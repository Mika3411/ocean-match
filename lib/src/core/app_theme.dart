import 'package:flutter/material.dart';

class OceanColors {
  static const midnight = Color(0xFF0B141E);
  static const deepBlue = Color(0xFF101D2A);
  static const harborBlue = Color(0xFF1B2B3D);
  static const seaTeal = Color(0xFF7BC7B3);
  static const coral = Color(0xFFFF7668);
  static const gold = Color(0xFFE7C75F);
  static const sand = Color(0xFFF4EDDE);
  static const mist = Color(0xFF293747);
  static const ink = Color(0xFFF7F1E6);
  static const muted = Color(0xFF9AA7B5);
  static const line = Color(0xFF35465A);
  static const card = Color(0xFF182637);
  static const cardAlt = Color(0xFF213247);
}

class OceanTypography {
  static const serifFamily = 'Georgia';
  static const serifFallback = ['Times New Roman'];

  static const editorial = TextStyle(
    fontFamily: serifFamily,
    fontFamilyFallback: serifFallback,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  static TextStyle? brand(BuildContext context, {bool compact = false}) {
    return Theme.of(context).textTheme.titleLarge?.copyWith(
          fontFamily: serifFamily,
          fontFamilyFallback: serifFallback,
          color: OceanColors.sand,
          fontSize: compact ? 21 : 25,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        );
  }

  static TextStyle? display(
    BuildContext context, {
    Color color = OceanColors.sand,
    double? fontSize,
    FontStyle fontStyle = FontStyle.normal,
  }) {
    return Theme.of(context).textTheme.displaySmall?.copyWith(
          fontFamily: serifFamily,
          fontFamilyFallback: serifFallback,
          color: color,
          fontSize: fontSize,
          fontStyle: fontStyle,
          fontWeight: FontWeight.w400,
          height: 0.94,
          letterSpacing: 0,
        );
  }

  static TextStyle? name(
    BuildContext context, {
    double? fontSize,
    Color color = OceanColors.sand,
  }) {
    return display(context, color: color, fontSize: fontSize)?.copyWith(
      fontStyle: FontStyle.italic,
    );
  }

  static TextStyle? age(
    BuildContext context, {
    double? fontSize,
  }) {
    return Theme.of(context).textTheme.titleLarge?.copyWith(
          fontFamily: serifFamily,
          fontFamilyFallback: serifFallback,
          color: OceanColors.muted,
          fontSize: fontSize,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
        );
  }

  static TextStyle? sectionLabel(BuildContext context) {
    return Theme.of(context).textTheme.labelLarge?.copyWith(
          color: OceanColors.gold,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        );
  }
}

class OceanTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: OceanColors.seaTeal,
      brightness: Brightness.dark,
      primary: OceanColors.gold,
      secondary: OceanColors.seaTeal,
      tertiary: OceanColors.coral,
      surface: OceanColors.card,
      error: OceanColors.coral,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
    );
    final baseTextTheme = base.textTheme.apply(
      bodyColor: OceanColors.ink,
      displayColor: OceanColors.sand,
    );
    final textTheme = baseTextTheme.copyWith(
      displayLarge:
          baseTextTheme.displayLarge?.merge(OceanTypography.editorial),
      displayMedium:
          baseTextTheme.displayMedium?.merge(OceanTypography.editorial),
      displaySmall:
          baseTextTheme.displaySmall?.merge(OceanTypography.editorial),
      headlineSmall:
          baseTextTheme.headlineSmall?.merge(OceanTypography.editorial),
      titleLarge: baseTextTheme.titleLarge?.copyWith(letterSpacing: 0),
      titleMedium: baseTextTheme.titleMedium?.copyWith(letterSpacing: 0),
      labelLarge: baseTextTheme.labelLarge?.copyWith(letterSpacing: 0),
      labelMedium: baseTextTheme.labelMedium?.copyWith(letterSpacing: 0),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: OceanColors.midnight,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: OceanColors.midnight,
        foregroundColor: OceanColors.sand,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: OceanColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: OceanColors.line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: OceanColors.deepBlue,
        labelStyle: const TextStyle(color: OceanColors.muted),
        hintStyle: const TextStyle(color: OceanColors.muted),
        prefixIconColor: OceanColors.gold,
        suffixIconColor: OceanColors.muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: OceanColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: OceanColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: OceanColors.gold, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: OceanColors.gold,
          foregroundColor: OceanColors.midnight,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: OceanColors.gold,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: OceanColors.line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: OceanColors.gold),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: OceanColors.mist,
        labelStyle: const TextStyle(color: OceanColors.ink),
        selectedColor: OceanColors.seaTeal.withValues(alpha: 0.20),
        checkmarkColor: OceanColors.seaTeal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: OceanColors.deepBlue,
        indicatorColor: OceanColors.gold.withValues(alpha: 0.16),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? OceanColors.gold
                : OceanColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? OceanColors.gold
                : OceanColors.muted,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: OceanColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: OceanColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: OceanColors.gold,
        linearTrackColor: OceanColors.mist,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: OceanColors.cardAlt,
        contentTextStyle: textTheme.bodyMedium,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
