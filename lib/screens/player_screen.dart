import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../services/playlist_service.dart';
import '../theme/music_theme.dart';
import '../utils/music_helpers.dart';
import '../widgets/album_cover.dart';
import '../widgets/error_notice.dart';
import '../widgets/playback_control_icon.dart';
import '../widgets/playlist_actions.dart';
import '../widgets/song_tile.dart';
import '../widgets/song_credits.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.music, required this.library});
  final AudioService music;
  final PlaylistService library;
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  double? _scrubMilliseconds;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([widget.music, widget.library]),
    builder: (context, _) {
      final palette = MusicPalette.of(context);
      final music = widget.music;
      final library = widget.library;
      final song = music.currentSong;
      if (song == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('Đang phát')),
          body: const Center(child: Text('Chọn một bài hát để bắt đầu.')),
        );
      }
      final maximum = music.duration.inMilliseconds.toDouble();
      final value =
          (_scrubMilliseconds ?? music.position.inMilliseconds.toDouble())
              .clamp(0.0, maximum > 0 ? maximum : 1.0);
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Thu nhỏ trình phát',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ĐANG PHÁT',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                  color: palette.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                music.queueName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Danh sách đang phát',
              onPressed: () => _showQueue(context),
              icon: const Icon(Icons.queue_music_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final coverSize = math.min(constraints.maxWidth - 64, 310.0);
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (music.error != null)
                      MusicErrorBanner(
                        message: music.error!,
                        onRetry: () => runMusicAction(context, music.retry),
                        onDismiss: music.clearError,
                      ),
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: palette.primary.withValues(alpha: .16),
                              blurRadius: 60,
                              spreadRadius: 7,
                            ),
                          ],
                        ),
                        child: AlbumCover(
                          song: song,
                          size: coverSize,
                          radius: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                song.artist,
                                style: TextStyle(
                                  color: palette.muted,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: library.isFavorite(song.id)
                              ? 'Bỏ thích bài hát'
                              : 'Thích bài hát',
                          onPressed: library.busy
                              ? null
                              : () =>
                                    toggleSongFavorite(context, library, song),
                          icon: Icon(
                            library.isFavorite(song.id)
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: library.isFavorite(song.id)
                                ? palette.primary
                                : palette.text,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 16,
                        ),
                        activeTrackColor: palette.primary,
                        inactiveTrackColor: palette.border,
                        thumbColor: palette.primary,
                        trackShape: const RoundedRectSliderTrackShape(),
                      ),
                      child: Slider(
                        semanticFormatterCallback: (value) =>
                            'Vị trí ${formatMusicTime(Duration(milliseconds: value.toInt()))}',
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        min: 0,
                        max: maximum > 0 ? maximum : 1,
                        value: value,
                        onChanged: maximum <= 0
                            ? null
                            : (value) =>
                                  setState(() => _scrubMilliseconds = value),
                        onChangeEnd: maximum <= 0
                            ? null
                            : (value) async {
                                await runMusicAction(
                                  context,
                                  () => music.seek(
                                    Duration(milliseconds: value.toInt()),
                                  ),
                                );
                                if (mounted) {
                                  setState(() => _scrubMilliseconds = null);
                                }
                              },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formatMusicTime(
                            Duration(milliseconds: value.toInt()),
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          maximum > 0
                              ? formatMusicTime(music.duration)
                              : '--:--',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          tooltip: music.shuffleEnabled
                              ? 'Tắt phát ngẫu nhiên'
                              : 'Bật phát ngẫu nhiên',
                          onPressed: () =>
                              runMusicAction(context, music.toggleShuffle),
                          icon: Icon(
                            Icons.shuffle_rounded,
                            size: 22,
                            color: music.shuffleEnabled
                                ? palette.primary
                                : palette.muted,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Bài trước',
                          iconSize: 36,
                          onPressed: music.hasPrevious
                              ? () => runMusicAction(context, music.previous)
                              : null,
                          icon: const Icon(Icons.skip_previous_rounded),
                        ),
                        SizedBox.square(
                          dimension: 72,
                          child: Tooltip(
                            message: music.wantsPlayback
                                ? 'Tạm dừng'
                                : 'Phát nhạc',
                            child: FilledButton(
                              key: const ValueKey('player-play-pause'),
                              style: FilledButton.styleFrom(
                                padding: EdgeInsets.zero,
                                shape: const CircleBorder(),
                              ),
                              onPressed: () => runMusicAction(
                                context,
                                music.togglePlayPause,
                              ),
                              child: PlaybackControlIcon(
                                playing: music.wantsPlayback,
                                loading: music.loading,
                                color: palette.onPrimary,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Bài tiếp theo',
                          iconSize: 36,
                          onPressed: music.hasNext
                              ? () => runMusicAction(context, music.next)
                              : null,
                          icon: const Icon(Icons.skip_next_rounded),
                        ),
                        IconButton(
                          tooltip: music.repeatEnabled
                              ? 'Tắt lặp lại danh sách'
                              : 'Bật lặp lại danh sách',
                          onPressed: () =>
                              runMusicAction(context, music.toggleRepeat),
                          icon: Icon(
                            Icons.repeat_rounded,
                            size: 22,
                            color: music.repeatEnabled
                                ? palette.primary
                                : palette.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: Text(
                        music.loading
                            ? 'Đang chuẩn bị giai điệu…'
                            : 'NGHE TRỰC TUYẾN',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600,
                          color: palette.muted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: library.busy
                          ? null
                          : () => choosePlaylistForSong(context, library, song),
                      icon: const Icon(Icons.playlist_add_rounded),
                      label: const Text('Thêm vào playlist'),
                    ),
                    SongCredits(song: song),
                  ],
                ),
              );
            },
          ),
        ),
      );
    },
  );

  Future<void> _showQueue(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => ListenableBuilder(
      listenable: widget.music,
      builder: (context, _) => SizedBox(
        height: MediaQuery.sizeOf(context).height * .7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tiếp tục câu chuyện',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${widget.music.queueName} · ${widget.music.queue.length} bài',
                    style: TextStyle(color: MusicPalette.of(context).muted),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final song in widget.music.queue)
                    SongTile(
                      song: song,
                      active: widget.music.currentSong?.id == song.id,
                      playing: widget.music.playing,
                      onTap: () async {
                        setState(() => _scrubMilliseconds = null);
                        await runMusicAction(
                          context,
                          () => widget.music.playSong(
                            song,
                            fromSongs: widget.music.queue,
                            queueName: widget.music.queueName,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
