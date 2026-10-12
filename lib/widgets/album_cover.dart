import 'package:flutter/material.dart';

import '../models/song_model.dart';

class AlbumCover extends StatelessWidget {
  const AlbumCover({
    super.key,
    required this.song,
    this.size = 56,
    this.radius = 14,
  });

  final SongModel? song;
  final double size;
  final double radius;

  // These local copies keep the catalogue artwork visible during loading or
  // when the image host cannot be reached. Other covers still use imageUrl.
  static const _bundledPhotos = {
    'photo-1493225457124-a3eb161ffa5f': 'assets/covers/song_01.jpg',
    'photo-1519608487953-e999c86e7455': 'assets/covers/song_02.jpg',
    'photo-1500534623283-312aade485b7': 'assets/covers/song_03.jpg',
    'photo-1441974231531-c6227db76b6e': 'assets/covers/song_04.jpg',
    'photo-1475924156734-496f6cac6ec1': 'assets/covers/song_05.jpg',
    'photo-1518837695005-2083093ee35b': 'assets/covers/song_06.jpg',
  };

  static const _artistCovers = {
    '/nextImages/albums/33-150.jpg': 'assets/covers/josh_33.jpg',
    '/nextImages/albums/Sandcastles-150.jpg':
        'assets/covers/josh_sandcastles.jpg',
    '/nextImages/albums/Breadcrumbs-150.jpg':
        'assets/covers/josh_breadcrumbs.jpg',
    '/nextImages/albums/TheBeautifulMachine-150.jpg':
        'assets/covers/josh_the_beautiful_machine.jpg',
    '/nextImages/albums/Ashes-150.jpg': 'assets/covers/josh_ashes.jpg',
  };

  String? get _bundledCover {
    final uri = Uri.tryParse(song?.imageUrl ?? '');
    if (uri?.host == 'www.joshwoodward.com') return _artistCovers[uri!.path];
    if (uri?.host != 'images.unsplash.com') return null;
    return _bundledPhotos[uri!.pathSegments.lastOrNull];
  }

  @override
  Widget build(BuildContext context) {
    final seed =
        (song?.id.codeUnits.fold<int>(0, (sum, value) => sum + value) ?? 0) % 4;
    const gradients = [
      [Color(0xFF2D4D89), Color(0xFFAF74BC)],
      [Color(0xFF14636B), Color(0xFF5ED8BE)],
      [Color(0xFF704F92), Color(0xFFDD819C)],
      [Color(0xFF375581), Color(0xFFF0AD77)],
    ];
    Widget placeholder() => DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradients[seed],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.graphic_eq_rounded,
          size: size * .45,
          color: Colors.white.withValues(alpha: .8),
        ),
      ),
    );
    final asset = _bundledCover;
    Widget fallback() => asset == null
        ? placeholder()
        : Image.asset(
            asset,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            errorBuilder: (_, _, _) => placeholder(),
          );
    return Semantics(
      image: true,
      label: song == null ? 'Ảnh bìa bài hát' : 'Ảnh bìa ${song!.title}',
      child: SizedBox.square(
        dimension: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: song == null
              ? placeholder()
              : Image.network(
                  song!.imageUrl,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                  errorBuilder: (_, _, _) => fallback(),
                  loadingBuilder: (context, child, loading) =>
                      loading == null ? child : fallback(),
                ),
        ),
      ),
    );
  }
}
