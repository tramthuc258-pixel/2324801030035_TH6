import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../services/playlist_service.dart';
import '../theme/music_theme.dart';
import '../utils/music_helpers.dart';
import '../widgets/album_cover.dart';
import '../widgets/empty_panel.dart';
import '../widgets/playlist_actions.dart';
import '../widgets/song_tile.dart';

enum PlaylistKind { queue, favorites, playlist }

class PlaylistScreen extends StatelessWidget {
  const PlaylistScreen({
    super.key,
    required this.music,
    required this.library,
    required this.onPlay,
    required this.kind,
    this.playlistId,
  });
  final AudioService music;
  final PlaylistService library;
  final PlaySelection onPlay;
  final PlaylistKind kind;
  final String? playlistId;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([music, library]),
    builder: (context, _) {
      final palette = MusicPalette.of(context);
      final playlist = library.playlists
          .where((item) => item.id == playlistId)
          .firstOrNull;
      if (kind == PlaylistKind.playlist && playlist == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('Playlist')),
          body: const Padding(
            padding: EdgeInsets.all(24),
            child: EmptyPanel(
              icon: Icons.library_music_outlined,
              title: 'Playlist không còn ở đây',
              message: 'Quay lại thư viện để chọn playlist khác.',
            ),
          ),
        );
      }
      final title = switch (kind) {
        PlaylistKind.queue => music.queueName,
        PlaylistKind.favorites => 'Bài yêu thích',
        PlaylistKind.playlist => playlist!.name,
      };
      final songs = switch (kind) {
        PlaylistKind.queue => music.queue,
        PlaylistKind.favorites =>
          music.songs.where((song) => library.isFavorite(song.id)).toList(),
        PlaylistKind.playlist => songsForIds(music.songs, playlist!.songIds),
      };
      final missing = playlist == null
          ? 0
          : playlist.songIds.length - songs.length;
      return Scaffold(
        appBar: AppBar(
          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [
            if (playlist != null)
              PopupMenuButton<String>(
                tooltip: 'Tùy chọn playlist',
                onSelected: (action) =>
                    showPlaylistMenu(context, library, playlist, action),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'rename', child: Text('Đổi tên')),
                  PopupMenuItem(value: 'delete', child: Text('Xóa playlist')),
                ],
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: AlbumCover(
                  song: songs.firstOrNull,
                  size: 190,
                  radius: 24,
                ),
              ),
            ),
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              '${songs.length} bài hát${kind == PlaylistKind.playlist ? ' · Playlist cá nhân' : ''}',
              style: TextStyle(color: palette.muted),
            ),
            if (missing > 0)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  '$missing bài hát hiện không còn khả dụng.',
                  style: TextStyle(color: palette.muted),
                ),
              ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: songs.isEmpty
                      ? null
                      : () => onPlay(songs.first, songs, title),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Phát tất cả'),
                ),
                if (playlist != null)
                  OutlinedButton.icon(
                    onPressed: library.busy
                        ? null
                        : () => _managePlaylistSongs(
                            context,
                            music,
                            library,
                            playlist.id,
                          ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Chọn bài hát'),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            if (songs.isEmpty)
              const EmptyPanel(
                icon: Icons.music_note_outlined,
                title: 'Chưa có bài hát',
                message: 'Thêm những bài bạn muốn nghe vào danh sách này.',
              ),
            for (final song in songs)
              SongTile(
                song: song,
                active: music.currentSong?.id == song.id,
                playing: music.playing,
                onTap: () => onPlay(song, songs, title),
                favorite: library.isFavorite(song.id),
                onFavorite: library.busy
                    ? null
                    : () => toggleSongFavorite(context, library, song),
                onAddToPlaylist: playlist == null
                    ? () => choosePlaylistForSong(context, library, song)
                    : null,
                onRemove: playlist == null || library.busy
                    ? null
                    : () => runMusicAction(
                        context,
                        () => library.removeSongFromPlaylist(
                          playlist.id,
                          song.id,
                        ),
                      ),
              ),
          ],
        ),
      );
    },
  );
}

Future<void> _managePlaylistSongs(
  BuildContext context,
  AudioService music,
  PlaylistService library,
  String playlistId,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => AnimatedBuilder(
    animation: Listenable.merge([music, library]),
    builder: (context, _) {
      final playlist = library.playlists
          .where((item) => item.id == playlistId)
          .firstOrNull;
      final selectableSongs = music.songs
          .where(
            (song) =>
                song.isVisible ||
                (playlist?.songIds.contains(song.id) ?? false),
          )
          .toList();
      return SizedBox(
        height: MediaQuery.sizeOf(context).height * .75,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'Chọn bài hát',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (library.busy) const LinearProgressIndicator(),
            Expanded(
              child: playlist == null
                  ? const Center(child: Text('Playlist không còn khả dụng.'))
                  : ListView.builder(
                      itemCount: selectableSongs.length,
                      itemBuilder: (context, index) {
                        final song = selectableSongs[index];
                        final included = playlist.songIds.contains(song.id);
                        return ListTile(
                          leading: AlbumCover(song: song, size: 48, radius: 12),
                          title: Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Icon(
                            included
                                ? Icons.check_circle_rounded
                                : Icons.add_circle_outline_rounded,
                            color: included
                                ? MusicPalette.of(context).primary
                                : MusicPalette.of(context).muted,
                          ),
                          onTap: library.busy
                              ? null
                              : () => runMusicAction(
                                  context,
                                  () => included
                                      ? library.removeSongFromPlaylist(
                                          playlistId,
                                          song.id,
                                        )
                                      : library.addSongToPlaylist(
                                          playlistId,
                                          song.id,
                                        ),
                                ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Xong'),
              ),
            ),
          ],
        ),
      );
    },
  ),
);
