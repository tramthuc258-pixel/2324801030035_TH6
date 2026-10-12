import 'package:just_audio/just_audio.dart';

import '../models/song_model.dart';

/// A small boundary around the native player, also usable without platform
/// channels in controller tests.
abstract class AudioEngine {
  PlayerState get state;
  int? get currentIndex;
  int? get nextIndex;
  int? get previousIndex;
  Duration get position;
  Duration? get duration;
  Duration get bufferedPosition;

  Stream<PlayerState> get stateStream;
  Stream<int?> get indexStream;
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;
  Stream<Duration> get bufferedStream;
  Stream<Object> get errorStream;

  Future<void> load(List<SongModel> songs, int initialIndex);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position, {int? index});
  Future<void> setShuffle(bool enabled);
  Future<void> setRepeat(bool enabled);
  Future<void> dispose();
}

class JustAudioEngine implements AudioEngine {
  JustAudioEngine({AudioPlayer? player})
    : _player = player ?? AudioPlayer(useLazyPreparation: true);

  final AudioPlayer _player;

  @override
  PlayerState get state => _player.playerState;
  @override
  int? get currentIndex => _player.currentIndex;
  @override
  int? get nextIndex => _player.nextIndex;
  @override
  int? get previousIndex => _player.previousIndex;
  @override
  Duration get position => _player.position;
  @override
  Duration? get duration => _player.duration;
  @override
  Duration get bufferedPosition => _player.bufferedPosition;
  @override
  Stream<PlayerState> get stateStream => _player.playerStateStream;
  @override
  Stream<int?> get indexStream => _player.currentIndexStream;
  @override
  Stream<Duration> get positionStream => _player.positionStream;
  @override
  Stream<Duration?> get durationStream => _player.durationStream;
  @override
  Stream<Duration> get bufferedStream => _player.bufferedPositionStream;
  @override
  Stream<Object> get errorStream => _player.errorStream;

  @override
  Future<void> load(List<SongModel> songs, int initialIndex) async {
    final sources = songs.map((song) {
      final uri = Uri.tryParse(song.audioUrl);
      if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
        throw const FormatException('URL nhạc phải là đường dẫn HTTPS.');
      }
      // Direct streaming: no file download or persistent audio cache.
      return AudioSource.uri(uri, tag: song.id);
    }).toList();
    await _player.setAudioSources(
      sources,
      initialIndex: initialIndex,
      initialPosition: Duration.zero,
    );
  }

  @override
  Future<void> play() => _player.play();
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> seek(Duration position, {int? index}) =>
      _player.seek(position, index: index);

  @override
  Future<void> setShuffle(bool enabled) async {
    if (enabled) await _player.shuffle();
    await _player.setShuffleModeEnabled(enabled);
  }

  @override
  Future<void> setRepeat(bool enabled) =>
      _player.setLoopMode(enabled ? LoopMode.all : LoopMode.off);

  @override
  Future<void> dispose() => _player.dispose();
}
