import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Premium Indigo-Violet primary
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primarySurface = Color(0xFFEEF2FF);

  // Accent - warm coral for CTAs
  static const Color accent = Color(0xFFF97316);
  static const Color accentLight = Color(0xFFFDBA74);

  // Secondary
  static const Color secondary = Color(0xFFEC4899);
  static const Color secondaryLight = Color(0xFFF472B6);

  // Backgrounds - warm off-whites
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Colors.white;
  static const Color card = Colors.white;
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color cardDark = Color(0xFF1E293B);
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color dividerDark = Color(0xFF334155);
  static const Color borderDark = Color(0xFF475569);
  static const Color primarySurfaceDark = Color(0xFF1E1B4B);

  // Dividers & Borders
  static const Color divider = Color(0xFFE5E7EB);
  static const Color border = Color(0xFFD1D5DB);
  static const Color borderLight = Color(0xFFF1F5F9);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textHint = Color(0xFFCBD5E1);
  static const Color textOnPrimary = Colors.white;

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // Booking Status
  static const Color bookingDraft = Color(0xFF94A3B8);
  static const Color bookingDraftBg = Color(0xFFF1F5F9);
  static const Color bookingTentative = Color(0xFFF59E0B);
  static const Color bookingTentativeBg = Color(0xFFFEF3C7);
  static const Color bookingConfirmed = Color(0xFF10B981);
  static const Color bookingConfirmedBg = Color(0xFFD1FAE5);
  static const Color bookingInProgress = Color(0xFF3B82F6);
  static const Color bookingInProgressBg = Color(0xFFDBEAFE);
  static const Color bookingCompleted = Color(0xFF059669);
  static const Color bookingCompletedBg = Color(0xFFD1FAE5);
  static const Color bookingCancelled = Color(0xFFEF4444);
  static const Color bookingCancelledBg = Color(0xFFFEE2E2);

  // Lead Status
  static const Color leadNew = Color(0xFF3B82F6);
  static const Color leadNewBg = Color(0xFFDBEAFE);
  static const Color leadContacted = Color(0xFF8B5CF6);
  static const Color leadContactedBg = Color(0xFFEDE9FE);
  static const Color leadSiteVisit = Color(0xFFF59E0B);
  static const Color leadSiteVisitBg = Color(0xFFFEF3C7);
  static const Color leadNegotiation = Color(0xFFF97316);
  static const Color leadNegotiationBg = Color(0xFFFED7AA);
  static const Color leadConverted = Color(0xFF10B981);
  static const Color leadConvertedBg = Color(0xFFD1FAE5);
  static const Color leadLost = Color(0xFFEF4444);
  static const Color leadLostBg = Color(0xFFFEE2E2);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFF97316), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0), Color(0xFFF1F5F9)],
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
  );

  // Shadows
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: const Color(0xFF6366F1).withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 16,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}
