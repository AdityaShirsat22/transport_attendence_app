import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// FleetTrack application theme preserving the original dark/green/amber color scheme.
class AppTheme {
  AppTheme._();

  // Brand colors from original Tailwind config
  static const Color primary = Color(0xFFF59E0B); // amber-500
  static const Color primaryDark = Color(0xFFD97706); // amber-600
  static const Color primaryLight = Color(0xFFFBBF24); // amber-400

  static const Color success = Color(0xFF059669); // emerald-600
  static const Color successLight = Color(0xFF10B981); // emerald-500
  static const Color successBg = Color(0xFFECFDF5); // emerald-50

  static const Color danger = Color(0xFFE11D48); // rose-600
  static const Color dangerLight = Color(0xFFF43F5E); // rose-500
  static const Color dangerBg = Color(0xFFFFF1F2); // rose-50

  static const Color surface = Color(0xFFF4F4F5); // zinc-100
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE4E4E7); // zinc-200
  static const Color borderLight = Color(0xFFD4D4D8); // zinc-300

  static const Color textPrimary = Color(0xFF09090B); // zinc-950
  static const Color textSecondary = Color(0xFF3F3F46); // zinc-700
  static const Color textTertiary = Color(0xFF71717A); // zinc-500
  static const Color textMuted = Color(0xFFA1A1AA); // zinc-400

  static const Color dark = Color(0xFF09090B); // zinc-950
  static const Color darkSurface = Color(0xFF18181B); // zinc-900
  static const Color darkBorder = Color(0xFF27272A); // zinc-800

  static ThemeData get theme {
    final textTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      textTheme: textTheme,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        onPrimary: dark,
        secondary: success,
        onSecondary: Colors.white,
        error: danger,
        surface: surface,
        onSurface: textPrimary,
      ),
      scaffoldBackgroundColor: surface,
      appBarTheme: AppBarTheme(
        backgroundColor: dark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: dark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: borderLight),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: danger),
        ),
        labelStyle: textTheme.bodySmall?.copyWith(
          color: textTertiary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: textMuted),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: dark,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primary.withValues(alpha: 0.15),
        labelStyle: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: const BorderSide(color: border),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: dark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
