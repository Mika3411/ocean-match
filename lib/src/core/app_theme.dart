import 'package:flutter/material.dart';

class OceanColors {
  static const abyss = Color(0xFF07111B);
  static const obsidian = Color(0xFF0A1018);
  static const midnight = Color(0xFF0B141E);
  static const deepBlue = Color(0xFF101D2A);
  static const harborBlue = Color(0xFF1B2B3D);
  static const seaTeal = Color(0xFF7BC7B3);
  static const coral = Color(0xFFFF7668);
  static const blush = Color(0xFFFFB7A8);
  static const rose = Color(0xFFEFA6B6);
  static const lavender = Color(0xFFD8C9FF);
  static const gold = Color(0xFFE7C75F);
  static const champagne = Color(0xFFFFDFA8);
  static const copper = Color(0xFFC98A5D);
  static const sand = Color(0xFFF4EDDE);
  static const mist = Color(0xFF293747);
  static const ink = Color(0xFFF7F1E6);
  static const muted = Color(0xFF9AA7B5);
  static const line = Color(0xFF35465A);
  static const glassLine = Color(0x55FFDFA8);
  static const card = Color(0xFF182637);
  static const cardAlt = Color(0xFF213247);
  static const glass = Color(0xDE101D2A);
  static const glassStrong = Color(0xF0182637);
}

class OceanTypography {
  static const scriptFamily = 'Parisienne';
  static const scriptFallback = [
    'Segoe Script',
    'Brush Script MT',
    'Lucida Handwriting',
    'Georgia',
  ];
  static const serifFamily = 'Georgia';
  static const serifFallback = ['Times New Roman'];
  static const goldTitleShadows = <Shadow>[
    Shadow(
      color: Color(0xFF7D4B1D),
      offset: Offset(1.1, 1.2),
    ),
    Shadow(
      color: Color(0xFF33200F),
      offset: Offset(2.2, 2.8),
    ),
    Shadow(
      color: Color(0x99FFF2C0),
      offset: Offset(-0.7, -0.8),
      blurRadius: 1.2,
    ),
    Shadow(
      color: Color(0x77220F08),
      offset: Offset(0, 7),
      blurRadius: 12,
    ),
  ];

  static const editorial = TextStyle(
    fontFamily: scriptFamily,
    fontFamilyFallback: scriptFallback,
    color: OceanColors.gold,
    fontWeight: FontWeight.w400,
    height: 1.06,
    letterSpacing: 0,
    shadows: goldTitleShadows,
  );

  static TextStyle? brand(BuildContext context, {bool compact = false}) {
    return Theme.of(context).textTheme.titleLarge?.copyWith(
          fontFamily: scriptFamily,
          fontFamilyFallback: scriptFallback,
          color: OceanColors.gold,
          fontSize: compact ? 28 : 34,
          fontWeight: FontWeight.w400,
          height: 1,
          letterSpacing: 0,
          shadows: goldTitleShadows,
        );
  }

  static TextStyle? display(
    BuildContext context, {
    Color color = OceanColors.gold,
    double? fontSize,
    FontStyle fontStyle = FontStyle.normal,
  }) {
    return Theme.of(context).textTheme.displaySmall?.copyWith(
          fontFamily: scriptFamily,
          fontFamilyFallback: scriptFallback,
          color: color,
          fontSize: fontSize,
          fontStyle: fontStyle,
          fontWeight: FontWeight.w400,
          height: 1.04,
          letterSpacing: 0,
          shadows: goldTitleShadows,
        );
  }

  static TextStyle? title(
    BuildContext context, {
    double? fontSize,
    Color color = OceanColors.gold,
    double height = 1.10,
  }) {
    return Theme.of(context).textTheme.titleLarge?.copyWith(
          fontFamily: scriptFamily,
          fontFamilyFallback: scriptFallback,
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w400,
          height: height,
          letterSpacing: 0,
          shadows: goldTitleShadows,
        );
  }

  static TextStyle? name(
    BuildContext context, {
    double? fontSize,
    Color color = OceanColors.gold,
  }) {
    return display(context, color: color, fontSize: fontSize)?.copyWith(
      fontStyle: FontStyle.italic,
    );
  }

  static TextStyle? age(
    BuildContext context, {
    double? fontSize,
  }) {
    return Theme.of(context).textTheme.bodyLarge?.copyWith(
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
    return title(context, fontSize: 24, height: 1.08);
  }
}

class OceanTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: OceanColors.champagne,
      brightness: Brightness.dark,
      primary: OceanColors.coral,
      secondary: OceanColors.seaTeal,
      tertiary: OceanColors.champagne,
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
      titleLarge: baseTextTheme.titleLarge?.merge(OceanTypography.editorial),
      titleMedium: baseTextTheme.titleMedium?.copyWith(letterSpacing: 0),
      labelLarge: baseTextTheme.labelLarge?.copyWith(letterSpacing: 0),
      labelMedium: baseTextTheme.labelMedium?.copyWith(letterSpacing: 0),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: OceanColors.abyss,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: OceanColors.abyss,
        foregroundColor: OceanColors.sand,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: OceanTypography.scriptFamily,
          fontFamilyFallback: OceanTypography.scriptFallback,
          color: OceanColors.gold,
          fontSize: 30,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          shadows: OceanTypography.goldTitleShadows,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: OceanColors.glass,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: OceanColors.glassLine),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: OceanColors.obsidian,
        labelStyle: const TextStyle(color: OceanColors.muted),
        hintStyle: const TextStyle(color: OceanColors.muted),
        prefixIconColor: OceanColors.champagne,
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
          borderSide:
              const BorderSide(color: OceanColors.champagne, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: OceanColors.coral,
          foregroundColor: OceanColors.midnight,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: OceanColors.champagne,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: OceanColors.glassLine),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: OceanColors.champagne),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: OceanColors.cardAlt,
        labelStyle: const TextStyle(color: OceanColors.ink),
        selectedColor: OceanColors.seaTeal.withValues(alpha: 0.20),
        checkmarkColor: OceanColors.seaTeal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: OceanColors.obsidian,
        indicatorColor: OceanColors.coral.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? OceanColors.coral
                : OceanColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? OceanColors.coral
                : OceanColors.muted,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: OceanColors.glassStrong,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          fontFamily: OceanTypography.scriptFamily,
          fontFamilyFallback: OceanTypography.scriptFallback,
          color: OceanColors.gold,
          fontSize: 30,
          fontWeight: FontWeight.w400,
          height: 1.08,
          letterSpacing: 0,
          shadows: OceanTypography.goldTitleShadows,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: OceanColors.glassStrong,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: OceanColors.champagne,
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
