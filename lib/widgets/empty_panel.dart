import 'package:flutter/material.dart';

import '../theme/music_theme.dart';

class EmptyPanel extends StatelessWidget {
  const EmptyPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: MusicPalette.of(context).surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: MusicPalette.of(context).border),
    ),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: MusicPalette.of(context).primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: MusicPalette.of(context).primary, size: 30),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: MusicPalette.of(context).muted, height: 1.5),
        ),
        if (action != null)
          Padding(padding: const EdgeInsets.only(top: 18), child: action!),
      ],
    ),
  );
}
