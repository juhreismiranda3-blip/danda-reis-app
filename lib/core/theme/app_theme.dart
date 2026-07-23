import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta de cores aprovada com a cliente: branco, rosa claro, lilás,
/// cinza claro. Poucas cores, muito espaço em branco, visual feminino,
/// elegante e minimalista.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFFFCFAFB);
  static const Color surface = Color(0xFFFFFFFF);

  static const Color pinkLight = Color(0xFFF3E6F0);
  static const Color pinkAccent = Color(0xFFB98CAE);
  static const Color pinkText = Color(0xFF8C5A82);

  static const Color lilacLight = Color(0xFFF1EEF7);
  static const Color lilacText = Color(0xFF7A6FA0);

  static const Color textPrimary = Color(0xFF3E2E3A);
  static const Color textSecondary = Color(0xFF8A7F88);
  static const Color textMuted = Color(0xFFB3A8B0);

  static const Color border = Color(0xFFEEE2EC);

  // Status de pagamentos / aulas
  static const Color successBg = Color(0xFFE9F3EA);
  static const Color successText = Color(0xFF3B7A4A);
  static const Color warningBg = Color(0xFFFDF3D8);
  static const Color warningText = Color(0xFF8A6D1F);
  static const Color dangerBg = Color(0xFFFBE7E7);
  static const Color dangerText = Color(0xFFA34848);
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.pinkAccent,
        brightness: Brightness.light,
        surface: AppColors.surface,
      ),
    );

    final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
      titleLarge: GoogleFonts.poppins(
        fontSize: 19,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        color: AppColors.textPrimary,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 12,
        color: AppColors.textSecondary,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleMedium,
        iconTheme: const IconThemeData(color: AppColors.pinkText),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.pinkAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.pinkText,
          side: const BorderSide(color: AppColors.pinkAccent),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.pinkAccent, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
