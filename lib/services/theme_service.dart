import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class ThemePreferences {
  Future<String?> read();
  Future<void> write(String value);
}

class DeviceThemePreferences implements ThemePreferences {
  SharedPreferencesAsync? _instance;
  SharedPreferencesAsync get _preferences =>
      _instance ??= SharedPreferencesAsync();
  static const _key = 'dyn_music_theme_mode';

  @override
  Future<String?> read() async => _preferences.getString(_key);

  @override
  Future<void> write(String value) async => _preferences.setString(_key, value);
}

class ThemeController extends ChangeNotifier {
  ThemeController({ThemePreferences? preferences})
    : _preferences = preferences ?? DeviceThemePreferences();

  final ThemePreferences _preferences;
  ThemeMode _mode = ThemeMode.system;
  Future<void>? _loading;
  Future<void> _pendingWrite = Future<void>.value();
  int _revision = 0;
  bool _disposed = false;

  ThemeMode get mode => _mode;

  Future<void> load() => _loading ??= _restore();

  Future<void> _restore() async {
    final revision = _revision;
    try {
      final saved = await _preferences.read();
      if (_disposed || revision != _revision) return;
      final restored = switch (saved) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      if (restored != _mode) {
        _mode = restored;
        notifyListeners();
      }
    } catch (_) {
      // Preferences must not prevent Firebase or music from loading.
    }
  }

  Future<void> setMode(ThemeMode value) {
    if (_disposed) return Future<void>.value();
    _revision++;
    if (value != _mode) {
      _mode = value;
      notifyListeners();
    }
    // Preserve the final selection even if the user switches quickly.
    final write = _pendingWrite.then((_) => _preferences.write(value.name));
    _pendingWrite = write.catchError((Object _) {});
    return write;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class MusicThemeScope extends InheritedNotifier<ThemeController> {
  const MusicThemeScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MusicThemeScope>()?.notifier;
}
