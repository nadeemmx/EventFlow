import 'package:flutter/material.dart';

class AppDimens {
  AppDimens._();

  // Spacing
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
  static const double massive = 48;

  // Border Radius
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusXxl = 24;
  static const double radiusFull = 999;

  // Card Radius
  static const double cardRadius = 16;
  static const double bottomSheetRadius = 24;
  static const double dialogRadius = 20;

  // Font Sizes
  static const double fontXs = 11;
  static const double fontSm = 12;
  static const double fontMd = 14;
  static const double fontBase = 16;
  static const double fontLg = 18;
  static const double fontXl = 20;
  static const double fontXxl = 24;
  static const double fontXxxl = 28;
  static const double fontDisplay = 32;

  // Icon Sizes
  static const double iconSm = 18;
  static const double iconMd = 22;
  static const double iconLg = 28;
  static const double iconXl = 36;
  static const double iconXxl = 48;

  // Heights
  static const double buttonHeight = 52;
  static const double inputHeight = 52;
  static const double appBarHeight = 56;
  static const double bottomNavHeight = 72;
  static const double chipHeight = 36;
  static const double listItemHeight = 72;
  static const double avatarSm = 32;
  static const double avatarMd = 44;
  static const double avatarLg = 56;
  static const double avatarXl = 72;

  // Animation Durations
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 250);
  static const Duration animSlow = Duration(milliseconds: 400);
  static const Duration animVerySlow = Duration(milliseconds: 600);

  // Curves
  static const Curve curveDefault = Curves.easeOutCubic;
  static const Curve curveSpring = Curves.elasticOut;
  static const Curve curveBounce = Curves.bounceOut;
}
