import 'package:flutter/material.dart';

import '../models/song_model.dart';
import '../theme/music_theme.dart';
import 'album_cover.dart';

class SongTile extends StatelessWidget {
  const SongTile({
    super.key,
    required this.song,
    required this.onTap,
    this.active = false,
    this.playing = false,
    this.favorite = false,
    this.onFavorite,
    this.onAddToPlaylist,
    this.onRemove,
  });

  final SongModel song;
  final VoidCallback onTap;
  final bool active;
  final bool playing;
  final bool favorite;
  final VoidCallback? onFavorite;
  final VoidCallback? onAddToPlaylist;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => Material(
    color: active
        ? MusicPalette.of(context).primaryContainer
        : Colors.transparent,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                AlbumCover(song: song),
                if (active)
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .38),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      playing ? Icons.equalizer_rounded : Icons.pause_rounded,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: active
                          ? MusicPalette.of(context).primary
                          : MusicPalette.of(context).text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    song.artist,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: MusicPalette.of(context).muted,
                    ),
                  ),
                ],
              ),
            ),
            if (onFavorite != null)
              IconButton(
                tooltip: favorite
                    ? 'Bỏ thích ${song.title}'
                    : 'Thích ${song.title}',
                onPressed: onFavorite,
                icon: Icon(
                  favorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 21,
                  color: favorite
                      ? MusicPalette.of(context).primary
                      : MusicPalette.of(context).muted,
                ),
              ),
            if (onAddToPlaylist != null || onRemove != null)
              PopupMenuButton<String>(
                tooltip: 'Tùy chọn ${song.title}',
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 21,
                  color: MusicPalette.of(context).muted,
                ),
                onSelected: (value) {
                  if (value == 'add') onAddToPlaylist?.call();
                  if (value == 'remove') onRemove?.call();
                },
                itemBuilder: (_) => [
                  if (onAddToPlaylist != null)
                    const PopupMenuItem(
                      value: 'add',
                      child: Text('Thêm vào playlist'),
                    ),
                  if (onRemove != null)
                    const PopupMenuItem(
                      value: 'remove',
                      child: Text('Xóa khỏi playlist'),
                    ),
                ],
              ),
          ],
        ),
      ),
    ),
  );
}
