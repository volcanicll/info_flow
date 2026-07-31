import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// 编辑部/杂志风设计系统。
///
/// 设计原则：纸感底色、墨色文字、发丝线分隔（用线不用影）、
/// 衬线大标题、克制用色（编辑红作唯一强调色）。
///
/// 语义色与结构色统一通过 [AppColors] ThemeExtension 暴露：
/// `Theme.of(context).extension<AppColors>()!`。
/// 旧的静态取色方法保留以兼容尚未迁移的调用点。
class AppTheme {
  AppTheme._();

  // ── 纸感底色 / 墨色文字（Light）──
  static const _paperLight = Color(0xFFFAF9F5); // 纸白
  static const _surfaceLight = Color(0xFFFFFEFB); // 卡面（略暖）
  static const _surface2Light = Color(0xFFF1EEE6); // 次级块面
  static const _tintLight = Color(0xFFEEE9DD); // 强调底纹
  static const _inkLight = Color(0xFF1A1917); // 主文墨黑
  static const _t2Light = Color(0xFF57534E); // 次级文（暖灰）
  static const _t3Light = Color(0xFF8A857D); // 辅助文
  static const _hairLight = Color(0xFFE5E2DA); // 发丝线
  static const _hairStrongLight = Color(0xFFD4CFC3); // 重发丝线
  static const _accentLight = Color(0xFFC0392B); // 编辑红

  // ── 墨黑纸底 / 米白文字（Dark）──
  static const _paperDark = Color(0xFF191817);
  static const _surfaceDark = Color(0xFF201F1D);
  static const _surface2Dark = Color(0xFF2A2825);
  static const _tintDark = Color(0xFF35302A);
  static const _inkDark = Color(0xFFEDE9E0);
  static const _t2Dark = Color(0xFFB0AAA0);
  static const _t3Dark = Color(0xFF7C766C);
  static const _hairDark = Color(0xFF34322E);
  static const _hairStrongDark = Color(0xFF454239);
  static const _accentDark = Color(0xFFE27060);

  // ── 语义色（低饱和，杂志质感）──
  static const _loveLight = Color(0xFFC0392B);
  static const _loveDark = Color(0xFFE27060);
  static const _upLight = Color(0xFF1E7F5C);
  static const _upDark = Color(0xFF4DAF87);
  static const _downLight = Color(0xFFB03A2E);
  static const _downDark = Color(0xFFE07A6E);
  static const _warnLight = Color(0xFFB7791F);
  static const _warnDark = Color(0xFFD6A84A);

  static ThemeData get lightTheme => _build(Brightness.light);
  static ThemeData get darkTheme => _build(Brightness.dark);

  /// 衬线标题字体（Noto Serif SC，杂志标题质感）。
  static TextStyle _serif(TextStyle base) =>
      GoogleFonts.notoSerifSc(textStyle: base);

  /// 行情等宽数字字体（表格化对齐）。
  static TextStyle mono(TextStyle base) =>
      GoogleFonts.robotoMono(textStyle: base);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final paper = isDark ? _paperDark : _paperLight;
    final surface = isDark ? _surfaceDark : _surfaceLight;
    final ink = isDark ? _inkDark : _inkLight;
    final t2 = isDark ? _t2Dark : _t2Light;
    final t3 = isDark ? _t3Dark : _t3Light;
    final hair = isDark ? _hairDark : _hairLight;
    final accent = isDark ? _accentDark : _accentLight;
    final onAccent = isDark ? _paperDark : Colors.white;

    final colors = _appColors(brightness);

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: accent,
      onPrimary: onAccent,
      secondary: isDark ? _loveDark : _loveLight,
      onSecondary: Colors.white,
      error: isDark ? _downDark : _downLight,
      onError: Colors.white,
      surface: surface,
      onSurface: ink,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: paper,
      splashFactory: NoSplash.splashFactory,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      extensions: [colors],

      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: ink,
        titleTextStyle: _serif(TextStyle(
          color: ink,
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        )),
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),

      // 杂志用线不用影：卡片无阴影、无圆角膨胀
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: hair, width: 0.5),
        ),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),

      dividerTheme: DividerThemeData(
        color: hair,
        thickness: 0.5,
        space: 0,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        shape: const StadiumBorder(),
        side: BorderSide(color: hair, width: 1),
        labelStyle: TextStyle(
          color: t2,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),

      // 输入框：极简，无填充，仅底部粗线（铅字排版感）
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: hair, width: 1),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: hair, width: 1),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: ink, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        hintStyle: TextStyle(color: t3, fontSize: 15),
      ),

      // 主按钮：方正墨块，非圆角胶囊
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: paper,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        ),
      ),

      textTheme: _textTheme(ink, t2, t3),
    );
  }

  static TextTheme _textTheme(Color ink, Color t2, Color t3) {
    return TextTheme(
      // 头条 / 大标题：衬线，重字重，紧字距
      displayLarge: _serif(TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        color: ink,
        height: 1.18,
      )),
      displayMedium: _serif(TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        color: ink,
        height: 1.22,
      )),
      headlineLarge: _serif(TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: ink,
        height: 1.28,
      )),
      headlineMedium: _serif(TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: ink,
        height: 1.32,
      )),
      titleLarge: _serif(TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
        color: ink,
        height: 1.36,
      )),
      // 副标题 / 来源栏：无衬线
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: t2,
        height: 1.4,
      ),
      titleSmall: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: ink,
        letterSpacing: 0.2,
      ),
      // 正文：大行高，衬线，阅读舒适
      bodyLarge: _serif(TextStyle(
        fontSize: 16,
        color: ink,
        height: 1.7,
      )),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: t2,
        height: 1.6,
      ),
      bodySmall: TextStyle(
        fontSize: 12.5,
        color: t3,
        height: 1.5,
      ),
      // kicker / 栏目标签：全大写小字，大字距
      labelLarge: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: ink,
        letterSpacing: 0.4,
      ),
      labelMedium: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: t2,
        letterSpacing: 1.5,
      ),
      labelSmall: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: t3,
        letterSpacing: 1.5,
      ),
    );
  }

  static AppColors _appColors(Brightness b) {
    final isDark = b == Brightness.dark;
    return AppColors(
      paper: isDark ? _paperDark : _paperLight,
      surface: isDark ? _surfaceDark : _surfaceLight,
      surface2: isDark ? _surface2Dark : _surface2Light,
      tint: isDark ? _tintDark : _tintLight,
      ink: isDark ? _inkDark : _inkLight,
      inkSecondary: isDark ? _t2Dark : _t2Light,
      inkTertiary: isDark ? _t3Dark : _t3Light,
      hairline: isDark ? _hairDark : _hairLight,
      hairlineStrong: isDark ? _hairStrongDark : _hairStrongLight,
      accent: isDark ? _accentDark : _accentLight,
      up: isDark ? _upDark : _upLight,
      down: isDark ? _downDark : _downLight,
      warn: isDark ? _warnDark : _warnLight,
      love: isDark ? _loveDark : _loveLight,
    );
  }

  // ── 兼容旧静态取色 API（页面逐步迁移到 AppColors 后可移除）──
  static Color love(Brightness b) => b == Brightness.dark ? _loveDark : _loveLight;
  static Color up(Brightness b) => b == Brightness.dark ? _upDark : _upLight;
  static Color down(Brightness b) => b == Brightness.dark ? _downDark : _downLight;
  static Color warn(Brightness b) => b == Brightness.dark ? _warnDark : _warnLight;
  static Color tint(Brightness b) => b == Brightness.dark ? _tintDark : _tintLight;
  static Color surface2(Brightness b) =>
      b == Brightness.dark ? _surface2Dark : _surface2Light;
  static Color hair(Brightness b) => b == Brightness.dark ? _hairDark : _hairLight;
  static Color hairStrong(Brightness b) =>
      b == Brightness.dark ? _hairStrongDark : _hairStrongLight;
  static Color canvas(Brightness b) => b == Brightness.dark ? _paperDark : _paperLight;

  /// 杂志风取消卡片阴影，保留空实现以兼容旧调用（返回空阴影）。
  static List<BoxShadow> cardShadow(Brightness brightness) => const [];
}

/// 语义色与结构色扩展。所有页面通过
/// `Theme.of(context).extension<AppColors>()!` 取色，禁止硬编码。
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color paper;
  final Color surface;
  final Color surface2;
  final Color tint;
  final Color ink;
  final Color inkSecondary;
  final Color inkTertiary;
  final Color hairline;
  final Color hairlineStrong;
  final Color accent;
  final Color up;
  final Color down;
  final Color warn;
  final Color love;

  const AppColors({
    required this.paper,
    required this.surface,
    required this.surface2,
    required this.tint,
    required this.ink,
    required this.inkSecondary,
    required this.inkTertiary,
    required this.hairline,
    required this.hairlineStrong,
    required this.accent,
    required this.up,
    required this.down,
    required this.warn,
    required this.love,
  });

  /// 涨跌语义色：正涨、负跌、零平。
  Color trend(double change) =>
      change > 0 ? up : (change < 0 ? down : inkSecondary);

  @override
  AppColors copyWith({
    Color? paper,
    Color? surface,
    Color? surface2,
    Color? tint,
    Color? ink,
    Color? inkSecondary,
    Color? inkTertiary,
    Color? hairline,
    Color? hairlineStrong,
    Color? accent,
    Color? up,
    Color? down,
    Color? warn,
    Color? love,
  }) {
    return AppColors(
      paper: paper ?? this.paper,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      tint: tint ?? this.tint,
      ink: ink ?? this.ink,
      inkSecondary: inkSecondary ?? this.inkSecondary,
      inkTertiary: inkTertiary ?? this.inkTertiary,
      hairline: hairline ?? this.hairline,
      hairlineStrong: hairlineStrong ?? this.hairlineStrong,
      accent: accent ?? this.accent,
      up: up ?? this.up,
      down: down ?? this.down,
      warn: warn ?? this.warn,
      love: love ?? this.love,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      paper: Color.lerp(paper, other.paper, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      tint: Color.lerp(tint, other.tint, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkSecondary: Color.lerp(inkSecondary, other.inkSecondary, t)!,
      inkTertiary: Color.lerp(inkTertiary, other.inkTertiary, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      hairlineStrong: Color.lerp(hairlineStrong, other.hairlineStrong, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      up: Color.lerp(up, other.up, t)!,
      down: Color.lerp(down, other.down, t)!,
      warn: Color.lerp(warn, other.warn, t)!,
      love: Color.lerp(love, other.love, t)!,
    );
  }
}

/// 便捷取色：`context.colors.accent`。
extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
