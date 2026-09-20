import 'dart:ui';

import 'package:antiiq/chaos/chaos_ui_state.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum AntiiQSurfaceRole { panel, elevated, control, quiet }

class AntiiQSurfaceTokens {
  const AntiiQSurfaceTokens._({
    required this.fill,
    required this.borderColor,
    required this.blur,
    required this.shadow,
  });

  final Color fill;
  final Color borderColor;
  final double blur;
  final List<BoxShadow> shadow;

  factory AntiiQSurfaceTokens.of(
    BuildContext context, {
    AntiiQSurfaceRole role = AntiiQSurfaceRole.panel,
    bool enableBlur = false,
  }) {
    final material = context.select<ChaosUIState, AntiiQSurfaceStyle>(
      (state) => state.surfaceStyle,
    );
    final colors = AntiiQTheme.of(context).colorScheme;
    final roleOpacity = switch (role) {
      AntiiQSurfaceRole.panel => 0.0,
      AntiiQSurfaceRole.elevated => 0.08,
      AntiiQSurfaceRole.control => 0.12,
      AntiiQSurfaceRole.quiet => -0.12,
    };
    final roleTint = switch (role) {
      AntiiQSurfaceRole.panel => 0.7,
      AntiiQSurfaceRole.elevated => 1.0,
      AntiiQSurfaceRole.control => 0.45,
      AntiiQSurfaceRole.quiet => 0.3,
    };
    final base =
        role == AntiiQSurfaceRole.panel ? colors.background : colors.surface;
    final tinted = Color.lerp(
          base,
          colors.primary,
          (material.tint * roleTint).clamp(0.0, 0.35),
        ) ??
        base;
    final opacity = (material.opacity + roleOpacity).clamp(0.12, 1.0);
    final borderStrength =
        (material.border * (role == AntiiQSurfaceRole.elevated ? 1.15 : 1.0))
            .clamp(0.0, 1.0);

    return AntiiQSurfaceTokens._(
      fill: tinted.withValues(alpha: opacity),
      borderColor: colors.primary.withValues(alpha: borderStrength),
      blur: enableBlur ? material.blur : 0,
      shadow: role == AntiiQSurfaceRole.elevated
          ? [
              BoxShadow(
                color: colors.primary
                    .withValues(alpha: 0.05 + material.tint * 0.25),
                blurRadius: 18,
                spreadRadius: -6,
                offset: const Offset(0, 8),
              ),
            ]
          : const [],
    );
  }
}

class AntiiQSurface extends StatelessWidget {
  const AntiiQSurface({
    required this.child,
    super.key,
    this.role = AntiiQSurfaceRole.panel,
    this.enableBlur = false,
    this.radius,
    this.padding,
    this.margin,
    this.border,
    this.width,
    this.height,
  });

  final Widget child;
  final AntiiQSurfaceRole role;
  final bool enableBlur;
  final double? radius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Border? border;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final tokens = AntiiQSurfaceTokens.of(
      context,
      role: role,
      enableBlur: enableBlur,
    );
    final resolvedRadius = radius ??
        context.select<ChaosUIState, double>((state) => state.chaosRadius);
    final borderRadius = BorderRadius.circular(resolvedRadius);
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: tokens.fill,
        border: border ?? Border.all(color: tokens.borderColor),
        borderRadius: borderRadius,
        boxShadow: tokens.shadow,
      ),
      child: child,
    );

    final clipped = ClipRRect(
      borderRadius: borderRadius,
      child: tokens.blur <= 0
          ? content
          : BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: tokens.blur,
                sigmaY: tokens.blur,
                tileMode: TileMode.decal,
              ),
              child: content,
            ),
    );

    return RepaintBoundary(
      child:
          margin == null ? clipped : Padding(padding: margin!, child: clipped),
    );
  }
}
