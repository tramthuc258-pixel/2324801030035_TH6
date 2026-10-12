import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../services/playlist_service.dart';
import '../utils/music_helpers.dart';
import 'playlist_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({
    super.key,
    required this.music,
    required this.library,
    required this.onPlay,
  });
  final AudioService music;
  final PlaylistService library;
  final PlaySelection onPlay;
  @override
  Widget build(BuildContext context) => PlaylistScreen(
    music: music,
    library: library,
    onPlay: onPlay,
    kind: PlaylistKind.favorites,
  );
}
