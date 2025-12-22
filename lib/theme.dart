import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// BitNet Design System Theme
/// Contains all design constants, colors, spacing, and typography
/// This is a static theme class that provides design system constants
abstract class AppTheme {
  // Satoshi Icon (for Bitcoin symbol)
  static IconData satoshiIcon = const IconData(
    0x0021,
    fontFamily: 'SatoshiSymbol',
  );

  // API URLs (essential only)
  static String baseUrlMemPoolSpaceApi = 'https://mempool.space/api/';

  // App Constants
  static const String appId = 'com.ark.arkflutter';
  static const String applicationName = 'Ark Flutter';
  static dynamic targetConf = 4;

  // Primary Colors
  static const Color immutableColorSchemeSeed = Color(0xffffffff);
  static Color? colorSchemeSeed = const Color(0xffffffff);
  static const Color primaryColor = Color(0xffffffff);
  static const Color colorBackground = Color(0xff130036);

  static const Color primaryColorLight = Color(0xFFCCBDEA);
  static const Color secondaryColor = Color(0xFF41a2bc);

  // Glass Morphism Colors
  static Color glassMorphColor = Colors.black.withOpacity(0.2);
  static Color glassMorphColorLight = Colors.white.withOpacity(0.2);
  static Color glassMorphColorDark = Colors.black.withOpacity(0.3);

  // Accent Colors
  static const Color colorLink = Colors.blueAccent;
  static const Color colorBitcoin = Color(0xfff7931a);
  static const Color colorPrimaryGradient = Color(0xfff25d00);

  // Status Colors
  static const Color errorColor = Color(0xFFFF6363);
  static const Color errorColorGradient = Color(0xFFC54545);
  static const Color successColor = Color(0xFF5DE165);
  static const Color successColorGradient = Color(0xFF148C1A);

  // Border Radius
  static BorderRadius cardRadiusSuperSmall = BorderRadius.circular(10);
  static BorderRadius cardRadiusSmall = BorderRadius.circular(16);
  static BorderRadius cardRadiusMid = BorderRadius.circular(24);
  static BorderRadius cardRadiusBig = BorderRadius.circular(28);
  static BorderRadius cardRadiusBigger = BorderRadius.circular(32);
  static BorderRadius cardRadiusBiggest = BorderRadius.circular(36);
  static Radius cornerRadiusBig = const Radius.circular(28);
  static Radius cornerRadiusMid = const Radius.circular(24);
  static BorderRadius cardRadiusCircular = BorderRadius.circular(500);

  static const double borderRadiusSuperSmall = 10.0;
  static const double borderRadiusSmall = 16.0;
  static const double borderRadiusMid = 24.0;
  static const double borderRadiusBig = 28.0;
  static const double borderRadiusBigger = 32.0;
  static const double borderRadiusCircular = 500.0;

  static const double tabbarBorderWidth = 1.5;

  // Spacing Constants
  static const double navRailWidth = 2 * cardPadding + elementSpacing;
  static const double cardPadding = 24;
  static const double columnWidth = 14 * cardPadding;
  static const double cardPaddingSmall = 16;
  static const double cardPaddingBig = 28;
  static const double cardPaddingBigger = 32;
  static const double elementSpacing = cardPadding * 0.5;
  static const double bottomNavBarHeight = 64;

  // Padding Constants (aliases for convenience)
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
  static const double paddingXXL = 48.0;

  // Border Radius Constants (aliases)
  static const double radiusXS = 4.0;
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 20.0;

  // Button Heights
  static const double buttonHeightS = 44.0;

  // Icon Sizes
  static const double iconS = 16.0;
  static const double iconM = 20.0;
  static const double iconL = 24.0;
  static const double iconXL = 40.0;

  // Sizes
  static const double iconSize = cardPadding;
  static const double buttonHeight = 50;
  static Size size(BuildContext context) => MediaQuery.of(context).size;

  // Responsiveness
  static bool isColumnModeByWidth(double width) =>
      width > columnWidth * 2 + navRailWidth;

  static bool isColumnMode(BuildContext context) =>
      isColumnModeByWidth(MediaQuery.of(context).size.width);

  // Breakpoints
  static const double isSuperSmallScreen = 600;
  static const double isSmallScreen = 1000;
  static const double isIntermediateScreen = 1350;
  static const double isSmallIntermediateScreen = 1100;
  static const double isMidScreen = 1600;

  // Box Shadows
  static BoxShadow boxShadow = BoxShadow(
    color: Colors.black.withOpacity(0.25),
    offset: const Offset(0, 2),
    blurRadius: 5,
  );
  static BoxShadow boxShadowSuperSmall = BoxShadow(
    color: Colors.black.withOpacity(0.05),
    offset: const Offset(0, 4),
    blurRadius: 15,
    spreadRadius: 0.5,
  );
  static BoxShadow boxShadowSmall = BoxShadow(
    color: Colors.black.withOpacity(0.1),
    offset: const Offset(0, 10),
    blurRadius: 80,
    spreadRadius: 1.5,
  );
  static BoxShadow boxShadowBig = BoxShadow(
    color: Colors.black.withOpacity(0.1),
    offset: const Offset(0, 2.5),
    blurRadius: 40.0,
  );
  static BoxShadow boxShadowButton = BoxShadow(
    color: Colors.black.withOpacity(0.6),
    offset: const Offset(0, 2.5),
    blurRadius: 40.0,
  );
  static BoxShadow boxShadowProfile = BoxShadow(
    color: Colors.black.withOpacity(0.1),
    offset: const Offset(0, 2.5),
    blurRadius: 10,
  );

  // Animation
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Curve animationCurve = Curves.easeInOut;

  // Text Colors with Opacity
  static const Color black100 = Color(0xFF000000);
  static Color black90 = const Color(0xFF000000).withOpacity(0.9);
  static Color black80 = const Color(0xFF000000).withOpacity(0.8);
  static Color black70 = const Color(0xFF000000).withOpacity(0.7);
  static Color black60 = const Color(0xFF000000).withOpacity(0.6);

  static const Color white100 = Color(0xFFFFFFFF);
  static Color white90 = const Color(0xFFFFFFFF).withOpacity(0.9);
  static Color white80 = const Color(0xFFFFFFFF).withOpacity(0.8);
  static Color white70 = const Color(0xFFFFFFFF).withOpacity(0.7);
  static Color white60 = const Color(0xFFFFFFFF).withOpacity(0.6);

  static Color colorGlassContainer = const Color(0xFFFFFFFF).withOpacity(0.15);

  // Input Decoration
  static InputDecoration textfieldDecoration(
    String hintText,
    BuildContext context,
  ) =>
      InputDecoration(
        hintText: hintText,
        contentPadding: const EdgeInsets.all(0.25),
        border: InputBorder.none,
        hintStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
              color: Theme.of(context)
                  .textTheme
                  .bodyLarge!
                  .color!
                  .withOpacity(0.4),
            ),
      );

  // Text Theme (Light Mode)
  static final textTheme = TextTheme(
    displayLarge: GoogleFonts.poppins(
      fontSize: 52,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: AppTheme.black90,
    ),
    displayMedium: GoogleFonts.poppins(
      fontSize: 40,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: AppTheme.black90,
    ),
    displaySmall: GoogleFonts.poppins(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.0,
      color: AppTheme.black90,
    ),
    headlineLarge: GoogleFonts.poppins(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.25,
      color: AppTheme.black80,
    ),
    headlineMedium: GoogleFonts.poppins(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.25,
      color: AppTheme.black80,
    ),
    headlineSmall: GoogleFonts.poppins(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.15,
      color: AppTheme.black80,
    ),
    titleLarge: GoogleFonts.poppins(
      fontSize: 17,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.15,
      color: AppTheme.black70,
    ),
    titleMedium: GoogleFonts.poppins(
      fontSize: 17,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.0,
      color: AppTheme.black70,
    ),
    titleSmall: GoogleFonts.poppins(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.0,
      color: AppTheme.black70,
    ),
    bodyLarge: GoogleFonts.poppins(
      fontSize: 17,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
      color: AppTheme.black60,
    ),
    bodyMedium: GoogleFonts.poppins(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
      color: AppTheme.black60,
    ),
    bodySmall: GoogleFonts.poppins(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      color: AppTheme.black60,
    ),
    labelLarge: GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      color: AppTheme.black60,
    ),
    labelMedium: GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      color: AppTheme.black60,
    ),
    labelSmall: GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      color: AppTheme.black60,
    ),
  );

  // Text Theme (Dark Mode)
  static final textThemeDarkMode = textTheme.copyWith(
    displayLarge: textTheme.displayLarge!.copyWith(color: AppTheme.white90),
    displayMedium: textTheme.displayMedium!.copyWith(color: AppTheme.white90),
    displaySmall: textTheme.displaySmall!.copyWith(color: AppTheme.white90),
    headlineLarge: textTheme.headlineMedium!.copyWith(color: AppTheme.white90),
    headlineMedium: textTheme.headlineMedium!.copyWith(color: AppTheme.white90),
    headlineSmall: textTheme.headlineSmall!.copyWith(color: AppTheme.white90),
    titleLarge: textTheme.titleLarge!.copyWith(color: AppTheme.white90),
    titleMedium: textTheme.titleMedium!.copyWith(color: AppTheme.white80),
    titleSmall: textTheme.titleSmall!.copyWith(color: AppTheme.white80),
    bodyLarge: textTheme.bodyLarge!.copyWith(color: AppTheme.white70),
    bodyMedium: textTheme.bodyMedium!.copyWith(color: AppTheme.white70),
    bodySmall: textTheme.bodySmall!.copyWith(color: AppTheme.white60),
    labelSmall: textTheme.labelSmall!.copyWith(color: AppTheme.white60),
    labelMedium: textTheme.labelMedium!.copyWith(color: AppTheme.white60),
    labelLarge: textTheme.labelLarge!.copyWith(color: AppTheme.white60),
  );

  // Fallback Text Style
  static const fallbackTextStyle = TextStyle(
    fontFamily: 'Poppins',
    fontFamilyFallback: ['NotoEmoji'],
  );

  static var fallbackTextTheme = const TextTheme(
    bodyLarge: fallbackTextStyle,
    bodyMedium: fallbackTextStyle,
    labelLarge: fallbackTextStyle,
    bodySmall: fallbackTextStyle,
    labelSmall: fallbackTextStyle,
    displayLarge: fallbackTextStyle,
    displayMedium: fallbackTextStyle,
    displaySmall: fallbackTextStyle,
    headlineMedium: fallbackTextStyle,
    headlineSmall: fallbackTextStyle,
    titleLarge: fallbackTextStyle,
    titleMedium: fallbackTextStyle,
    titleSmall: fallbackTextStyle,
  );

  /// Creates a custom ThemeData based on brightness and optional seed color
  static ThemeData customTheme(Brightness brightness, [Color? seed]) {
    Color defaultSeed = seed ?? AppTheme.primaryColor;

    if (defaultSeed == const Color(0xffffffff) ||
        defaultSeed == const Color(0xff000000)) {
      if (brightness == Brightness.dark) {
        ColorScheme colorScheme = ColorScheme(
          onPrimaryContainer: Colors.white,
          primary: AppTheme.colorBitcoin,
          secondary: AppTheme.secondaryColor,
          secondaryContainer: Colors.black,
          primaryContainer: Colors.black,
          tertiary: Colors.black,
          tertiaryContainer: Colors.black,
          brightness: Brightness.dark,
          onPrimary: AppTheme.white80,
          onSecondary: Colors.black,
          error: AppTheme.errorColor,
          onError: AppTheme.errorColor,
          surface: Colors.black,
          onSurface: Colors.white,
        );
        ThemeData themeData = ThemeData.from(
          colorScheme: colorScheme,
          textTheme: fallbackTextTheme.merge(textThemeDarkMode),
        );
        return themeData;
      } else {
        // Light mode
        ColorScheme colorScheme = const ColorScheme(
          brightness: Brightness.light,
          onPrimaryContainer: Colors.black,
          onPrimary: Colors.black,
          onSecondaryContainer: Colors.black,
          onSecondary: Colors.black,
          primary: AppTheme.colorBitcoin,
          onSurface: Colors.black,
          secondary: AppTheme.secondaryColor,
          secondaryContainer: Color(0xfff2f2f2),
          primaryContainer: Color(0xfff2f2f2),
          tertiary: Color(0xfff2f2f2),
          tertiaryContainer: Color(0xfff2f2f2),
          error: AppTheme.errorColor,
          onError: AppTheme.errorColor,
          surface: Color(0xfff2f2f2),
        );
        ThemeData themeData = ThemeData.from(
          colorScheme: colorScheme,
          textTheme: fallbackTextTheme.merge(textTheme),
        );
        return themeData;
      }
    } else {
      ColorScheme colorScheme = ColorScheme.fromSeed(
        seedColor: defaultSeed,
        brightness: brightness,
      );
      ThemeData themeData = ThemeData.from(
        colorScheme: colorScheme,
        textTheme: brightness == Brightness.light
            ? fallbackTextTheme.merge(textTheme)
            : fallbackTextTheme.merge(textThemeDarkMode),
      );
      return themeData;
    }
  }
}

extension on Brightness {
  Brightness get reversed =>
      this == Brightness.dark ? Brightness.light : Brightness.dark;
}

/// Darken a color by [percent] amount (100 = black)
Color darken(Color c, [int percent = 10]) {
  assert(1 <= percent && percent <= 100);
  var f = 1 - percent / 100;
  return Color.fromARGB(
    c.alpha,
    (c.red * f).round(),
    (c.green * f).round(),
    (c.blue * f).round(),
  );
}

/// Lighten a color by [percent] amount (100 = white)
Color lighten(Color c, [int percent = 10]) {
  assert(1 <= percent && percent <= 100);
  var p = percent / 100;
  return Color.fromARGB(
    c.alpha,
    c.red + ((255 - c.red) * p).round(),
    c.green + ((255 - c.green) * p).round(),
    c.blue + ((255 - c.blue) * p).round(),
  );
}

/// Calculate QR code size based on context
dynamic qrCodeSize(BuildContext context) =>
    min(AppTheme.cardPadding * 9.5, AppTheme.cardPadding * 9.5).toDouble();
