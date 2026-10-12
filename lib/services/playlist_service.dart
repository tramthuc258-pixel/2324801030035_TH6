import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/playlist_model.dart';
import '../models/song_model.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

abstract class LibraryStore {
  Stream<Set<String>> watchFavorites(String userId);
  Stream<List<PlaylistModel>> watchPlaylists(String userId);
  Future<void> setFavorite(String userId, String songId, bool liked);
  Future<String> createPlaylist(
    String userId,
    String name,
    List<String> songIds,
  );
  Future<PlaylistModel> addSong(String userId, String id, String songId);
  Future<PlaylistModel> removeSong(String userId, String id, String songId);
  Future<PlaylistModel> renamePlaylist(String userId, String id, String name);
  Future<void> deletePlaylist(String userId, String id);
}

class FirestoreLibraryStore implements LibraryStore {
  FirestoreLibraryStore({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _favorites(String uid) =>
      _firestore.collection('users').doc(uid).collection('favorites');
  CollectionReference<Map<String, dynamic>> _playlists(String uid) =>
      _firestore.collection('users').doc(uid).collection('playlists');

  @override
  Stream<Set<String>> watchFavorites(String userId) =>
      _favorites(userId)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());

  @override
  Stream<List<PlaylistModel>> watchPlaylists(String userId) =>
      _playlists(userId)
          .orderBy('createdAt')
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => PlaylistModel.fromFirestore(doc.id, doc.data()))
                .toList(),
          );

  @override
  Future<void> setFavorite(String userId, String songId, bool liked) async {
    final document = _favorites(userId).doc(songId);
    if (liked) {
      await document.set({
        'songId': songId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await document.delete();
    }
  }

  @override
  Future<String> createPlaylist(
    String userId,
    String name,
    List<String> songIds,
  ) async {
    final document = _playlists(userId).doc();
    await document.set({
      'name': name,
      'songIds': songIds,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return document.id;
  }

  Future<PlaylistModel> _changePlaylist(
    String userId,
    String id,
    PlaylistModel Function(PlaylistModel playlist) change,
  ) => _firestore.runTransaction((transaction) async {
    final reference = _playlists(userId).doc(id);
    final snapshot = await transaction.get(reference);
    final data = snapshot.data();
    if (data == null) {
      throw const LibraryException('Playlist này không còn tồn tại.');
    }
    final updated = change(PlaylistModel.fromFirestore(id, data));
    if (updated.songIds.length > 100) {
      throw const LibraryException('Mỗi playlist chỉ chứa tối đa 100 bài hát.');
    }
    transaction.update(reference, {
      'name': updated.name,
      'songIds': updated.songIds,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return updated;
  });

  @override
  Future<PlaylistModel> addSong(String userId, String id, String songId) =>
      _changePlaylist(
        userId,
        id,
        (playlist) => playlist.copyWith(songIds: [...playlist.songIds, songId]),
      );

  @override
  Future<PlaylistModel> removeSong(String userId, String id, String songId) =>
      _changePlaylist(
        userId,
        id,
        (playlist) => playlist.copyWith(
          songIds: playlist.songIds.where((value) => value != songId).toList(),
        ),
      );

  @override
  Future<PlaylistModel> renamePlaylist(String userId, String id, String name) =>
      _changePlaylist(userId, id, (playlist) => playlist.copyWith(name: name));

  @override
  Future<void> deletePlaylist(String userId, String id) =>
      _playlists(userId).doc(id).delete();
}

class PlaylistService extends ChangeNotifier {
  PlaylistService({AuthService? accountService, LibraryStore? store})
    : _account = accountService ?? FirebaseAuthService(),
      _store = store ?? FirestoreLibraryStore() {
    _onUserChanged(_account.currentUser);
    _accountSubscription = _account.userChanges().listen(
      _onUserChanged,
      onError: (Object error) {
        if (!_disposed) {
          _error = friendlyLibraryError(error);
          notifyListeners();
        }
      },
    );
  }

  final AuthService _account;
  final LibraryStore _store;
  StreamSubscription<UserModel?>? _accountSubscription;
  StreamSubscription<Set<String>>? _favoriteSubscription;
  StreamSubscription<List<PlaylistModel>>? _playlistSubscription;
  UserModel? _user;
  Set<String> _favoriteIds = {};
  List<PlaylistModel> _playlists = [];
  bool _busy = false;
  bool _favoritesLoading = false;
  bool _playlistsLoading = false;
  bool _disposed = false;
  int _epoch = 0;
  String? _error;

  UserModel? get user => _user;
  bool get isSignedIn => _user != null;
  bool get busy => _busy;
  bool get loading => _favoritesLoading || _playlistsLoading;
  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);
  List<PlaylistModel> get playlists => List.unmodifiable(_playlists);
  String? get error => _error;
  bool isFavorite(String songId) => _favoriteIds.contains(songId);

  bool _isCurrent(int epoch, String uid) =>
      !_disposed && epoch == _epoch && _user?.id == uid;

  void _onUserChanged(UserModel? nextUser) {
    if (_disposed) return;
    if (_user?.id == nextUser?.id) {
      _user = nextUser;
      notifyListeners();
      return;
    }
    final epoch = ++_epoch;
    unawaited(_favoriteSubscription?.cancel());
    unawaited(_playlistSubscription?.cancel());
    _favoriteSubscription = null;
    _playlistSubscription = null;
    _user = nextUser;
    _favoriteIds = {};
    _playlists = [];
    _error = null;
    _busy = false;
    _favoritesLoading = nextUser != null;
    _playlistsLoading = nextUser != null;
    notifyListeners();
    if (nextUser == null) return;
    final uid = nextUser.id;
    _favoriteSubscription = _store
        .watchFavorites(uid)
        .listen(
          (ids) {
            if (!_isCurrent(epoch, uid)) return;
            _favoriteIds = Set.of(ids);
            _favoritesLoading = false;
            notifyListeners();
          },
          onError: (Object error) {
            if (!_isCurrent(epoch, uid)) return;
            _favoritesLoading = false;
            _error = friendlyLibraryError(error);
            notifyListeners();
          },
        );
    _playlistSubscription = _store
        .watchPlaylists(uid)
        .listen(
          (playlists) {
            if (!_isCurrent(epoch, uid)) return;
            _playlists = List.of(playlists);
            _playlistsLoading = false;
            notifyListeners();
          },
          onError: (Object error) {
            if (!_isCurrent(epoch, uid)) return;
            _playlistsLoading = false;
            _error = friendlyLibraryError(error);
            notifyListeners();
          },
        );
  }

  Future<T> _run<T>(Future<T> Function() action) async {
    if (_disposed) {
      throw const LibraryException('Thư viện đã đóng.');
    }
    if (_busy) {
      throw const LibraryException('Vui lòng chờ thao tác hiện tại hoàn tất.');
    }
    final epoch = _epoch;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      return await action();
    } catch (error) {
      final message = friendlyLibraryError(error);
      if (!_disposed && epoch == _epoch) {
        _error = message;
        notifyListeners();
      }
      throw LibraryException(message);
    } finally {
      if (!_disposed && epoch == _epoch) {
        _busy = false;
        notifyListeners();
      }
    }
  }

  String _requireUser() {
    final uid = _user?.id;
    if (uid == null) {
      throw const LibraryException('Hãy đăng nhập để lưu thư viện cá nhân.');
    }
    return uid;
  }

  String _checkedName(String input) {
    final name = input.trim();
    if (name.isEmpty || name.length > 60) {
      throw const LibraryException('Tên phải có từ 1 đến 60 ký tự.');
    }
    return name;
  }

  void _checkId(String value) {
    if (value.isEmpty || value.length > 128 || value.contains('/')) {
      throw const LibraryException('Mã bài hát hoặc playlist chưa hợp lệ.');
    }
  }

  List<String> _checkedSongIds(List<String> songIds) {
    for (final id in songIds) {
      _checkId(id);
    }
    final ids = songIds.toSet().toList();
    if (ids.length > 100) {
      throw const LibraryException('Mỗi playlist chỉ chứa tối đa 100 bài hát.');
    }
    return ids;
  }

  void _checkCredentials(
    String email,
    String password, {
    bool register = false,
  }) {
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      throw const LibraryException('Địa chỉ email chưa hợp lệ.');
    }
    if (password.isEmpty || (register && password.length < 6)) {
      throw const LibraryException('Mật khẩu phải có ít nhất 6 ký tự.');
    }
  }

  Future<void> signIn(String email, String password) => _run(() async {
    final normalizedEmail = email.trim();
    _checkCredentials(normalizedEmail, password);
    final nextUser = await _account.signIn(normalizedEmail, password);
    if (!_disposed && _account.currentUser?.id == nextUser.id) {
      _onUserChanged(nextUser);
    }
  });

  Future<void> register(String displayName, String email, String password) =>
      _run(() async {
        final name = _checkedName(displayName);
        final normalizedEmail = email.trim();
        _checkCredentials(normalizedEmail, password, register: true);
        final nextUser = await _account.register(
          name,
          normalizedEmail,
          password,
        );
        if (!_disposed && _account.currentUser?.id == nextUser.id) {
          _onUserChanged(nextUser);
        }
      });

  Future<bool> signInWithGoogle() => _run(() async {
    final nextUser = await _account.signInWithGoogle();
    if (nextUser == null) return false;
    if (!_disposed && _account.currentUser?.id == nextUser.id) {
      _onUserChanged(nextUser);
      return true;
    }
    return false;
  });

  Future<void> signOut() => _run(() async {
    await _account.signOut();
    if (!_disposed && _account.currentUser == null) _onUserChanged(null);
  });

  Future<void> toggleFavorite(SongModel song) => _run(() async {
    final uid = _requireUser();
    final epoch = _epoch;
    _checkId(song.id);
    final liked = !isFavorite(song.id);
    await _store.setFavorite(uid, song.id, liked);
    if (_isCurrent(epoch, uid)) {
      if (liked) {
        _favoriteIds.add(song.id);
      } else {
        _favoriteIds.remove(song.id);
      }
    }
  });

  Future<String> createPlaylist(
    String name, {
    List<String> songIds = const [],
  }) => _run(() async {
    final uid = _requireUser();
    final epoch = _epoch;
    final checkedName = _checkedName(name);
    final ids = _checkedSongIds(songIds);
    final id = await _store.createPlaylist(uid, checkedName, ids);
    if (_isCurrent(epoch, uid) && !_playlists.any((item) => item.id == id)) {
      _playlists.add(PlaylistModel(id: id, name: checkedName, songIds: ids));
    }
    return id;
  });

  Future<void> _changePlaylist(
    String id,
    Future<PlaylistModel> Function(String uid) action,
  ) => _run(() async {
    final uid = _requireUser();
    final epoch = _epoch;
    _checkId(id);
    final updated = await action(uid);
    if (_isCurrent(epoch, uid)) {
      final index = _playlists.indexWhere((playlist) => playlist.id == id);
      if (index >= 0) _playlists[index] = updated;
    }
  });

  Future<void> addSongToPlaylist(String id, String songId) =>
      _changePlaylist(id, (uid) {
        _checkId(songId);
        return _store.addSong(uid, id, songId);
      });

  Future<void> removeSongFromPlaylist(String id, String songId) =>
      _changePlaylist(id, (uid) {
        _checkId(songId);
        return _store.removeSong(uid, id, songId);
      });

  Future<void> renamePlaylist(String id, String name) => _changePlaylist(
    id,
    (uid) => _store.renamePlaylist(uid, id, _checkedName(name)),
  );

  Future<void> deletePlaylist(String id) => _run(() async {
    final uid = _requireUser();
    final epoch = _epoch;
    _checkId(id);
    await _store.deletePlaylist(uid, id);
    if (_isCurrent(epoch, uid)) {
      _playlists.removeWhere((playlist) => playlist.id == id);
    }
  });

  void clearError() {
    _error = null;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_epoch;
    unawaited(_accountSubscription?.cancel());
    unawaited(_favoriteSubscription?.cancel());
    unawaited(_playlistSubscription?.cancel());
    super.dispose();
  }
}
