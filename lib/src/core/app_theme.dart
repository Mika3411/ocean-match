import 'package:flutter/material.dart';

class OceanColors {
  static const navy = Color(0xFF16273D);
  static const deep = Color(0xFF102A43);
  static const cream = Color(0xFFE8EEF5);
  static const copper = Color(0xFFC88048);

  static const abyss = Color(0xFF0A1B2C);
  static const obsidian = Color(0xFF081522);
  static const midnight = navy;
  static const deepBlue = deep;
  static const harborBlue = Color(0xFF1F3A56);
  static const seaTeal = Color(0xFF6EA6A6);
  static const coral = copper;
  static const blush = Color(0xFFD69A65);
  static const rose = Color(0xFFD7B18F);
  static const lavender = cream;
  static const gold = copper;
  static const champagne = cream;
  static const sand = cream;
  static const mist = Color(0xFF2A4058);
  static const ink = cream;
  static const muted = Color(0xFFA8B3C1);
  static const line = Color(0xFF314B66);
  static const glassLine = Color(0x66C88048);
  static const card = navy;
  static const cardAlt = deep;
  static const glass = Color(0xDE16273D);
  static const glassStrong = Color(0xF016273D);
}

class OceanTypography {
  static const uiFamily = 'Inter';
  static const uiFallback = ['Segoe UI', 'Arial'];
  static const brandFamily = 'Cormorant Garamond';
  static const brandFallback = [
    'Playfair Display',
    'Georgia',
    'Times New Roman',
  ];
  static const scriptFamily = brandFamily;
  static const scriptFallback = brandFallback;
  static const serifFamily = brandFamily;
  static const serifFallback = brandFallback;
  static const goldTitleShadows = <Shadow>[
    Shadow(
      color: Color(0xE6F8F2E8),
      offset: Offset(-1.0, -1.1),
      blurRadius: 1.2,
    ),
    Shadow(
      color: Color(0xFFD6A06E),
      offset: Offset(0.9, 0.9),
    ),
    Shadow(
      color: Color(0xFFC88048),
      offset: Offset(1.8, 2.0),
    ),
    Shadow(
      color: Color(0xFF7E4520),
      offset: Offset(2.8, 3.2),
    ),
    Shadow(
      color: Color(0xFF2B170B),
      offset: Offset(3.8, 4.4),
    ),
    Shadow(
      color: Color(0xAA140803),
      offset: Offset(0, 9),
      blurRadius: 16,
    ),
  ];
  static const goldGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFFFFF),
      OceanColors.cream,
      Color(0xFFE0B185),
      OceanColors.copper,
      Color(0xFFF3D2B1),
      Color(0xFFD0925E),
      Color(0xFF7A3E1B),
    ],
    stops: [0.0, 0.16, 0.32, 0.48, 0.62, 0.78, 1.0],
  );

  static Paint goldTitlePaint({double? fontSize}) {
    final size = fontSize ?? 42;
    final width = (size * 8.4).clamp(220.0, 980.0).toDouble();
    final height = (size * 1.55).clamp(42.0, 170.0).toDouble();
    return Paint()
      ..shader = goldGradient.createShader(
        Rect.fromLTWH(0, 0, width, height),
      );
  }

  static const editorial = TextStyle(
    fontFamily: scriptFamily,
    fontFamilyFallback: scriptFallback,
    color: OceanColors.gold,
    fontWeight: FontWeight.w600,
    height: 1.06,
    letterSpacing: 0,
    shadows: goldTitleShadows,
  );

  static TextStyle? brand(BuildContext context, {bool compact = false}) {
    final size = compact ? 28.0 : 34.0;
    return Theme.of(context).textTheme.titleLarge?.copyWith(
          fontFamily: scriptFamily,
          fontFamilyFallback: scriptFallback,
          color: OceanColors.gold,
          fontSize: size,
          fontWeight: FontWeight.w600,
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
          fontWeight: FontWeight.w600,
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
          fontWeight: FontWeight.w600,
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
          fontWeight: FontWeight.w500,
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
      fontFamily: OceanTypography.uiFamily,
      fontFamilyFallback: OceanTypography.uiFallback,
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
      fontFamily: OceanTypography.uiFamily,
      fontFamilyFallback: OceanTypography.uiFallback,
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
          fontWeight: FontWeight.w600,
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
          fontWeight: FontWeight.w600,
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
