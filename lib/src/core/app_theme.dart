import 'package:flutter/material.dart';

class OceanColors {
  static const deepBlue = Color(0xFF062B3F);
  static const harborBlue = Color(0xFF0D5C75);
  static const seaTeal = Color(0xFF168B8F);
  static const coral = Color(0xFFFF6B5F);
  static const sand = Color(0xFFF6F2EA);
  static const mist = Color(0xFFE7EEF0);
  static const ink = Color(0xFF10242F);
  static const muted = Color(0xFF667985);
}

class OceanTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: OceanColors.harborBlue,
      primary: OceanColors.harborBlue,
      secondary: OceanColors.seaTeal,
      tertiary: OceanColors.coral,
      surface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: OceanColors.sand,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: OceanColors.sand,
        foregroundColor: OceanColors.ink,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: OceanColors.mist),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: OceanColors.mist),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: OceanColors.harborBlue, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: OceanColors.harborBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: OceanColors.harborBlue,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: OceanColors.harborBlue),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: OceanColors.mist,
        selectedColor: OceanColors.seaTeal.withValues(alpha: 0.16),
        checkmarkColor: OceanColors.seaTeal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
