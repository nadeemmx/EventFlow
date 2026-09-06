import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── EventFlow Gold / Primary ─────────────────────────────────────
  static const Color primary = Color(0xFFD4A843);
  static const Color primaryLight = Color(0xFFE8C96A);
  static const Color primaryDark = Color(0xFFB8922E);
  static const Color primarySurface = Color(0xFFFDF6E3);

  // ─── Warm Accent ──────────────────────────────────────────────────
  static const Color accent = Color(0xFFC48B6A);
  static const Color accentLight = Color(0xFFF0B89A);

  // ─── Secondary ────────────────────────────────────────────────────
  static const Color secondary = Color(0xFF7A9E7E);
  static const Color secondaryLight = Color(0xFFA8D5AB);

  // ─── Backgrounds - Warm Cream / Ivory ─────────────────────────────
  static const Color background = Color(0xFFFFFBF5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Colors.white;
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color warmSurface = Color(0xFFFAF5ED);
  static const Color ivory = Color(0xFFFEFAF2);
  static const Color cream = Color(0xFFFDF6E3);

  // ─── Dark Mode Backgrounds ────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF1A1714);
  static const Color surfaceDark = Color(0xFF262320);
  static const Color cardDark = Color(0xFF2A2622);
  static const Color textPrimaryDark = Color(0xFFF0EBE3);
  static const Color textSecondaryDark = Color(0xFFB8B0A8);
  static const Color dividerDark = Color(0xFF3A3530);
  static const Color borderDark = Color(0xFF4A4540);
  static const Color primarySurfaceDark = Color(0xFF3D3210);

  // ─── Dividers & Borders ───────────────────────────────────────────
  static const Color divider = Color(0xFFE8E3DB);
  static const Color border = Color(0xFFDDD8D0);
  static const Color borderLight = Color(0xFFF0EBE3);

  // ─── Text ─────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6560);
  static const Color textTertiary = Color(0xFF9B9590);
  static const Color textHint = Color(0xFFB8B0A8);
  static const Color textOnPrimary = Colors.white;

  // ─── Status ───────────────────────────────────────────────────────
  static const Color success = Color(0xFF27AE60);
  static const Color successLight = Color(0xFFE8F8F0);
  static const Color warning = Color(0xFFF39C12);
  static const Color warningLight = Color(0xFFFEF5E1);
  static const Color error = Color(0xFFC0392B);
  static const Color errorLight = Color(0xFFFDECEA);
  static const Color info = Color(0xFF3498DB);
  static const Color infoLight = Color(0xFFE8F4FD);

  // ─── Booking Status ───────────────────────────────────────────────
  static const Color bookingDraft = Color(0xFF9B9590);
  static const Color bookingDraftBg = Color(0xFFF0EBE3);
  static const Color bookingTentative = Color(0xFFF39C12);
  static const Color bookingTentativeBg = Color(0xFFFEF5E1);
  static const Color bookingConfirmed = Color(0xFF27AE60);
  static const Color bookingConfirmedBg = Color(0xFFE8F8F0);
  static const Color bookingInProgress = Color(0xFF3498DB);
  static const Color bookingInProgressBg = Color(0xFFE8F4FD);
  static const Color bookingCompleted = Color(0xFF1B7A43);
  static const Color bookingCompletedBg = Color(0xFFE8F8F0);
  static const Color bookingCancelled = Color(0xFFC0392B);
  static const Color bookingCancelledBg = Color(0xFFFDECEA);

  // ─── Lead Status ──────────────────────────────────────────────────
  static const Color leadNew = Color(0xFF3498DB);
  static const Color leadNewBg = Color(0xFFE8F4FD);
  static const Color leadContacted = Color(0xFF8E6BA1);
  static const Color leadContactedBg = Color(0xFFF3ECF7);
  static const Color leadSiteVisit = Color(0xFFF39C12);
  static const Color leadSiteVisitBg = Color(0xFFFEF5E1);
  static const Color leadNegotiation = Color(0xFFE67E22);
  static const Color leadNegotiationBg = Color(0xFFFDEBD0);
  static const Color leadConverted = Color(0xFF27AE60);
  static const Color leadConvertedBg = Color(0xFFE8F8F0);
  static const Color leadLost = Color(0xFFC0392B);
  static const Color leadLostBg = Color(0xFFFDECEA);

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

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFC48B6A), Color(0xFFD4A843)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF27AE60), Color(0xFF1B7A43)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF1A1714), Color(0xFF262320)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [Color(0xFFFAF5ED), Color(0xFFF0EBE3), Color(0xFFFAF5ED)],
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
  );

  // ─── Shadows ──────────────────────────────────────────────────────
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: const Color(0xFFD4A843).withValues(alpha: 0.12),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 12,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];
}
