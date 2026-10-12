import 'package:flutter/material.dart';

import '../models/song_model.dart';
import '../services/audio_service.dart';
import '../services/playlist_service.dart';
import '../theme/music_theme.dart';
import '../utils/music_helpers.dart';
import '../widgets/album_cover.dart';
import '../widgets/empty_panel.dart';
import '../widgets/error_notice.dart';
import '../widgets/mini_player.dart';
import '../widgets/playlist_actions.dart';
import '../widgets/section_header.dart';
import '../widgets/song_tile.dart';
import 'account_screen.dart';
import 'library_screen.dart';
import 'player_screen.dart';

String normalizeSearchText(String value) {
  var result = value.toLowerCase();
  const groups = {
    'a': 'àáạảãâầấậẩẫăằắặẳẵ',
    'e': 'èéẹẻẽêềếệểễ',
    'i': 'ìíịỉĩ',
    'o': 'òóọỏõôồốộổỗơờớợởỡ',
    'u': 'ùúụủũưừứựửữ',
    'y': 'ỳýỵỷỹ',
    'd': 'đ',
  };
  for (final group in groups.entries) {
    result = result.replaceAll(RegExp('[${group.value}]'), group.key);
  }
  return result.replaceAll(RegExp(r'[\u0300-\u036f]'), '').trim();
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.music,
    required this.library,
    this.onRefresh,
  });
  final AudioService music;
  final PlaylistService library;
  final Future<void> Function()? onRefresh;
  @override
  State<HomeScreen> createState() => _MusicHomeState();
}

class _MusicHomeState extends State<HomeScreen> {
  final _search = TextEditingController();
  int _tab = 0;
  bool _refreshing = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openPlayer() => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) =>
          PlayerScreen(music: widget.music, library: widget.library),
    ),
  );

  void _play(SongModel song, List<SongModel> songs, String name) {
    runMusicAction(
      context,
      () => widget.music.playSong(song, fromSongs: songs, queueName: name),
    );
    _openPlayer();
  }

  Future<void> _refresh() async {
    if (_refreshing || widget.onRefresh == null) return;
    setState(() => _refreshing = true);
    await runMusicAction(context, widget.onRefresh!);
    if (mounted) setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([widget.music, widget.library]),
    builder: (context, _) => Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _tab,
          children: [
            _explore(context),
            LibraryScreen(
              music: widget.music,
              library: widget.library,
              onPlay: _play,
            ),
            AccountScreen(library: widget.library),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.music.currentSong != null)
            MiniPlayer(music: widget.music, onOpen: _openPlayer),
          NavigationBar(
            height: 70,
            selectedIndex: _tab,
            onDestinationSelected: (index) {
              FocusScope.of(context).unfocus();
              setState(() => _tab = index);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore_rounded),
                label: 'Khám phá',
              ),
              NavigationDestination(
                icon: Icon(Icons.library_music_outlined),
                selectedIcon: Icon(Icons.library_music_rounded),
                label: 'Thư viện',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Tài khoản',
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _explore(BuildContext context) {
    final palette = MusicPalette.of(context);
    final music = widget.music;
    final library = widget.library;
    final query = normalizeSearchText(_search.text);
    final catalogue = music.songs.where((song) => song.isVisible).toList();
    final filtered = catalogue
        .where(
          (song) =>
              normalizeSearchText('${song.title} ${song.artist}')
                  .contains(query),
        )
        .toList();
    final list = ListView(
      key: const PageStorageKey('explore-list'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: palette.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.graphic_eq_rounded,
                color: palette.onPrimary,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'DYN MUSIC',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ),
            if (widget.onRefresh != null)
              IconButton(
                tooltip: 'Tải lại bài hát',
                onPressed: _refreshing ? null : _refresh,
                icon: _refreshing
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        Icons.refresh_rounded,
                        size: 21,
                        color: palette.muted,
                      ),
              ),
            IconButton(
              tooltip: 'Mở tài khoản',
              onPressed: () => setState(() => _tab = 2),
              icon: CircleAvatar(
                radius: 18,
                backgroundColor: palette.primaryContainer,
                child: Text(
                  library.user?.displayName.characters.firstOrNull
                          ?.toUpperCase() ??
                      'D',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: palette.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          key: const ValueKey('song-search'),
          controller: _search,
          onChanged: (_) => setState(() {}),
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => FocusScope.of(context).unfocus(),
          decoration: InputDecoration(
            hintText: 'Tìm bài hát, nghệ sĩ…',
            prefixIcon: Icon(Icons.search_rounded, color: palette.muted),
            suffixIcon: _search.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Xóa tìm kiếm',
                    onPressed: () {
                      _search.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
          ),
        ),
        if (query.isEmpty && catalogue.isNotEmpty) ...[
          const SizedBox(height: 16),
          _FeaturedCard(
            song: catalogue.first,
            onPlay: () => _play(catalogue.first, catalogue, 'Khám phá'),
          ),
        ],
        SectionHeader(
          title: query.isEmpty ? 'Danh sách bài hát' : 'Kết quả tìm kiếm',
          subtitle:
              '${filtered.length} bài hát${query.isEmpty ? ' · Chạm để nghe' : ''}',
          action: filtered.isEmpty
              ? null
              : FilledButton.tonalIcon(
                  onPressed: () => _play(
                    filtered.first,
                    filtered,
                    query.isEmpty ? 'Khám phá' : 'Kết quả tìm kiếm',
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const Text('Phát'),
                ),
        ),
        if (music.error != null)
          MusicErrorBanner(
            message: music.error!,
            onRetry: () => runMusicAction(context, music.retry),
            onDismiss: music.clearError,
          ),
        if (filtered.isEmpty)
          EmptyPanel(
            icon: query.isEmpty
                ? Icons.music_note_outlined
                : Icons.search_off_rounded,
            title: query.isEmpty
                ? 'Chưa có bài hát'
                : 'Chưa tìm thấy giai điệu',
            message: query.isEmpty
                ? 'Tải lại danh sách để khám phá những bài hát mới.'
                : 'Thử tìm theo tên bài hát hoặc nghệ sĩ khác.',
            action: query.isEmpty && widget.onRefresh != null
                ? OutlinedButton.icon(
                    onPressed: _refreshing ? null : _refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Tải lại'),
                  )
                : null,
          )
        else
          for (final song in filtered)
            SongTile(
              song: song,
              active: music.currentSong?.id == song.id,
              playing: music.playing,
              onTap: () => _play(
                song,
                filtered,
                query.isEmpty ? 'Khám phá' : 'Kết quả tìm kiếm',
              ),
              favorite: library.isFavorite(song.id),
              onFavorite: library.busy
                  ? null
                  : () => toggleSongFavorite(context, library, song),
              onAddToPlaylist: () =>
                  choosePlaylistForSong(context, library, song),
            ),
        const SizedBox(height: 20),
        if (query.isEmpty)
          Center(
            child: Text(
              'MỘT BÀI HÁT · MỘT KHOẢNH KHẮC',
              style: TextStyle(
                fontSize: 9,
                color: palette.muted,
                letterSpacing: 2,
              ),
            ),
          ),
      ],
    );
    return widget.onRefresh == null
        ? list
        : RefreshIndicator(onRefresh: _refresh, child: list);
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.song, required this.onPlay});
  final SongModel song;
  final VoidCallback onPlay;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          MusicPalette.of(context).heroStart,
          MusicPalette.of(context).heroEnd,
        ],
      ),
      border: Border.all(color: MusicPalette.of(context).border),
    ),
    child: Row(
      children: [
        AlbumCover(song: song, size: 64, radius: 14),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GIAI ĐIỆU HÔM NAY',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                  color: MusicPalette.of(context).primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                song.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: MusicPalette.of(context).muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Tooltip(
          message: 'Nghe ngay ${song.title}',
          child: SizedBox.square(
            dimension: 44,
            child: FilledButton(
              onPressed: onPlay,
              style: FilledButton.styleFrom(
                minimumSize: const Size.square(44),
                padding: EdgeInsets.zero,
                shape: const CircleBorder(),
              ),
              child: const Icon(Icons.play_arrow_rounded, size: 26),
            ),
          ),
        ),
      ],
    ),
  );
}
