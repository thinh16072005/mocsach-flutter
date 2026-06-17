import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Hệ thiết kế tập trung: palette "Warm Library" (light) + "Reading Night" (dark),
/// typography Lora (tiêu đề serif) + Inter (nội dung sans).
class AppTheme {
  AppTheme._();

  /// Bo góc nhất quán toàn app.
  static const double radius = 14;
  static const Radius rad = Radius.circular(radius);
  static const BorderRadius borderRadius = BorderRadius.all(rad);

  // ---------- PALETTE ----------
  // Light — Warm Library
  static const Color _lBackground = Color(0xFFFAF7F2);
  static const Color _lSurface = Color(0xFFFFFFFF);
  static const Color _lSurfaceVariant = Color(0xFFF1EBE1);
  static const Color _lPrimary = Color(0xFF0F4C5C); // deep teal
  static const Color _lSecondary = Color(0xFF1B263B); // navy
  static const Color _lTertiary = Color(0xFFE0A458); // amber/gold CTA
  static const Color _lError = Color(0xFFB3261E);
  static const Color _lOutline = Color(0xFFD8CFC2);
  static const Color _lText = Color(0xFF1F2933);
  static const Color _lTextMuted = Color(0xFF6B7280);

  // Dark — Reading Night
  static const Color _dBackground = Color(0xFF121417);
  static const Color _dSurface = Color(0xFF1C2024);
  static const Color _dSurfaceVariant = Color(0xFF262B30);
  static const Color _dPrimary = Color(0xFF4FB3C7); // teal sáng cho contrast
  static const Color _dSecondary = Color(0xFF9FB3C8);
  static const Color _dTertiary = Color(0xFFE0A458);
  static const Color _dError = Color(0xFFF2B8B5);
  static const Color _dOutline = Color(0xFF3A4047);
  static const Color _dText = Color(0xFFECECEC);
  static const Color _dTextMuted = Color(0xFF9AA5B1);

  // Tiện ích truy cập màu gold ở chỗ cần (badge, CTA) bất kể theme.
  static const Color gold = Color(0xFFE0A458);

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: _lPrimary,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFCDE7EC),
    onPrimaryContainer: Color(0xFF06222B),
    secondary: _lSecondary,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFD7DEE9),
    onSecondaryContainer: Color(0xFF101826),
    tertiary: _lTertiary,
    onTertiary: _lText,
    tertiaryContainer: Color(0xFFF6E2C4),
    onTertiaryContainer: Color(0xFF4A3413),
    error: _lError,
    onError: Colors.white,
    surface: _lSurface,
    onSurface: _lText,
    surfaceContainerHighest: _lSurfaceVariant,
    onSurfaceVariant: _lTextMuted,
    outline: _lOutline,
    outlineVariant: Color(0xFFE7DFD3),
    shadow: Color(0x1A1B263B),
    surfaceTint: _lPrimary,
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: _dPrimary,
    onPrimary: Color(0xFF06222B),
    primaryContainer: Color(0xFF0F4C5C),
    onPrimaryContainer: Color(0xFFCDE7EC),
    secondary: _dSecondary,
    onSecondary: Color(0xFF0E1726),
    secondaryContainer: Color(0xFF2A3445),
    onSecondaryContainer: Color(0xFFD7DEE9),
    tertiary: _dTertiary,
    onTertiary: Color(0xFF1F2933),
    tertiaryContainer: Color(0xFF5A4220),
    onTertiaryContainer: Color(0xFFF6E2C4),
    error: _dError,
    onError: Color(0xFF601410),
    surface: _dSurface,
    onSurface: _dText,
    surfaceContainerHighest: _dSurfaceVariant,
    onSurfaceVariant: _dTextMuted,
    outline: _dOutline,
    outlineVariant: Color(0xFF2E343B),
    shadow: Color(0x66000000),
    surfaceTint: _dPrimary,
  );

  // ---------- TYPOGRAPHY ----------
  // Lora cho display/headline/title (cảm giác "sách"); Inter cho body/label.
  static TextTheme _textTheme(Color text, Color muted) {
    final lora = GoogleFonts.lora(color: text);
    final inter = GoogleFonts.inter(color: text);
    return TextTheme(
      displayLarge: lora.copyWith(fontSize: 34, fontWeight: FontWeight.w700, height: 1.15),
      displayMedium: lora.copyWith(fontSize: 28, fontWeight: FontWeight.w700, height: 1.18),
      displaySmall: lora.copyWith(fontSize: 24, fontWeight: FontWeight.w600),
      headlineMedium: lora.copyWith(fontSize: 22, fontWeight: FontWeight.w600),
      headlineSmall: lora.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
      titleLarge: lora.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
      titleMedium: inter.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      titleSmall: inter.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      bodyLarge: inter.copyWith(fontSize: 16, height: 1.45),
      bodyMedium: inter.copyWith(fontSize: 14, height: 1.45),
      bodySmall: inter.copyWith(fontSize: 12, color: muted, height: 1.4),
      labelLarge: inter.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      labelMedium: inter.copyWith(fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: inter.copyWith(fontSize: 11, fontWeight: FontWeight.w500, color: muted),
    );
  }

  // ---------- THEMES ----------
  static ThemeData get light => _build(_lightScheme, _lBackground, _lText, _lTextMuted);
  static ThemeData get dark => _build(_darkScheme, _dBackground, _dText, _dTextMuted);

  static ThemeData _build(ColorScheme scheme, Color scaffoldBg, Color text, Color muted) {
    final textTheme = _textTheme(text, muted);
    final isLight = scheme.brightness == Brightness.light;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBg,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,

      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),

      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(color: scheme.outline.withValues(alpha: isLight ? 0.5 : 0.4)),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // CTA chính: nền gold, chữ đậm tối — nổi bật trên nền kem.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.tertiary,
          foregroundColor: scheme.onTertiary,
          disabledBackgroundColor: scheme.tertiary.withValues(alpha: 0.4),
          disabledForegroundColor: scheme.onTertiary.withValues(alpha: 0.6),
          elevation: 0,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: textTheme.labelLarge,
          shape: const RoundedRectangleBorder(borderRadius: borderRadius),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(0, 48),
          side: BorderSide(color: scheme.outline),
          textStyle: textTheme.labelLarge,
          shape: const RoundedRectangleBorder(borderRadius: borderRadius),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: textTheme.labelLarge,
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: scheme.primary,
        secondarySelectedColor: scheme.primary,
        labelStyle: textTheme.labelMedium,
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(color: scheme.onPrimary),
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.6)),
        shape: const StadiumBorder(),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        labelStyle: TextStyle(color: muted),
        hintStyle: TextStyle(color: muted),
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outline.withValues(alpha: 0.5),
        thickness: 1,
        space: 24,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.secondary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: scheme.onSecondary),
        shape: const RoundedRectangleBorder(borderRadius: borderRadius),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: scheme.primary,
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: textTheme.bodySmall,
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
