import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/song_model.dart';
import 'audio_engine.dart';

/// Owns the one player shared by the home, playlist and now-playing screens.
class AudioService extends ChangeNotifier {
  AudioService({AudioEngine? engine}) : _engine = engine ?? JustAudioEngine() {
    _subscriptions.addAll([
      _engine.stateStream.listen((_) => _syncFromEngine()),
      _engine.indexStream.listen((_) => _syncFromEngine()),
      _engine.positionStream.listen((_) => _syncFromEngine()),
      _engine.durationStream.listen((_) => _syncFromEngine()),
      _engine.bufferedStream.listen((_) => _syncFromEngine()),
      _engine.errorStream.listen((failure) {
        if (!_loadPending) _reportError(failure, _request);
      }),
    ]);
  }

  final AudioEngine _engine;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  List<SongModel> _songs = const [];
  List<SongModel> _queue = const [];
  String _queueName = 'Danh sách phát';
  int? _currentIndex;
  int _request = 0;
  bool _disposed = false;
  bool _loadPending = false;
  bool _sourceLoaded = false;
  bool _wantsPlayback = false;
  bool _playing = false;
  bool _buffering = false;
  bool _shuffleEnabled = false;
  bool _repeatEnabled = false;
  bool _hasNext = false;
  bool _hasPrevious = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Duration _bufferedPosition = Duration.zero;
  String? _error;
  Future<void> _commands = Future<void>.value();

  List<SongModel> get songs => _songs;
  List<SongModel> get queue => _queue;
  String get queueName => _queueName;
  SongModel? get currentSong {
    final index = _currentIndex;
    return index != null && index >= 0 && index < _queue.length
        ? _queue[index]
        : null;
  }

  bool get playing => _playing && _error == null;
  bool get wantsPlayback =>
      _error == null && (_loadPending ? _wantsPlayback : playing);
  bool get loading => _error == null && (_loadPending || _buffering);
  bool get shuffleEnabled => _shuffleEnabled;
  bool get repeatEnabled => _repeatEnabled;
  bool get hasNext => _sourceLoaded && !_loadPending && _hasNext;
  bool get hasPrevious => _sourceLoaded && !_loadPending && _hasPrevious;
  Duration get position => _position;
  Duration get duration => _duration;
  Duration get bufferedPosition => _bufferedPosition;
  String? get error => _error;

  void setSongs(List<SongModel> songs) {
    _songs = _uniqueSongs(songs);
    _notify();
  }

  static List<SongModel> _uniqueSongs(Iterable<SongModel> songs) {
    final seen = <String>{};
    return List.unmodifiable(songs.where((song) => seen.add(song.id)));
  }

  Future<void> playSong(
    SongModel song, {
    List<SongModel>? fromSongs,
    String queueName = 'Danh sách phát',
  }) async {
    if (_disposed) return;
    final chosen = _uniqueSongs(fromSongs ?? _songs);
    final index = chosen.indexWhere((item) => item.id == song.id);
    // Selection uses its ID, never an index from a filtered UI list.
    final sourceQueue = index < 0
        ? List<SongModel>.unmodifiable([song])
        : chosen;
    final selectedIndex = index < 0 ? 0 : index;
    final request = ++_request;
    _queue = sourceQueue;
    _queueName = queueName;
    _currentIndex = selectedIndex;
    _error = null;
    _loadPending = true;
    _sourceLoaded = false;
    _wantsPlayback = true;
    _playing = false;
    _buffering = false;
    _position = Duration.zero;
    _duration = Duration.zero;
    _bufferedPosition = Duration.zero;
    _notify();

    try {
      await _engine.pause();
      if (!_isCurrent(request)) return;
      // just_audio interrupts older setAudioSources requests. Do not serialize
      // loading behind a slow URL: a later selection must win immediately.
      await _engine.load(sourceQueue, selectedIndex);
      if (!_isCurrent(request)) return;
      // A mode may be toggled while the URL is loading. Apply the latest
      // choices before declaring this source ready.
      bool repeat;
      bool shuffle;
      do {
        repeat = _repeatEnabled;
        shuffle = _shuffleEnabled;
        await _engine.setRepeat(repeat);
        if (!_isCurrent(request)) return;
        await _engine.setShuffle(shuffle);
        if (!_isCurrent(request)) return;
      } while (repeat != _repeatEnabled || shuffle != _shuffleEnabled);
      _sourceLoaded = true;
      _loadPending = false;
      _syncFromEngine();
      if (_wantsPlayback) _startPlayback(request);
    } catch (failure) {
      _reportError(failure, request);
    }
  }

  Future<void> togglePlayPause() {
    if (_disposed || currentSong == null) return Future<void>.value();
    if (_loadPending) {
      _wantsPlayback = !_wantsPlayback;
      _notify();
      return Future<void>.value();
    }
    if (_error != null || !_sourceLoaded) return retry();
    return _command(() async {
      if (_engine.state.playing &&
          _engine.state.processingState != ProcessingState.completed) {
        _wantsPlayback = false;
        await _engine.pause();
      } else {
        _wantsPlayback = true;
        if (_engine.state.processingState == ProcessingState.completed) {
          await _engine.seek(Duration.zero, index: _currentIndex);
        }
        _startPlayback(_request);
      }
      _syncFromEngine();
    });
  }

  Future<void> next() => _move(forward: true);
  Future<void> previous() => _move(forward: false);

  Future<void> _move({required bool forward}) => _command(() async {
    final index = forward ? _engine.nextIndex : _engine.previousIndex;
    if (index == null) return;
    await _engine.seek(Duration.zero, index: index);
    _syncFromEngine();
    if (_wantsPlayback) _startPlayback(_request);
  });

  Future<void> seek(Duration target) => _command(() async {
    // Unknown duration cannot safely drive a seek bar.
    if (_duration == Duration.zero) return;
    await _engine.seek(_clamp(target));
    _syncFromEngine();
  });

  Future<void> toggleShuffle() async {
    if (_disposed) return;
    _shuffleEnabled = !_shuffleEnabled;
    _notify();
    await _command(() async {
      await _engine.setShuffle(_shuffleEnabled);
      _syncFromEngine();
    });
  }

  Future<void> toggleRepeat() async {
    if (_disposed) return;
    _repeatEnabled = !_repeatEnabled;
    _notify();
    await _command(() async {
      await _engine.setRepeat(_repeatEnabled);
      _syncFromEngine();
    });
  }

  Future<void> retry() {
    final song = currentSong;
    if (song == null || _disposed) return Future<void>.value();
    return playSong(song, fromSongs: _queue, queueName: _queueName);
  }

  void clearError() {
    _error = null;
    _notify();
  }

  /// Serializes quick controls while new source requests invalidate old ones.
  Future<void> _command(Future<void> Function() action) {
    final request = _request;
    final next = _commands.then((_) async {
      if (!_isCurrent(request) || _loadPending || !_sourceLoaded) return;
      try {
        await action();
      } catch (failure) {
        _reportError(failure, request);
      }
    });
    _commands = next;
    return next;
  }

  void _startPlayback(int request) {
    if (!_isCurrent(request) || _loadPending || !_sourceLoaded) return;
    // play() completes at the END of playback, not when audio starts.
    unawaited(
      _engine.play().catchError((Object failure) {
        _reportError(failure, request);
      }),
    );
    _syncFromEngine();
  }

  bool _isCurrent(int request) => !_disposed && request == _request;

  Duration _clamp(Duration value) {
    if (value.isNegative) return Duration.zero;
    return _duration > Duration.zero && value > _duration ? _duration : value;
  }

  void _syncFromEngine() {
    if (_disposed || _loadPending || !_sourceLoaded) return;
    final index = _engine.currentIndex;
    if (index != null && index >= 0 && index < _queue.length) {
      _currentIndex = index;
    }
    final state = _engine.state;
    _playing =
        state.playing && state.processingState != ProcessingState.completed;
    _buffering =
        state.processingState == ProcessingState.loading ||
        state.processingState == ProcessingState.buffering;
    final duration = _engine.duration;
    _duration = duration == null || duration.isNegative
        ? Duration.zero
        : duration;
    _position = _clamp(_engine.position);
    _bufferedPosition = _clamp(_engine.bufferedPosition);
    _hasNext = _engine.nextIndex != null;
    _hasPrevious = _engine.previousIndex != null;
    _notify();
  }

  void _reportError(Object failure, int request) {
    if (!_isCurrent(request)) return;
    _loadPending = false;
    _sourceLoaded = false;
    _playing = false;
    _buffering = false;
    _error = failure is FormatException
        ? failure.message
        : 'Không phát được bài hát. Kiểm tra kết nối mạng rồi thử lại.';
    // A failed stream must also stop the native player's playback intent;
    // changing only the button state could leave audio playing behind it.
    unawaited(_engine.pause().catchError((Object _) {}));
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_request;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(_engine.dispose());
    super.dispose();
  }
}
