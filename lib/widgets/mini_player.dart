import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../theme/music_theme.dart';
import '../utils/music_helpers.dart';
import 'album_cover.dart';
import 'playback_control_icon.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key, required this.music, required this.onOpen});
  final AudioService music;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) {
    final palette = MusicPalette.of(context);
    final song = music.currentSong;
    if (song == null) return const SizedBox.shrink();
    final progress = music.duration.inMilliseconds > 0
        ? (music.position.inMilliseconds / music.duration.inMilliseconds).clamp(
            0.0,
            1.0,
          )
        : 0.0;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.raised,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: palette.primary.withValues(alpha: .08),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpen,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 9, 4, 9),
                child: Row(
                  children: [
                    AlbumCover(song: song, size: 42, radius: 10),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            music.loading ? 'Đang tải…' : song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: palette.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('mini-play-pause'),
                      tooltip: music.wantsPlayback ? 'Tạm dừng' : 'Phát nhạc',
                      onPressed: () =>
                          runMusicAction(context, music.togglePlayPause),
                      icon: PlaybackControlIcon(
                        playing: music.wantsPlayback,
                        loading: music.loading,
                        size: 30,
                        color: palette.primary,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Bài tiếp theo',
                      onPressed: music.hasNext
                          ? () => runMusicAction(context, music.next)
                          : null,
                      icon: const Icon(Icons.skip_next_rounded, size: 26),
                    ),
                  ],
                ),
              ),
              LinearProgressIndicator(
                value: progress,
                minHeight: 2,
                backgroundColor: palette.border,
                color: palette.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
