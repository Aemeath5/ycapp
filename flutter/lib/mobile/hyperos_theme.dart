import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A mobile-only visual layer inspired by Xiaomi HyperOS.
///
/// It deliberately builds on RustDesk's existing themes so desktop and web
/// keep their current appearance and behavior.
class HyperosTheme {
  HyperosTheme._();

  // HyperCeiler uses MIUIX's HyperOS blue (#0D84FF) for interactive states.
  static const Color accent = Color(0xFF0D84FF);

  static const Color lightBackground = Color(0xFFF4F5F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceMuted = Color(0xFFF1F2F6);
  static const Color lightAccentSurface = Color(0xFFE9F3FF);
  static const Color lightText = Color(0xFF17181A);
  static const Color lightSecondaryText = Color(0xFF898C93);
  static const Color lightBorder = Color(0x0D000000);

  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF1C1C1E);
  static const Color darkSurfaceMuted = Color(0xFF2C2C2E);
  static const Color darkAccentSurface = Color(0xFF182D43);
  static const Color darkText = Color(0xFFF4F4F6);
  static const Color darkSecondaryText = Color(0xFFA5A7AD);
  static const Color darkBorder = Color(0x14FFFFFF);

  static ThemeData light(ThemeData base) => _build(
        base: base,
        brightness: Brightness.light,
        background: lightBackground,
        surface: lightSurface,
        surfaceMuted: lightSurfaceMuted,
        text: lightText,
        secondaryText: lightSecondaryText,
        border: lightBorder,
      );

  static ThemeData dark(ThemeData base) => _build(
        base: base,
        brightness: Brightness.dark,
        background: darkBackground,
        surface: darkSurface,
        surfaceMuted: darkSurfaceMuted,
        text: darkText,
        secondaryText: darkSecondaryText,
        border: darkBorder,
      );

  static ThemeData _build({
    required ThemeData base,
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color surfaceMuted,
    required Color text,
    required Color secondaryText,
    required Color border,
  }) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = base.colorScheme.copyWith(
      brightness: brightness,
      primary: accent,
      secondary: accent,
      background: background,
      surface: surface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: text,
      onSurface: text,
    );

    return base.copyWith(
      brightness: brightness,
      primaryColor: accent,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: surface,
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogBackgroundColor: surface,
      dividerColor: border,
      hintColor: secondaryText,
      colorScheme: colorScheme,
      iconTheme: IconThemeData(color: text),
      primaryIconTheme: const IconThemeData(color: accent),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: background,
        foregroundColor: text,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: background,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
        ),
        titleSpacing: 20,
        toolbarHeight: 68,
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        elevation: 0,
        selectedItemColor: accent,
        unselectedItemColor: secondaryText,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
      ),
      dialogTheme: DialogTheme(
        elevation: 18,
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: TextStyle(color: secondaryText),
        labelStyle: TextStyle(color: secondaryText),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 50),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          backgroundColor: surface,
          foregroundColor: text,
          minimumSize: const Size(48, 50),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color?>((states) {
          if (states.contains(MaterialState.disabled)) {
            return secondaryText.withOpacity(0.45);
          }
          return states.contains(MaterialState.selected)
              ? Colors.white
              : surface;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color?>((states) {
          if (states.contains(MaterialState.disabled)) {
            return border;
          }
          return states.contains(MaterialState.selected)
              ? accent
              : secondaryText.withOpacity(0.35);
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        fillColor: MaterialStateProperty.resolveWith<Color?>((states) {
          return states.contains(MaterialState.selected) ? accent : null;
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color?>((states) {
          return states.contains(MaterialState.selected)
              ? accent
              : secondaryText;
        }),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: accent,
        textColor: text,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18),
        minVerticalPadding: 12,
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 0.5, space: 1),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? darkSurfaceMuted : lightText,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      textTheme: base.textTheme.copyWith(
        headlineSmall: TextStyle(
          color: text,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
        ),
        titleLarge: TextStyle(
          color: text,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        titleMedium: TextStyle(
          color: text,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: text, fontSize: 16, height: 1.35),
        bodyMedium: TextStyle(color: text, fontSize: 14, height: 1.35),
        bodySmall: TextStyle(color: secondaryText, fontSize: 12, height: 1.3),
        labelLarge: const TextStyle(
          color: accent,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color background(BuildContext context) =>
      isDark(context) ? darkBackground : lightBackground;

  static Color surface(BuildContext context) =>
      isDark(context) ? darkSurface : lightSurface;

  static Color surfaceMuted(BuildContext context) =>
      isDark(context) ? darkSurfaceMuted : lightSurfaceMuted;

  static Color accentSurface(BuildContext context) =>
      isDark(context) ? darkAccentSurface : lightAccentSurface;

  static Color text(BuildContext context) =>
      isDark(context) ? darkText : lightText;

  static Color secondaryText(BuildContext context) =>
      isDark(context) ? darkSecondaryText : lightSecondaryText;

  static Color border(BuildContext context) =>
      isDark(context) ? darkBorder : lightBorder;

  /// Flutter's closest equivalent to MIUIX SpringBackLayout.
  static const ScrollPhysics springPhysics = BouncingScrollPhysics(
    parent: AlwaysScrollableScrollPhysics(),
  );

  static List<BoxShadow> shadow(BuildContext context) => [
        BoxShadow(
          color: Colors.black.withOpacity(isDark(context) ? 0.20 : 0.08),
          blurRadius: 20,
          offset: const Offset(0, 7),
        ),
      ];

  static List<BoxShadow> capsuleShadow(BuildContext context) => [
        BoxShadow(
          color: Colors.black.withOpacity(isDark(context) ? 0.34 : 0.12),
          blurRadius: 40,
          offset: const Offset(1, 12),
        ),
      ];
}
