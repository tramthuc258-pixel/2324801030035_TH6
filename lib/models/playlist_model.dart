class PlaylistModel {
  PlaylistModel({
    required this.id,
    required this.name,
    required List<String> songIds,
  }) : songIds = List.unmodifiable(songIds.toSet());

  factory PlaylistModel.fromFirestore(String id, Map<String, dynamic> data) {
    final name = data['name'];
    final ids = data['songIds'];
    if (name is! String || name.trim().isEmpty || ids is! List) {
      throw const FormatException('Playlist có dữ liệu chưa hợp lệ.');
    }
    return PlaylistModel(id: id, name: name, songIds: ids.cast<String>());
  }

  final String id;
  final String name;
  final List<String> songIds;

  PlaylistModel copyWith({String? name, List<String>? songIds}) =>
      PlaylistModel(
        id: id,
        name: name ?? this.name,
        songIds: songIds ?? this.songIds,
      );
}
