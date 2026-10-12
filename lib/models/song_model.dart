class SongModel {
  const SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.imageUrl,
    required this.audioUrl,
    this.genre,
    this.isVisible = true,
    this.sourceUrl,
    this.licenseUrl,
  });

  factory SongModel.fromFirestore(String id, Map<String, dynamic> data) {
    String readString(String field) {
      final value = data[field];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('Bài hát $id thiếu trường $field hợp lệ.');
      }
      return value;
    }

    String? readOptionalString(String field) {
      final value = data[field];
      if (value != null && value is! String) {
        throw FormatException('Bài hát $id có trường $field không hợp lệ.');
      }
      final text = (value as String?)?.trim();
      return text == null || text.isEmpty ? null : text;
    }

    final visibleValue = data['isVisible'];
    if (data.containsKey('isVisible') && visibleValue is! bool) {
      throw FormatException('Bài hát $id có trường isVisible không hợp lệ.');
    }

    return SongModel(
      id: id,
      title: readString('title'),
      artist: readString('artist'),
      imageUrl: readString('imageUrl'),
      audioUrl: readString('audioUrl'),
      genre: readOptionalString('genre'),
      isVisible: visibleValue as bool? ?? true,
      sourceUrl: readOptionalString('sourceUrl'),
      licenseUrl: readOptionalString('licenseUrl'),
    );
  }

  final String id;
  final String title;
  final String artist;
  final String imageUrl;
  final String audioUrl;
  final String? genre;
  // Archived songs remain available to existing favorites and playlists.
  final bool isVisible;
  final String? sourceUrl;
  final String? licenseUrl;
}
