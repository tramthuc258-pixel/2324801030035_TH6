import 'package:flutter/material.dart';

import '../theme/music_theme.dart';

class PlaybackControlIcon extends StatelessWidget {
  const PlaybackControlIcon({
    super.key,
    required this.playing,
    required this.loading,
    this.size = 42,
    this.color,
  });
  final bool playing;
  final bool loading;
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: [
      if (loading)
        SizedBox.square(
          dimension: size + 8,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: (color ?? MusicPalette.of(context).onPrimary).withValues(
              alpha: .5,
            ),
          ),
        ),
      Icon(
        playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
        size: loading ? size - 6 : size,
        color: color,
      ),
    ],
  );
}
