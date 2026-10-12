import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../services/playlist_service.dart';
import '../theme/music_theme.dart';
import '../utils/music_helpers.dart';
import '../widgets/album_cover.dart';
import '../widgets/empty_panel.dart';
import '../widgets/error_notice.dart';
import '../widgets/playlist_actions.dart';
import '../widgets/section_header.dart';
import '../widgets/song_tile.dart';
import 'favorites_screen.dart';
import 'login_screen.dart';
import 'playlist_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({
    super.key,
    required this.music,
    required this.library,
    required this.onPlay,
  });
  final AudioService music;
  final PlaylistService library;
  final PlaySelection onPlay;

  @override
  Widget build(BuildContext context) {
    final palette = MusicPalette.of(context);
    final favorites = music.songs
        .where((song) => library.isFavorite(song.id))
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      children: [
        Text('Thư viện', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 8),
        Text(
          'Những giai điệu mang dấu ấn của bạn.',
          style: TextStyle(color: palette.muted),
        ),
        if (library.error != null)
          LibraryErrorNotice(
            message: library.error!,
            onDismiss: library.clearError,
          ),
        if (library.loading)
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: LinearProgressIndicator(),
          ),
        SectionHeader(
          title: 'Đang nghe',
          subtitle: music.queue.isEmpty
              ? 'Chọn một bài để bắt đầu'
              : '${music.queue.length} bài · ${music.queueName}',
          action: music.queue.isEmpty
              ? null
              : TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => PlaylistScreen(
                        music: music,
                        library: library,
                        onPlay: onPlay,
                        kind: PlaylistKind.queue,
                      ),
                    ),
                  ),
                  child: const Text('Xem tất cả'),
                ),
        ),
        if (music.queue.isEmpty)
          const EmptyPanel(
            icon: Icons.queue_music_rounded,
            title: 'Nhạc đang chờ bạn',
            message: 'Chọn bài hát trong Khám phá để tạo danh sách phát.',
          )
        else
          for (final song in music.queue.take(3))
            SongTile(
              song: song,
              active: music.currentSong?.id == song.id,
              playing: music.playing,
              onTap: () => onPlay(song, music.queue, music.queueName),
            ),
        SectionHeader(
          title: 'Bài yêu thích',
          subtitle: '${favorites.length} bài hát',
          action: favorites.isEmpty
              ? null
              : TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => FavoritesScreen(
                        music: music,
                        library: library,
                        onPlay: onPlay,
                      ),
                    ),
                  ),
                  child: const Text('Xem tất cả'),
                ),
        ),
        if (!library.isSignedIn)
          EmptyPanel(
            icon: Icons.favorite_border_rounded,
            title: 'Lưu lại bài bạn thích',
            message:
                'Đăng nhập để có thư viện riêng và nghe lại bất cứ lúc nào.',
            action: FilledButton(
              onPressed: () => showMusicAuth(context, library),
              child: const Text('Đăng nhập'),
            ),
          )
        else if (favorites.isEmpty)
          const EmptyPanel(
            icon: Icons.favorite_border_rounded,
            title: 'Một chút yêu thích',
            message: 'Nhấn trái tim cạnh bài hát để thêm vào danh sách này.',
          )
        else
          for (final song in favorites.take(3))
            SongTile(
              song: song,
              active: music.currentSong?.id == song.id,
              playing: music.playing,
              favorite: true,
              onFavorite: library.busy
                  ? null
                  : () => toggleSongFavorite(context, library, song),
              onTap: () => onPlay(song, favorites, 'Bài yêu thích'),
              onAddToPlaylist: () =>
                  choosePlaylistForSong(context, library, song),
            ),
        SectionHeader(
          title: 'Playlist của bạn',
          subtitle: 'Một bộ sưu tập cho mỗi tâm trạng',
          action: IconButton(
            tooltip: 'Tạo playlist',
            onPressed: library.busy
                ? null
                : () => createMusicPlaylist(context, library),
            icon: Icon(
              Icons.add_circle_outline_rounded,
              color: palette.primary,
            ),
          ),
        ),
        if (library.playlists.isEmpty)
          EmptyPanel(
            icon: Icons.library_music_outlined,
            title: 'Playlist đầu tiên',
            message: 'Gom những bài hát hợp gu vào một nơi.',
            action: OutlinedButton.icon(
              onPressed: library.busy
                  ? null
                  : () => createMusicPlaylist(context, library),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tạo playlist'),
            ),
          )
        else
          for (final playlist in library.playlists)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: palette.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: palette.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  leading: AlbumCover(
                    song: songsForIds(
                      music.songs,
                      playlist.songIds,
                    ).firstOrNull,
                  ),
                  title: Text(
                    playlist.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${playlist.songIds.length} bài hát',
                    style: TextStyle(color: palette.muted),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => PlaylistScreen(
                        music: music,
                        library: library,
                        onPlay: onPlay,
                        kind: PlaylistKind.playlist,
                        playlistId: playlist.id,
                      ),
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    tooltip: 'Tùy chọn playlist ${playlist.name}',
                    onSelected: (action) =>
                        showPlaylistMenu(context, library, playlist, action),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'rename', child: Text('Đổi tên')),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Xóa playlist'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ],
    );
  }
}
