import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 应用主题配置
///
/// 设计理念：
/// - 主色采用深紫罗兰（Indigo-Violet），传递专业、现代、智能的调性
/// - 辅助色采用品红（Magenta），用于强调与点缀
/// - 中性色采用冷灰阶，层次细腻
/// - 卡片采用柔和阴影 + 微圆角，营造轻盈的卡片悬浮感
class AppTheme {
  AppTheme._();

  // ============ 亮色模式 ============
  // 品牌色：深紫罗兰
  static const Color _primary = Color(0xFF5B5BD6);
  // 辅助色：品红
  static const Color _secondary = Color(0xFFE84A8A);
  // 强调色（渐变终点）
  static const Color _accent = Color(0xFF8B5CF6);

  // 语义色
  static const Color _error = Color(0xFFEF4444);
  static const Color _success = Color(0xFF10B981);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _info = Color(0xFF3B82F6);

  // 中性色（冷灰阶）
  static const Color _textPrimary = Color(0xFF1A1D29);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _textHint = Color(0xFF9CA3AF);
  static const Color _divider = Color(0xFFEDEEF2);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _surfaceAlt = Color(0xFFF7F7FB);
  static const Color _background = Color(0xFFF4F4F8);

  // ============ 暗色模式 ============
  static const Color _darkPrimary = Color(0xFF9B9BF5);
  static const Color _darkSecondary = Color(0xFFF06292);
  static const Color _darkAccent = Color(0xFFA78BFA);

  static const Color _darkTextPrimary = Color(0xFFECECF1);
  static const Color _darkTextSecondary = Color(0xFFA0A3B1);
  static const Color _darkTextHint = Color(0xFF6B6E7A);
  static const Color _darkDivider = Color(0xFF2A2D3A);
  static const Color _darkSurface = Color(0xFF1E2030);
  static const Color _darkSurfaceAlt = Color(0xFF262838);
  static const Color _darkBackground = Color(0xFF15161F);

  /// 品牌渐变（用于按钮、胶囊标签等强调元素）
  static const List<Color> brandGradient = [_primary, _accent];
  static const List<Color> brandGradientDark = [_darkPrimary, _darkAccent];

  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primary = isDark ? _darkPrimary : _primary;
    final onPrimary = isDark ? const Color(0xFF15161F) : Colors.white;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      primary: primary,
      secondary: isDark ? _darkSecondary : _secondary,
      surface: isDark ? _darkSurface : _surface,
      error: isDark ? const Color(0xFFF87171) : _error,
    ).copyWith(
      surfaceContainerHighest:
          isDark ? _darkSurfaceAlt : _surfaceAlt,
      outline: isDark ? _darkDivider : _divider,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? _darkBackground : _background,
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.adaptivePlatformDensity,

      // 状态栏
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: isDark ? _darkBackground : _background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: isDark ? _darkTextPrimary : _textPrimary,
        titleTextStyle: TextStyle(
          color: isDark ? _darkTextPrimary : _textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),

      // 卡片：柔和阴影 + 微圆角
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? _darkSurface : _surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: isDark ? _darkDivider : _divider,
        thickness: 0.5,
        space: 0,
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        titleTextStyle: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDark ? _darkTextPrimary : _textPrimary,
        ),
        subtitleTextStyle: TextStyle(
          fontSize: 13,
          color: isDark ? _darkTextSecondary : _textSecondary,
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? _darkSurface : _surface,
        selectedItemColor: primary,
        unselectedItemColor: isDark ? _darkTextHint : _textHint,
        selectedLabelStyle:
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
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
        fillColor: isDark ? _darkSurfaceAlt : _surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(
          color: isDark ? _darkTextHint : _textHint,
          fontSize: 15,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      textTheme: TextTheme(
        // 大标题
        headlineLarge: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: isDark ? _darkTextPrimary : _textPrimary,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: isDark ? _darkTextPrimary : _textPrimary,
          height: 1.25,
        ),
        // 卡片标题
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: isDark ? _darkTextPrimary : _textPrimary,
          height: 1.3,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isDark ? _darkTextPrimary : _textPrimary,
          height: 1.35,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? _darkTextPrimary : _textPrimary,
        ),
        // 正文
        bodyLarge: TextStyle(
          fontSize: 15,
          color: isDark ? _darkTextPrimary : _textPrimary,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          color: isDark ? _darkTextSecondary : _textSecondary,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: isDark ? _darkTextHint : _textHint,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: primary,
        ),
      ),
    );
  }

  // 语义色访问
  static Color error(Brightness brightness) =>
      brightness == Brightness.dark ? const Color(0xFFF87171) : _error;
  static Color success(Brightness brightness) =>
      brightness == Brightness.dark ? const Color(0xFF34D399) : _success;
  static Color warning(Brightness brightness) =>
      brightness == Brightness.dark ? const Color(0xFFFBBF24) : _warning;
  static Color info(Brightness brightness) =>
      brightness == Brightness.dark ? _darkPrimary : _info;

  /// 卡片阴影
  static List<BoxShadow> cardShadow(Brightness brightness) {
    return [
      BoxShadow(
        color: brightness == Brightness.dark
            ? Colors.black.withValues(alpha: 0.3)
            : const Color(0xFF5B5BD6).withValues(alpha: 0.06),
        blurRadius: 20,
        offset: const Offset(0, 6),
      ),
    ];
  }
}
