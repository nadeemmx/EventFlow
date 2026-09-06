import 'package:flutter/material.dart';

class DesignSystem {
  DesignSystem._();

  // ─── Spacing (8pt grid) ───────────────────────────────────────────
  static const double spacing0 = 0;
  static const double spacing1 = 4;
  static const double spacing2 = 8;
  static const double spacing3 = 12;
  static const double spacing4 = 16;
  static const double spacing5 = 20;
  static const double spacing6 = 24;
  static const double spacing7 = 28;
  static const double spacing8 = 32;
  static const double spacing10 = 40;
  static const double spacing12 = 48;
  static const double spacing16 = 64;

  // ─── Shape Radius ─────────────────────────────────────────────────
  static const double radiusNone = 0;
  static const double radiusXs = 4;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusXxl = 24;
  static const double radiusFull = 999;

  // Squircle shapes
  static const ContinuousRectangleBorder squircleSm =
      ContinuousRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(radiusSm)));
  static const ContinuousRectangleBorder squircleMd =
      ContinuousRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(radiusMd)));
  static const ContinuousRectangleBorder squircleLg =
      ContinuousRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(radiusLg)));
  static const ContinuousRectangleBorder squircleXl =
      ContinuousRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(radiusXl)));

  // ─── Elevation ────────────────────────────────────────────────────
  static const double elevationNone = 0;
  static const double elevationXs = 1;
  static const double elevationSm = 2;
  static const double elevationMd = 4;
  static const double elevationLg = 8;
  static const double elevationXl = 16;

  // ─── Motion ───────────────────────────────────────────────────────
  static const Duration durationFast = Duration(milliseconds: 100);
  static const Duration durationNormal = Duration(milliseconds: 200);
  static const Duration durationSlow = Duration(milliseconds: 300);
  static const Duration durationVerySlow = Duration(milliseconds: 500);
  static const Duration durationExtraSlow = Duration(milliseconds: 700);

  // M3 easing curves
  static const Curve easeStandard = Curves.easeInOut;
  static const Curve easeDecelerate = Curves.easeOut;
  static const Curve easeAccelerate = Curves.easeIn;
  static const Curve easeEmphasized = Curves.easeInOutCubicEmphasized;
  static const Curve easeEmphasizedDecelerate = Curves.easeOutCubic;
  static const Curve easeEmphasizedAccelerate = Curves.easeInCubic;

  // ─── Typography (M3 Type Scale with Inter) ────────────────────────
  // Display
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    height: 1.12,
  );
  static const TextStyle displayMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 45,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.16,
  );
  static const TextStyle displaySmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 36,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.22,
  );

  // Headline
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 32,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.25,
  );
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 28,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.29,
  );
  static const TextStyle headlineSmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 24,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.33,
  );

  // Title
  static const TextStyle titleLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 22,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.27,
  );
  static const TextStyle titleMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    height: 1.5,
  );
  static const TextStyle titleSmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );

  // Body
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.5,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
  );
  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );

  // Label
  static const TextStyle labelLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );
  static const TextStyle labelMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.33,
  );
  static const TextStyle labelSmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.45,
  );

  // ─── Light Color Scheme (Warm Gold / Cream) ────────────────────────
  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,
    // Primary - EventFlow Gold
    primary: Color(0xFFD4A843),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFFDF6E3),
    onPrimaryContainer: Color(0xFF5C4A12),
    // Secondary - Warm Rose
    secondary: Color(0xFFC48B6A),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFFCEEE6),
    onSecondaryContainer: Color(0xFF4A2510),
    // Tertiary - Sage Green
    tertiary: Color(0xFF7A9E7E),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFE8F5E9),
    onTertiaryContainer: Color(0xFF1B4332),
    // Error
    error: Color(0xFFC0392B),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFDECEA),
    onErrorContainer: Color(0xFF7B1A1A),
    // Surface - Warm Cream
    surface: Color(0xFFFFFBF5),
    onSurface: Color(0xFF1A1A1A),
    surfaceContainerHighest: Color(0xFFF0EBE3),
    surfaceContainerHigh: Color(0xFFF5F0E8),
    surfaceContainer: Color(0xFFFAF5ED),
    surfaceContainerLow: Color(0xFFFEFAF2),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceDim: Color(0xFFE8E3DB),
    onSurfaceVariant: Color(0xFF6B6560),
    // Outline
    outline: Color(0xFFB8B0A8),
    outlineVariant: Color(0xFFDDD8D0),
    // Inverse
    inverseSurface: Color(0xFF2C2620),
    onInverseSurface: Color(0xFFF5F0E8),
    inversePrimary: Color(0xFFE8C96A),
    // Shadow & Scrim
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );

  // ─── Dark Color Scheme (Premium Dark Gold) ─────────────────────────
  static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,
    // Primary - Warm Gold (lighter for dark)
    primary: Color(0xFFE8C96A),
    onPrimary: Color(0xFF3D3210),
    primaryContainer: Color(0xFF5C4A12),
    onPrimaryContainer: Color(0xFFFDF6E3),
    // Secondary - Warm Rose
    secondary: Color(0xFFF0B89A),
    onSecondary: Color(0xFF4A2510),
    secondaryContainer: Color(0xFF6B3D24),
    onSecondaryContainer: Color(0xFFFCEEE6),
    // Tertiary - Sage Green
    tertiary: Color(0xFFA8D5AB),
    onTertiary: Color(0xFF1B4332),
    tertiaryContainer: Color(0xFF2D6A4F),
    onTertiaryContainer: Color(0xFFE8F5E9),
    // Error
    error: Color(0xFFF5A6A0),
    onError: Color(0xFF7B1A1A),
    errorContainer: Color(0xFF9B2C2C),
    onErrorContainer: Color(0xFFFDECEA),
    // Surface - Premium Dark
    surface: Color(0xFF1A1714),
    onSurface: Color(0xFFF0EBE3),
    surfaceContainerHighest: Color(0xFF3A3530),
    surfaceContainerHigh: Color(0xFF302C28),
    surfaceContainer: Color(0xFF262320),
    surfaceContainerLow: Color(0xFF201D1A),
    surfaceContainerLowest: Color(0xFF141210),
    surfaceDim: Color(0xFF1A1714),
    onSurfaceVariant: Color(0xFFB8B0A8),
    // Outline
    outline: Color(0xFF8A8278),
    outlineVariant: Color(0xFF3A3530),
    // Inverse
    inverseSurface: Color(0xFFF0EBE3),
    onInverseSurface: Color(0xFF1A1714),
    inversePrimary: Color(0xFFD4A843),
    // Shadow & Scrim
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );

  // ─── Semantic Status Colors ───────────────────────────────────────
  static const Color success = Color(0xFF27AE60);
  static const Color successLight = Color(0xFFE8F8F0);
  static const Color successDark = Color(0xFF1B7A43);

  static const Color warning = Color(0xFFF39C12);
  static const Color warningLight = Color(0xFFFEF5E1);
  static const Color warningDark = Color(0xFF8A5D08);

  static const Color info = Color(0xFF3498DB);
  static const Color infoLight = Color(0xFFE8F4FD);
  static const Color infoDark = Color(0xFF1A5276);

  // ─── Gradients ────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFD4A843), Color(0xFFE8C96A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFD4A843), Color(0xFFC48B6A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF1A1714), Color(0xFF262320)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient creamGradient = LinearGradient(
    colors: [Color(0xFFFFFBF5), Color(0xFFFEFAF2)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ─── Shadows ──────────────────────────────────────────────────────
  static List<BoxShadow> shadowXs = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 2, offset: const Offset(0, 1)),
  ];

  static List<BoxShadow> shadowSm = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1)),
  ];

  static List<BoxShadow> shadowMd = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2)),
  ];

  static List<BoxShadow> shadowLg = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 16, offset: const Offset(0, 4)),
  ];

  static List<BoxShadow> shadowXl = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 8)),
  ];

  static List<BoxShadow> goldShadow = [
    BoxShadow(
      color: const Color(0xFFD4A843).withValues(alpha: 0.25),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  // ─── Button Dimensions ────────────────────────────────────────────
  static const double buttonHeightSmall = 36;
  static const double buttonHeightMedium = 44;
  static const double buttonHeightLarge = 52;
  static const double buttonHeightXl = 56;

  static const double buttonPaddingHorizontal = 24;
  static const double buttonIconSize = 18;
  static const double buttonGap = 8;

  // ─── Card Dimensions ──────────────────────────────────────────────
  static const double cardPadding = 16;
  static const double cardGap = 12;

  // ─── TextField Dimensions ─────────────────────────────────────────
  static const double textFieldHeight = 52;
  static const double textFieldPaddingHorizontal = 16;

  // ─── Chip Dimensions ──────────────────────────────────────────────
  static const double chipHeight = 32;
  static const double chipGap = 8;
  static const double chipIconSize = 18;

  // ─── Icon Sizes ───────────────────────────────────────────────────
  static const double iconSm = 18;
  static const double iconMd = 24;
  static const double iconLg = 32;
  static const double iconXl = 40;

  // ─── Avatar Sizes ─────────────────────────────────────────────────
  static const double avatarSm = 32;
  static const double avatarMd = 40;
  static const double avatarLg = 56;
  static const double avatarXl = 72;
}
