import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/song_model.dart';
import '../theme/music_theme.dart';
import '../utils/music_helpers.dart';

class SongCredits extends StatelessWidget {
  const SongCredits({super.key, required this.song});
  final SongModel song;

  Future<void> _open(BuildContext context, String url) async {
    await runMusicAction(context, () async {
      final uri = Uri.tryParse(url);
      if (uri == null || !['https', 'http'].contains(uri.scheme)) {
        throw Exception('Địa chỉ nguồn nhạc không hợp lệ.');
      }
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Chưa mở được trang nguồn nhạc.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final source = song.sourceUrl;
    if (source == null) return const SizedBox.shrink();
    final palette = MusicPalette.of(context);
    final license = song.licenseUrl;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nguồn nhạc', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            '${song.title} — ${song.artist}',
            style: TextStyle(color: palette.muted, fontSize: 12),
          ),
          const SizedBox(height: 3),
          SelectableText(
            Uri.tryParse(source)?.host ?? source,
            style: TextStyle(color: palette.muted, fontSize: 11),
          ),
          Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: () => _open(context, source),
                icon: const Icon(Icons.open_in_new_rounded, size: 15),
                label: const Text('Trang nghệ sĩ'),
              ),
              if (license != null)
                TextButton(
                  onPressed: () => _open(context, license),
                  child: Text(
                    license == 'https://creativecommons.org/licenses/by/4.0/'
                        ? 'CC BY 4.0'
                        : 'Giấy phép',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
