import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

@immutable
class MusicPalette extends ThemeExtension<MusicPalette> {
  const MusicPalette({
    required this.background,
    required this.surface,
    required this.raised,
    required this.primary,
    required this.secondary,
    required this.muted,
    required this.text,
    required this.border,
    required this.primaryContainer,
    required this.onPrimary,
    required this.heroStart,
    required this.heroEnd,
  });
  final Color background,
      surface,
      raised,
      primary,
      secondary,
      muted,
      text,
      border,
      primaryContainer,
      onPrimary,
      heroStart,
      heroEnd;

  static const light = MusicPalette(
    background: Color(0xFFF7F7FC),
    surface: Color(0xFFFFFFFF),
    raised: Color(0xFFEFEDF8),
    primary: Color(0xFF6D4DE6),
    secondary: Color(0xFFB85935),
    muted: Color(0xFF696579),
    text: Color(0xFF242035),
    border: Color(0xFFE4E0EF),
    primaryContainer: Color(0xFFECE5FF),
    onPrimary: Color(0xFFFFFFFF),
    heroStart: Color(0xFFEDE6FF),
    heroEnd: Color(0xFFFBEDE7),
  );
  static const dark = MusicPalette(
    background: Color(0xFF111019),
    surface: Color(0xFF1C1A28),
    raised: Color(0xFF282537),
    primary: Color(0xFFB8A3FF),
    secondary: Color(0xFFF0B597),
    muted: Color(0xFFABA6BD),
    text: Color(0xFFF4F1FF),
    border: Color(0xFF373247),
    primaryContainer: Color(0xFF382958),
    onPrimary: Color(0xFF22123D),
    heroStart: Color(0xFF32264F),
    heroEnd: Color(0xFF332630),
  );
  static MusicPalette of(BuildContext context) =>
      Theme.of(context).extension<MusicPalette>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  @override
  MusicPalette copyWith({
    Color? background,
    Color? surface,
    Color? raised,
    Color? primary,
    Color? secondary,
    Color? muted,
    Color? text,
    Color? border,
    Color? primaryContainer,
    Color? onPrimary,
    Color? heroStart,
    Color? heroEnd,
  }) => MusicPalette(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    raised: raised ?? this.raised,
    primary: primary ?? this.primary,
    secondary: secondary ?? this.secondary,
    muted: muted ?? this.muted,
    text: text ?? this.text,
    border: border ?? this.border,
    primaryContainer: primaryContainer ?? this.primaryContainer,
    onPrimary: onPrimary ?? this.onPrimary,
    heroStart: heroStart ?? this.heroStart,
    heroEnd: heroEnd ?? this.heroEnd,
  );

  @override
  MusicPalette lerp(covariant MusicPalette? other, double t) {
    if (other == null) return this;
    Color blend(Color a, Color b) => Color.lerp(a, b, t)!;
    return MusicPalette(
      background: blend(background, other.background),
      surface: blend(surface, other.surface),
      raised: blend(raised, other.raised),
      primary: blend(primary, other.primary),
      secondary: blend(secondary, other.secondary),
      muted: blend(muted, other.muted),
      text: blend(text, other.text),
      border: blend(border, other.border),
      primaryContainer: blend(primaryContainer, other.primaryContainer),
      onPrimary: blend(onPrimary, other.onPrimary),
      heroStart: blend(heroStart, other.heroStart),
      heroEnd: blend(heroEnd, other.heroEnd),
    );
  }
}

ThemeData buildMusicTheme({Brightness brightness = Brightness.dark}) {
  final palette = brightness == Brightness.dark
      ? MusicPalette.dark
      : MusicPalette.light;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: palette.primary,
        brightness: brightness,
      ).copyWith(
        primary: palette.primary,
        onPrimary: palette.onPrimary,
        primaryContainer: palette.primaryContainer,
        onPrimaryContainer: palette.text,
        secondary: palette.secondary,
        surface: palette.surface,
        onSurface: palette.text,
        onSurfaceVariant: palette.muted,
        outline: palette.border,
        outlineVariant: palette.border,
        surfaceContainerLow: palette.surface,
        surfaceContainer: palette.surface,
        surfaceContainerHigh: palette.raised,
        surfaceContainerHighest: palette.raised,
      );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  OutlineInputBorder inputBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: color),
  );
  return base.copyWith(
    extensions: [palette],
    scaffoldBackgroundColor: palette.background,
    appBarTheme: AppBarTheme(
      backgroundColor: palette.background,
      foregroundColor: palette.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
    ),
    textTheme: base.textTheme
        .copyWith(
          headlineLarge: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -.9,
          ),
          headlineMedium: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -.6,
          ),
          titleLarge: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: const TextStyle(fontSize: 16, height: 1.4),
          bodyMedium: const TextStyle(fontSize: 14, height: 1.4),
          bodySmall: TextStyle(fontSize: 12, color: palette.muted, height: 1.4),
        )
        .apply(bodyColor: palette.text, displayColor: palette.text)
        .copyWith(
          bodySmall: TextStyle(fontSize: 12, color: palette.muted, height: 1.4),
        ),
    iconTheme: IconThemeData(color: palette.muted),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.raised,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      border: inputBorder(Colors.transparent),
      enabledBorder: inputBorder(Colors.transparent),
      focusedBorder: inputBorder(palette.primary),
      errorBorder: inputBorder(scheme.error),
      focusedErrorBorder: inputBorder(scheme.error),
      hintStyle: TextStyle(color: palette.muted),
      labelStyle: TextStyle(color: palette.muted),
      prefixIconColor: palette.muted,
      suffixIconColor: palette.muted,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 50),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 50),
        foregroundColor: palette.text,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide(color: palette.border),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: palette.primaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: states.contains(WidgetState.selected)
              ? palette.primary
              : palette.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? palette.primary
              : palette.muted,
        ),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: palette.border,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: brightness == Brightness.dark
          ? palette.raised
          : palette.text,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: DividerThemeData(color: palette.border, thickness: 1),
    popupMenuTheme: PopupMenuThemeData(
      color: palette.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );
}
