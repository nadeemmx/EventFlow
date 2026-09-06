import 'package:flutter/material.dart';
import 'package:eventflow_app/core/theme/design_system.dart';

class PageTransitions {
  PageTransitions._();

  // ─── Transitions Builder Functions ────────────────────────────────
  // Use these as `transitionsBuilder` in CustomTransitionPage.

  static Widget fadeThrough(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: DesignSystem.easeEmphasized,
      reverseCurve: DesignSystem.easeEmphasized,
    );
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.8, curve: DesignSystem.easeEmphasized),
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 0.04),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }

  static Widget slideFromRight(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final slideTween = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: DesignSystem.easeEmphasizedDecelerate,
      reverseCurve: DesignSystem.easeEmphasizedAccelerate,
    ));
    final fadeTween = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    return FadeTransition(
      opacity: fadeTween,
      child: SlideTransition(position: slideTween, child: child),
    );
  }

  static Widget slideFromBottom(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final slideTween = Tween<Offset>(
      begin: const Offset(0.0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: DesignSystem.easeEmphasizedDecelerate,
      reverseCurve: DesignSystem.easeEmphasizedAccelerate,
    ));
    final fadeTween = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    return FadeTransition(
      opacity: fadeTween,
      child: SlideTransition(position: slideTween, child: child),
    );
  }

  static Widget scaleTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final scaleTween = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: DesignSystem.easeEmphasizedDecelerate,
        reverseCurve: DesignSystem.easeEmphasizedAccelerate,
      ),
    );
    final fadeTween = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    return ScaleTransition(
      scale: scaleTween,
      child: FadeTransition(opacity: fadeTween, child: child),
    );
  }

  static Widget sharedAxisHorizontal(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final slideTween = Tween<Offset>(
      begin: const Offset(0.3, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: DesignSystem.easeEmphasized,
      reverseCurve: DesignSystem.easeEmphasized,
    ));
    final fadeTween = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );
    return FadeTransition(
      opacity: fadeTween,
      child: SlideTransition(position: slideTween, child: child),
    );
  }
}
