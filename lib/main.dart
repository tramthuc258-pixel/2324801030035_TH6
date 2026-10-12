import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/song_model.dart';
import 'screens/home_screen.dart';
import 'services/audio_service.dart';
import 'services/firebase_service.dart';
import 'services/playlist_service.dart';
import 'services/theme_service.dart';
import 'theme/music_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

typedef ReadyAppBuilder = Widget Function(
  BuildContext context,
  List<SongModel> songs,
  Future<void> Function() onRefresh,
);

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    this.initializeFirebase = initializeFirebaseApp,
    this.loadSongs = loadSongsFromFirestore,
    this.readyBuilder,
    this.themeController,
  });

  final FirebaseInitializer initializeFirebase;
  final SongLoader loadSongs;
  final ReadyAppBuilder? readyBuilder;
  final ThemeController? themeController;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final ThemeController _theme;

  @override
  void initState() {
    super.initState();
    _theme = widget.themeController ?? ThemeController();
    unawaited(_theme.load());
  }

  @override
  void dispose() {
    if (widget.themeController == null) _theme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MusicThemeScope(
    controller: _theme,
    child: AnimatedBuilder(
      animation: _theme,
      builder: (context, _) => MaterialApp(
        title: 'DYN MUSIC',
        debugShowCheckedModeBanner: false,
        theme: buildMusicTheme(brightness: Brightness.light),
        darkTheme: buildMusicTheme(),
        themeMode: _theme.mode,
        builder: (context, child) {
          final dark = Theme.of(context).brightness == Brightness.dark;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value:
                (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
                    .copyWith(
                      statusBarColor: Colors.transparent,
                      systemNavigationBarColor: MusicPalette.of(context)
                          .surface,
                    ),
            child: child!,
          );
        },
        home: _MusicBootstrap(
          initializeFirebase: widget.initializeFirebase,
          loadSongs: widget.loadSongs,
          readyBuilder: widget.readyBuilder,
        ),
      ),
    ),
  );
}

class _MusicBootstrap extends StatefulWidget {
  const _MusicBootstrap({
    required this.initializeFirebase,
    required this.loadSongs,
    this.readyBuilder,
  });

  final FirebaseInitializer initializeFirebase;
  final SongLoader loadSongs;
  final ReadyAppBuilder? readyBuilder;

  @override
  State<_MusicBootstrap> createState() => _MusicBootstrapState();
}

class _MusicBootstrapState extends State<_MusicBootstrap> {
  bool _firebaseReady = false;
  bool _loading = true;
  List<SongModel>? _songs;
  String? _error;
  Future<void>? _refreshInFlight;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  Future<void> _start() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (!_firebaseReady) {
        await widget.initializeFirebase();
        _firebaseReady = true;
      }
      final songs = await widget.loadSongs();
      if (!mounted) return;
      setState(() {
        _songs = songs;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _failureMessage(error);
      });
    }
  }

  Future<void> _refresh() => _refreshInFlight ??= _reload().whenComplete(() {
    _refreshInFlight = null;
  });

  Future<void> _reload() async {
    try {
      final songs = await widget.loadSongs();
      if (mounted) setState(() => _songs = songs);
    } catch (error) {
      throw Exception(_failureMessage(error));
    }
  }

  String _failureMessage(Object error) {
    if (error is UnsupportedError) {
      return 'Hãy chạy ứng dụng trên điện thoại hoặc máy ảo Android.';
    }
    if (!_firebaseReady) {
      return 'Chưa kết nối được dịch vụ. Kiểm tra Internet rồi thử lại.';
    }
    if (error is TimeoutException ||
        error is FirebaseException &&
            ['unavailable', 'deadline-exceeded'].contains(error.code)) {
      return 'Kết nối quá thời gian chờ. Kiểm tra Internet rồi thử lại.';
    }
    if (error is FirebaseException && error.code == 'permission-denied') {
      return 'Danh sách bài hát chưa được cấp quyền truy cập. Vui lòng thử lại sau.';
    }
    if (error is FormatException) {
      return 'Thông tin bài hát chưa đầy đủ. Vui lòng thử lại sau.';
    }
    return 'Chưa tải được danh sách bài hát. Kiểm tra Internet rồi thử lại.';
  }

  @override
  Widget build(BuildContext context) {
    final songs = _songs;
    if (!_loading && songs != null) {
      return widget.readyBuilder?.call(context, songs, _refresh) ??
          _ReadyMusic(songs: songs, onRefresh: _refresh);
    }
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.graphic_eq_rounded,
                  size: 72,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'DYN MUSIC',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 24),
                if (_loading) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  const Text('Đang tải âm nhạc…'),
                ] else ...[
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _start,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadyMusic extends StatefulWidget {
  const _ReadyMusic({required this.songs, required this.onRefresh});

  final List<SongModel> songs;
  final Future<void> Function() onRefresh;

  @override
  State<_ReadyMusic> createState() => _ReadyMusicState();
}

class _ReadyMusicState extends State<_ReadyMusic> {
  late final AudioService _music;
  late final PlaylistService _library;

  @override
  void initState() {
    super.initState();
    _music = AudioService()..setSongs(widget.songs);
    _library = PlaylistService();
  }

  @override
  void didUpdateWidget(covariant _ReadyMusic oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.songs, oldWidget.songs)) {
      _music.setSongs(widget.songs);
    }
  }

  @override
  void dispose() {
    _music.dispose();
    _library.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      HomeScreen(music: _music, library: _library, onRefresh: widget.onRefresh);
}
