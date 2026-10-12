import 'package:flutter/material.dart';

import '../models/song_model.dart';

Future<bool> runMusicAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
    return true;
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
    return false;
  }
}

String formatMusicTime(Duration duration) {
  final seconds = duration.inSeconds.clamp(0, 999999);
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

typedef PlaySelection = void Function(
  SongModel song,
  List<SongModel> songs,
  String name,
);

List<SongModel> songsForIds(List<SongModel> songs, Iterable<String> ids) {
  final map = {for (final song in songs) song.id: song};
  return [
    for (final id in ids)
      if (map.containsKey(id)) map[id]!,
  ];
}
