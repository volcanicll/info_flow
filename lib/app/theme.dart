import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  AppTheme._();

  // Design tokens from design.html (OKLCH → hex)
  static const _canvasLight = Color(0xFFF8F7FC);
  static const _surfaceLight = Color(0xFFFFFFFF);
  static const _surface2Light = Color(0xFFF2F1F7);
  static const _tintLight = Color(0xFFEAE8F5);
  static const _brandLight = Color(0xFF5B5BD6);
  // static const _brandPressLight = Color(0xFF4A4AC0);
  static const _t1Light = Color(0xFF2D2D3A);
  static const _t2Light = Color(0xFF6B6B7D);
  static const _t3Light = Color(0xFF9898A8);
  static const _hairLight = Color(0xFFE5E4EC);
  static const _hairStrongLight = Color(0xFFD0CFDC);

  static const _canvasDark = Color(0xFF20202E);
  static const _surfaceDark = Color(0xFF282838);
  static const _surface2Dark = Color(0xFF303044);
  static const _tintDark = Color(0xFF3B3860);
  static const _brandDark = Color(0xFF8989F0);
  // static const _brandPressDark = Color(0xFF7575E0);
  static const _t1Dark = Color(0xFFE8E8F0);
  static const _t2Dark = Color(0xFFA0A0B8);
  static const _t3Dark = Color(0xFF707088);
  static const _hairDark = Color(0xFF3A3A4E);
  static const _hairStrongDark = Color(0xFF4A4A60);

  static const _loveLight = Color(0xFFD6446A);
  static const _loveDark = Color(0xFFF06292);
  static const _upLight = Color(0xFF2DB88A);
  static const _upDark = Color(0xFF4DD4A8);
  static const _downLight = Color(0xFFD64444);
  static const _downDark = Color(0xFFF0625E);
  static const _warnLight = Color(0xFFD6A040);
  static const _warnDark = Color(0xFFE0B850);

  static ThemeData get lightTheme => _build(Brightness.light);
  static ThemeData get darkTheme => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final canvas = isDark ? _canvasDark : _canvasLight;
    final surface = isDark ? _surfaceDark : _surfaceLight;
    final surface2 = isDark ? _surface2Dark : _surface2Light;
    final brand = isDark ? _brandDark : _brandLight;
    final onBrand = isDark ? _canvasDark : Colors.white;
    final t1 = isDark ? _t1Dark : _t1Light;
    final t2 = isDark ? _t2Dark : _t2Light;
    final t3 = isDark ? _t3Dark : _t3Light;
    final hair = isDark ? _hairDark : _hairLight;
    // final hairStrong = isDark ? _hairStrongDark : _hairStrongLight;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: brand,
      onPrimary: onBrand,
      secondary: isDark ? _loveDark : _loveLight,
      onSecondary: Colors.white,
      error: isDark ? _downDark : _downLight,
      onError: Colors.white,
      surface: surface,
      onSurface: t1,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: canvas,
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.adaptivePlatformDensity,

      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: t1,
        titleTextStyle: TextStyle(
          color: t1,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),

      dividerTheme: DividerThemeData(
        color: hair,
        thickness: 0.5,
        space: 0,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: surface.withValues(alpha: 0.88),
        elevation: 0,
      ),

      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        side: BorderSide.none,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: hair, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: brand, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        hintStyle: TextStyle(
          color: t3,
          fontSize: 14.5,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: onBrand,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brand,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: t1,
          height: 1.25,
        ),
        headlineMedium: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: t1,
          height: 1.35,
        ),
        titleLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
          color: t1,
          height: 1.38,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: t2,
          height: 1.35,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: t1,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          color: t1,
          height: 1.55,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          color: t2,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: t3,
          fontWeight: FontWeight.w600,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: brand,
        ),
        labelSmall: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: t3,
        ),
      ),
    );
  }

  // Shared shadow styles
  static List<BoxShadow> cardShadow(Brightness brightness) {
    return [
      BoxShadow(
        color: brightness == Brightness.dark
            ? Colors.black.withValues(alpha: 0.3)
            : const Color(0xFF5B5BD6).withValues(alpha: 0.04),
        blurRadius: 2,
        offset: const Offset(0, 1),
      ),
      BoxShadow(
        color: brightness == Brightness.dark
            ? Colors.black.withValues(alpha: 0.24)
            : const Color(0xFF5B5BD6).withValues(alpha: 0.12),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ];
  }

  static List<BoxShadow> floatShadow(Brightness brightness) {
    return [
      BoxShadow(
        color: brightness == Brightness.dark
            ? Colors.black.withValues(alpha: 0.5)
            : const Color(0xFF1C1E2C).withValues(alpha: 0.24),
        blurRadius: 48,
        offset: const Offset(0, 16),
      ),
    ];
  }

  // Semantic colors
  static Color love(Brightness b) => b == Brightness.dark ? _loveDark : _loveLight;
  static Color up(Brightness b) => b == Brightness.dark ? _upDark : _upLight;
  static Color down(Brightness b) => b == Brightness.dark ? _downDark : _downLight;
  static Color warn(Brightness b) => b == Brightness.dark ? _warnDark : _warnLight;
  static Color tint(Brightness b) => b == Brightness.dark ? _tintDark : _tintLight;
  static Color surface2(Brightness b) => b == Brightness.dark ? _surface2Dark : _surface2Light;
  static Color hair(Brightness b) => b == Brightness.dark ? _hairDark : _hairLight;
  static Color hairStrong(Brightness b) => b == Brightness.dark ? _hairStrongDark : _hairStrongLight;
  static Color canvas(Brightness b) => b == Brightness.dark ? _canvasDark : _canvasLight;
}
