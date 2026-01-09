import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Modern Forager Design System
/// Nature-inspired, energetic, professional
class AppTheme {
  // ============================================================================
  // COLOR PALETTE
  // ============================================================================

  /// Primary - Forest Green (trustworthy, natural)
  static const Color primary = Color(0xFF2D6A4F);
  static const Color primaryLight = Color(0xFF40916C);
  static const Color primaryDark = Color(0xFF1B4332);

  /// Secondary - Warm Amber (energetic, friendly)
  static const Color secondary = Color(0xFFF4A261);
  static const Color secondaryLight = Color(0xFFF6B17A);
  static const Color secondaryDark = Color(0xFFE76F51);

  /// Accent - Coral (fun, playful)
  static const Color accent = Color(0xFFE76F51);
  static const Color accentLight = Color(0xFFEF8A6F);
  static const Color accentDark = Color(0xFFD4583B);

  /// Success/Active
  static const Color success = Color(0xFF52B788);
  static const Color successLight = Color(0xFF74C69D);

  /// Warning
  static const Color warning = Color(0xFFF4A261);

  /// Error/Danger
  static const Color error = Color(0xFFE63946);

  /// Info
  static const Color info = Color(0xFF457B9D);

  /// XP/Points Color (Gold)
  static const Color xp = Color(0xFFFFB703);
  static const Color xpGradientStart = Color(0xFFFFB703);
  static const Color xpGradientEnd = Color(0xFFFB8500);

  /// Streak Color (Fire)
  static const Color streak = Color(0xFFFF6B35);

  // ============================================================================
  // BACKGROUNDS
  // ============================================================================

  /// Light Mode Backgrounds
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);

  /// Dark Mode Backgrounds
  static const Color backgroundDark = Color(0xFF1B263B);
  static const Color surfaceDark = Color(0xFF0D1B2A);
  static const Color cardDark = Color(0xFF1B263B);

  // ============================================================================
  // TEXT COLORS
  // ============================================================================

  static const Color textDark = Color(0xFF2B2D42);
  static const Color textMedium = Color(0xFF6B6D7D);
  static const Color textLight = Color(0xFF9B9DAD);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ============================================================================
  // GRADIENTS
  // ============================================================================

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryDark],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentDark],
  );

  static const LinearGradient xpGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [xpGradientStart, xpGradientEnd],
  );

  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x40FFFFFF),
      Color(0x10FFFFFF),
    ],
  );

  // ============================================================================
  // TYPOGRAPHY
  // ============================================================================

  /// Display text (large headings)
  static TextStyle display({
    double size = 32,
    FontWeight weight = FontWeight.bold,
    Color color = textDark,
  }) {
    return GoogleFonts.outfit(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.2,
      letterSpacing: -0.5,
    );
  }

  /// Heading text (section titles)
  static TextStyle heading({
    double size = 24,
    FontWeight weight = FontWeight.w600,
    Color color = textDark,
  }) {
    return GoogleFonts.outfit(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.3,
      letterSpacing: -0.3,
    );
  }

  /// Title text (card titles, list items)
  static TextStyle title({
    double size = 18,
    FontWeight weight = FontWeight.w600,
    Color color = textDark,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.4,
    );
  }

  /// Body text (paragraphs, descriptions)
  static TextStyle body({
    double size = 16,
    FontWeight weight = FontWeight.normal,
    Color color = textDark,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.5,
    );
  }

  /// Caption text (small labels, hints)
  static TextStyle caption({
    double size = 14,
    FontWeight weight = FontWeight.normal,
    Color color = textMedium,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.4,
    );
  }

  /// Button text
  static TextStyle button({
    double size = 16,
    FontWeight weight = FontWeight.w600,
    Color color = textWhite,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.2,
      letterSpacing: 0.5,
    );
  }

  /// Number/Stats text (points, levels, counts)
  static TextStyle stats({
    double size = 24,
    FontWeight weight = FontWeight.bold,
    Color color = primary,
  }) {
    return GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.2,
    );
  }

  // ============================================================================
  // SPACING
  // ============================================================================

  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space48 = 48.0;
  static const double space64 = 64.0;

  // ============================================================================
  // BORDER RADIUS
  // ============================================================================

  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  static const double radiusRound = 100.0;

  static BorderRadius borderRadiusSmall = BorderRadius.circular(radiusSmall);
  static BorderRadius borderRadiusMedium = BorderRadius.circular(radiusMedium);
  static BorderRadius borderRadiusLarge = BorderRadius.circular(radiusLarge);
  static BorderRadius borderRadiusXLarge = BorderRadius.circular(radiusXLarge);
  static BorderRadius borderRadiusRound = BorderRadius.circular(radiusRound);

  // ============================================================================
  // SHADOWS
  // ============================================================================

  static List<BoxShadow> shadowSoft = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> shadowHard = [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  // ============================================================================
  // ANIMATIONS
  // ============================================================================

  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  static const Curve animationCurve = Curves.easeInOutCubic;

  // ============================================================================
  // THEME DATA
  // ============================================================================

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    // Colors
    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: secondary,
      surface: surfaceLight,
      error: error,
      onPrimary: textWhite,
      onSecondary: textWhite,
      onSurface: textDark,
      onError: textWhite,
    ),

    scaffoldBackgroundColor: backgroundLight,

    // App Bar
    appBarTheme: AppBarTheme(
      backgroundColor: primary,
      foregroundColor: textWhite,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: heading(size: 20, color: textWhite),
    ),

    // Card
    cardTheme: CardThemeData(
      color: cardLight,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadiusLarge,
      ),
      shadowColor: Colors.black.withOpacity(0.1),
    ),

    // Elevated Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: textWhite,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadiusMedium,
        ),
        textStyle: button(),
      ),
    ),

    // Text Button
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadiusMedium,
        ),
        textStyle: button(color: primary),
      ),
    ),

    // Input
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceLight,
      border: OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: BorderSide(color: textLight.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: BorderSide(color: textLight.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: const BorderSide(color: error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: body(color: textMedium),
      hintStyle: body(color: textLight),
    ),

    // Bottom Navigation
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surfaceLight,
      selectedItemColor: primary,
      unselectedItemColor: textMedium,
      selectedLabelStyle: caption(weight: FontWeight.w600),
      unselectedLabelStyle: caption(),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    // Colors
    colorScheme: const ColorScheme.dark(
      primary: primaryLight,
      secondary: secondary,
      surface: surfaceDark,
      error: error,
      onPrimary: textWhite,
      onSecondary: textDark,
      onSurface: textWhite,
      onError: textWhite,
    ),

    scaffoldBackgroundColor: backgroundDark,

    // App Bar
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceDark,
      foregroundColor: textWhite,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: heading(size: 20, color: textWhite),
    ),

    // Card
    cardTheme: CardThemeData(
      color: cardDark,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadiusLarge,
      ),
      shadowColor: Colors.black.withOpacity(0.3),
    ),

    // Elevated Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryLight,
        foregroundColor: textWhite,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadiusMedium,
        ),
        textStyle: button(),
      ),
    ),

    // Text Button
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryLight,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadiusMedium,
        ),
        textStyle: button(color: primaryLight),
      ),
    ),

    // Input
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceDark,
      border: OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: BorderSide(color: textWhite.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: BorderSide(color: textWhite.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: const BorderSide(color: primaryLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: const BorderSide(color: error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: body(color: textWhite.withOpacity(0.7)),
      hintStyle: body(color: textWhite.withOpacity(0.5)),
    ),

    // Bottom Navigation
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surfaceDark,
      selectedItemColor: primaryLight,
      unselectedItemColor: textWhite.withOpacity(0.6),
      selectedLabelStyle: caption(weight: FontWeight.w600, color: textWhite),
      unselectedLabelStyle: caption(color: textWhite.withOpacity(0.6)),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );
}
