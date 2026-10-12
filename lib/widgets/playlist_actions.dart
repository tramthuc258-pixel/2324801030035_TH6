import 'package:flutter/material.dart';

import '../models/playlist_model.dart';
import '../models/song_model.dart';
import '../screens/login_screen.dart';
import '../services/playlist_service.dart';
import '../theme/music_theme.dart';
import '../utils/music_helpers.dart';

Future<bool> requireMusicAccount(
  BuildContext context,
  PlaylistService library,
) async {
  if (!library.isSignedIn) await showMusicAuth(context, library);
  return context.mounted && library.isSignedIn;
}

Future<void> toggleSongFavorite(
  BuildContext context,
  PlaylistService library,
  SongModel song,
) async {
  if (!await requireMusicAccount(context, library) || !context.mounted) return;
  await runMusicAction(context, () => library.toggleFavorite(song));
}

Future<String?> _askPlaylistName(BuildContext context, {String? initial}) =>
    showDialog<String>(
      context: context,
      builder: (_) => _PlaylistNameDialog(initial: initial),
    );

class _PlaylistNameDialog extends StatefulWidget {
  const _PlaylistNameDialog({this.initial});
  final String? initial;
  @override
  State<_PlaylistNameDialog> createState() => _PlaylistNameDialogState();
}

class _PlaylistNameDialogState extends State<_PlaylistNameDialog> {
  late final controller = TextEditingController(text: widget.initial);
  final form = GlobalKey<FormState>();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _save() {
    if (form.currentState!.validate()) {
      Navigator.pop(context, controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.initial == null ? 'Playlist mới' : 'Đổi tên playlist'),
    content: Form(
      key: form,
      child: TextFormField(
        controller: controller,
        autofocus: true,
        maxLength: 60,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Tên playlist',
          hintText: 'Ví dụ: Một ngày thật chill',
        ),
        validator: (value) =>
            value == null || value.trim().isEmpty ? 'Nhập tên playlist.' : null,
        onFieldSubmitted: (_) => _save(),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton(onPressed: _save, child: const Text('Lưu')),
    ],
  );
}

Future<void> createMusicPlaylist(
  BuildContext context,
  PlaylistService library,
) async {
  if (!await requireMusicAccount(context, library) || !context.mounted) return;
  final name = await _askPlaylistName(context);
  if (name != null && context.mounted) {
    await runMusicAction(context, () async {
      await library.createPlaylist(name);
    });
  }
}

Future<void> choosePlaylistForSong(
  BuildContext context,
  PlaylistService library,
  SongModel song,
) async {
  if (!await requireMusicAccount(context, library) || !context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => ListenableBuilder(
      listenable: library,
      builder: (context, _) => SizedBox(
        height: MediaQuery.sizeOf(context).height * .55,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thêm vào playlist',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    song.title,
                    style: TextStyle(color: MusicPalette.of(context).muted),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final playlist in library.playlists)
                    ListTile(
                      leading: Icon(
                        Icons.playlist_play_rounded,
                        color: MusicPalette.of(context).primary,
                      ),
                      title: Text(playlist.name),
                      subtitle: Text('${playlist.songIds.length} bài hát'),
                      trailing: playlist.songIds.contains(song.id)
                          ? Icon(
                              Icons.check_rounded,
                              color: MusicPalette.of(context).primary,
                            )
                          : const Icon(Icons.add_rounded),
                      onTap: library.busy || playlist.songIds.contains(song.id)
                          ? null
                          : () async {
                              final success = await runMusicAction(
                                context,
                                () => library.addSongToPlaylist(
                                  playlist.id,
                                  song.id,
                                ),
                              );
                              if (success && sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                              }
                            },
                    ),
                  if (library.playlists.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Tạo playlist đầu tiên để lưu bài hát này.',
                        style: TextStyle(color: MusicPalette.of(context).muted),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: FilledButton.icon(
                onPressed: library.busy
                    ? null
                    : () async {
                        final name = await _askPlaylistName(context);
                        if (name == null || !context.mounted) return;
                        final success = await runMusicAction(context, () async {
                          await library.createPlaylist(
                            name,
                            songIds: [song.id],
                          );
                        });
                        if (success && sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                        }
                      },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Tạo playlist mới'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> showPlaylistMenu(
  BuildContext context,
  PlaylistService library,
  PlaylistModel playlist,
  String action,
) async {
  if (action == 'rename') {
    final name = await _askPlaylistName(context, initial: playlist.name);
    if (name != null && context.mounted) {
      await runMusicAction(
        context,
        () => library.renamePlaylist(playlist.id, name),
      );
    }
  } else if (action == 'delete') {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa playlist?'),
        content: Text(
          'Xóa “${playlist.name}” khỏi thư viện của bạn? Các bài hát vẫn có trong Khám phá.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Giữ lại'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await runMusicAction(context, () => library.deletePlaylist(playlist.id));
    }
  }
}
