import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_model.dart';
import 'user_profile_service.dart';

class LibraryException implements Exception {
  const LibraryException(this.message);
  final String message;

  @override
  String toString() => message;
}

abstract class AuthService {
  UserModel? get currentUser;
  Stream<UserModel?> userChanges();
  Future<UserModel> signIn(String email, String password);
  Future<UserModel> register(String displayName, String email, String password);
  Future<UserModel?> signInWithGoogle();
  Future<void> signOut();
}

abstract class GoogleAccountProvider {
  Future<String?> authenticate();
  Future<void> signOut();
}

class NativeGoogleAccountProvider implements GoogleAccountProvider {
  static Future<void>? _initialization;

  Future<void> _initialize() =>
      _initialization ??= GoogleSignIn.instance.initialize();

  @override
  Future<String?> authenticate() async {
    try {
      await _initialize();
      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        throw const LibraryException(
          'Đăng nhập Google chưa hỗ trợ thiết bị này.',
        );
      }
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const LibraryException(
          'Google chưa gửi thông tin đăng nhập. Hãy thử lại.',
        );
      }
      return idToken;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    if (_initialization != null) {
      await _initialization;
      await GoogleSignIn.instance.signOut();
    }
  }
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({
    FirebaseAuth? auth,
    UserProfileService? profiles,
    GoogleAccountProvider? googleAccount,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _profiles = profiles ?? UserProfileService(),
       _google = googleAccount ?? NativeGoogleAccountProvider();

  final FirebaseAuth _auth;
  final UserProfileService _profiles;
  final GoogleAccountProvider _google;
  final Map<String, UserModel> _savedProfiles = {};
  final Map<String, Future<UserModel>> _profileRequests = {};
  bool _authenticating = false;
  static const _timeout = Duration(seconds: 20);

  @override
  UserModel? get currentUser {
    final user = _auth.currentUser;
    return user == null
        ? null
        : _savedProfiles[user.uid] ?? UserModel.fromFirebase(user);
  }

  @override
  Stream<UserModel?> userChanges() => Stream.multi((sink) {
    var generation = 0;
    var active = true;
    final subscription = _auth.userChanges().listen((user) {
      final eventGeneration = ++generation;
      if (user == null) {
        _savedProfiles.clear();
        sink.add(null);
        return;
      }
      // Announce the UID immediately so old-account library state is cleared.
      sink.add(_savedProfiles[user.uid] ?? UserModel.fromFirebase(user));
      if (_authenticating) return;
      unawaited(
        _syncProfile(user).then(
          (profile) {
            if (active &&
                generation == eventGeneration &&
                _auth.currentUser?.uid == user.uid) {
              sink.add(profile);
            }
          },
          onError: (Object error, StackTrace stack) {
            if (active &&
                generation == eventGeneration &&
                _auth.currentUser?.uid == user.uid) {
              sink.addError(error, stack);
            }
          },
        ),
      );
    }, onError: sink.addError);
    sink.onCancel = () {
      active = false;
      ++generation;
      return subscription.cancel();
    };
  });

  Future<UserModel> _syncProfile(User user) {
    final existing = _profileRequests[user.uid];
    if (existing != null) return existing;
    final future = _profiles
        .ensureProfile(UserModel.fromFirebase(user))
        .timeout(_timeout)
        .then((profile) {
          if (_auth.currentUser?.uid == user.uid) {
            _savedProfiles[user.uid] = profile;
          }
          return profile;
        })
        .catchError((Object error) {
          throw const LibraryException(
            'Bạn đã đăng nhập, nhưng chưa lưu được hồ sơ. Kiểm tra Internet và thử đăng nhập lại.',
          );
        });
    _profileRequests[user.uid] = future;
    unawaited(
      future.then(
        (_) {
          if (identical(_profileRequests[user.uid], future)) {
            _profileRequests.remove(user.uid);
          }
        },
        onError: (Object _, StackTrace stack) {
          if (identical(_profileRequests[user.uid], future)) {
            _profileRequests.remove(user.uid);
          }
        },
      ),
    );
    return future;
  }

  Future<T> _authenticate<T>(Future<T> Function() action) async {
    if (_authenticating) {
      throw const LibraryException('Vui lòng chờ thao tác đăng nhập hoàn tất.');
    }
    _authenticating = true;
    try {
      return await action();
    } finally {
      _authenticating = false;
    }
  }

  @override
  Future<UserModel> signIn(String email, String password) =>
      _authenticate(() async {
        final credential = await _auth
            .signInWithEmailAndPassword(email: email, password: password)
            .timeout(_timeout);
        return _syncProfile(credential.user!);
      });

  @override
  Future<UserModel> register(
    String displayName,
    String email,
    String password,
  ) => _authenticate(() async {
    final credential = await _auth
        .createUserWithEmailAndPassword(email: email, password: password)
        .timeout(_timeout);
    final user = credential.user!;
    try {
      await user.updateDisplayName(displayName).timeout(_timeout);
    } catch (_) {
      throw const LibraryException(
        'Tài khoản đã được tạo, nhưng chưa lưu được tên. Hãy đăng nhập lại để hoàn tất hồ sơ.',
      );
    }
    // The native SDK replaces currentUser after updateDisplayName; the original
    // credential's User can still contain the previous display name.
    final updatedUser = _auth.currentUser;
    if (updatedUser == null || updatedUser.uid != user.uid) {
      throw const LibraryException(
        'Phiên đăng nhập đã thay đổi. Hãy đăng nhập lại.',
      );
    }
    return _syncProfile(updatedUser);
  });

  @override
  Future<UserModel?> signInWithGoogle() => _authenticate(() async {
    String? idToken;
    try {
      idToken = await _google.authenticate();
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
    if (idToken == null) return null;
    final credential = await _auth
        .signInWithCredential(GoogleAuthProvider.credential(idToken: idToken))
        .timeout(_timeout);
    return _syncProfile(credential.user!);
  });

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    _savedProfiles.clear();
    try {
      await _google.signOut();
    } catch (_) {
      throw const LibraryException(
        'Bạn đã đăng xuất, nhưng phiên Google chưa đóng hoàn toàn. Hãy chọn lại tài khoản khi đăng nhập.',
      );
    }
  }
}

String friendlyLibraryError(Object error) {
  if (error is LibraryException) return error.message;
  if (error is TimeoutException) {
    return 'Kết nối quá lâu. Kiểm tra Internet rồi thử lại.';
  }
  if (error is GoogleSignInException) {
    return switch (error.code) {
      GoogleSignInExceptionCode.canceled => 'Bạn đã hủy đăng nhập Google.',
      GoogleSignInExceptionCode.interrupted =>
        'Đăng nhập Google bị gián đoạn. Hãy thử lại.',
      GoogleSignInExceptionCode.clientConfigurationError ||
      GoogleSignInExceptionCode.providerConfigurationError =>
        'Đăng nhập Google chưa sẵn sàng. Vui lòng thử lại sau.',
      GoogleSignInExceptionCode.uiUnavailable =>
        'Chưa thể mở cửa sổ Google. Hãy thử lại khi ứng dụng đang mở.',
      _ => 'Không thể đăng nhập Google lúc này. Vui lòng thử lại.',
    };
  }
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'invalid-email' => 'Địa chỉ email chưa hợp lệ.',
      'email-already-in-use' => 'Email này đã được đăng ký. Hãy đăng nhập.',
      'weak-password' => 'Mật khẩu chưa đủ mạnh. Hãy dùng ít nhất 6 ký tự.',
      'wrong-password' ||
      'user-not-found' ||
      'invalid-credential' => 'Email hoặc mật khẩu chưa đúng.',
      'user-disabled' => 'Tài khoản này đã bị vô hiệu hóa.',
      'operation-not-allowed' =>
        'Tính năng đăng nhập chưa sẵn sàng. Vui lòng thử lại sau.',
      'network-request-failed' => 'Không có kết nối mạng. Hãy thử lại.',
      'too-many-requests' =>
        'Bạn đã thử quá nhiều lần. Vui lòng chờ rồi thử lại.',
      'requires-recent-login' => 'Vui lòng đăng nhập lại để tiếp tục.',
      'account-exists-with-different-credential' => 'Email này đã dùng cách đăng nhập khác. Hãy đăng nhập bằng cách đã đăng ký.',
      _ => 'Không thể đăng nhập lúc này. Vui lòng thử lại.',
    };
  }
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' =>
        'Chưa có quyền truy cập thư viện. Hãy đăng nhập lại.',
      'unauthenticated' => 'Phiên đăng nhập đã hết hạn. Hãy đăng nhập lại.',
      'unavailable' || 'deadline-exceeded' =>
        'Không thể kết nối thư viện. Kiểm tra Internet rồi thử lại.',
      'not-found' => 'Playlist này không còn tồn tại.',
      _ => 'Không thể lưu thay đổi. Vui lòng thử lại.',
    };
  }
  return 'Không thể thực hiện thao tác. Vui lòng thử lại.';
}
