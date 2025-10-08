import 'package:flutter/material.dart';

/// Defines anchor positions for canvas overlays
enum CanvasOverlayAnchor {
  topLeft,
  topCenter,
  topRight,
  centerLeft,
  center,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
  custom,
}

/// A widget overlay positioned on the typography canvas
class CanvasOverlay {
  /// The widget to display
  final Widget child;

  /// Predefined anchor position
  final CanvasOverlayAnchor anchor;

  /// Padding around the widget (applied based on anchor)
  final EdgeInsets padding;

  /// Whether to respect safe area for this overlay
  final bool useSafeArea;

  /// Custom positioning - only used when anchor == CanvasOverlayAnchor.custom
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;

  /// Optional builder that has access to context
  final Widget Function(BuildContext context, Widget child)? builder;

  const CanvasOverlay({
    required this.child,
    this.anchor = CanvasOverlayAnchor.custom,
    this.padding = const EdgeInsets.all(16),
    this.useSafeArea = true,
    this.top,
    this.bottom,
    this.left,
    this.right,
    this.builder,
  }) : assert(
          anchor != CanvasOverlayAnchor.custom ||
              ((top != null || bottom != null) &&
                  (left != null || right != null)),
          'Custom anchor requires at least one vertical (top/bottom) and one horizontal (left/right) position',
        );

  /// Creates a top-left anchored overlay
  const CanvasOverlay.topLeft({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
    bool useSafeArea = true,
    Widget Function(BuildContext context, Widget child)? builder,
  }) : this(
          child: child,
          anchor: CanvasOverlayAnchor.topLeft,
          padding: padding,
          useSafeArea: useSafeArea,
          builder: builder,
        );

  /// Creates a top-center anchored overlay
  const CanvasOverlay.topCenter({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
    bool useSafeArea = true,
    Widget Function(BuildContext context, Widget child)? builder,
  }) : this(
          child: child,
          anchor: CanvasOverlayAnchor.topCenter,
          padding: padding,
          useSafeArea: useSafeArea,
          builder: builder,
        );

  /// Creates a top-right anchored overlay
  const CanvasOverlay.topRight({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
    bool useSafeArea = true,
    Widget Function(BuildContext context, Widget child)? builder,
  }) : this(
          child: child,
          anchor: CanvasOverlayAnchor.topRight,
          padding: padding,
          useSafeArea: useSafeArea,
          builder: builder,
        );

  /// Creates a bottom-left anchored overlay
  const CanvasOverlay.bottomLeft({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
    bool useSafeArea = true,
    Widget Function(BuildContext context, Widget child)? builder,
  }) : this(
          child: child,
          anchor: CanvasOverlayAnchor.bottomLeft,
          padding: padding,
          useSafeArea: useSafeArea,
          builder: builder,
        );

  /// Creates a bottom-right anchored overlay
  const CanvasOverlay.bottomRight({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
    bool useSafeArea = true,
    Widget Function(BuildContext context, Widget child)? builder,
  }) : this(
          child: child,
          anchor: CanvasOverlayAnchor.bottomRight,
          padding: padding,
          useSafeArea: useSafeArea,
          builder: builder,
        );

  /// Builds the positioned widget based on anchor
  Widget build(BuildContext context) {
    Widget content = builder?.call(context, child) ?? child;

    // Apply safe area if needed
    if (useSafeArea) {
      content = SafeArea(
        left: _shouldApplySafeArea('left'),
        right: _shouldApplySafeArea('right'),
        top: _shouldApplySafeArea('top'),
        bottom: _shouldApplySafeArea('bottom'),
        child: content,
      );
    }

    return Positioned(
      top: _getTop(),
      bottom: _getBottom(),
      left: _getLeft(),
      right: _getRight(),
      child: content,
    );
  }

  bool _shouldApplySafeArea(String edge) {
    switch (anchor) {
      case CanvasOverlayAnchor.topLeft:
        return edge == 'top' || edge == 'left';
      case CanvasOverlayAnchor.topCenter:
        return edge == 'top';
      case CanvasOverlayAnchor.topRight:
        return edge == 'top' || edge == 'right';
      case CanvasOverlayAnchor.centerLeft:
        return edge == 'left';
      case CanvasOverlayAnchor.center:
        return false;
      case CanvasOverlayAnchor.centerRight:
        return edge == 'right';
      case CanvasOverlayAnchor.bottomLeft:
        return edge == 'bottom' || edge == 'left';
      case CanvasOverlayAnchor.bottomCenter:
        return edge == 'bottom';
      case CanvasOverlayAnchor.bottomRight:
        return edge == 'bottom' || edge == 'right';
      case CanvasOverlayAnchor.custom:
        // For custom, apply based on which edges are constrained
        if (edge == 'top') return top != null;
        if (edge == 'bottom') return bottom != null;
        if (edge == 'left') return left != null;
        if (edge == 'right') return right != null;
        return false;
    }
  }

  double? _getTop() {
    switch (anchor) {
      case CanvasOverlayAnchor.topLeft:
      case CanvasOverlayAnchor.topCenter:
      case CanvasOverlayAnchor.topRight:
        return padding.top;
      case CanvasOverlayAnchor.centerLeft:
      case CanvasOverlayAnchor.center:
      case CanvasOverlayAnchor.centerRight:
        return null;
      case CanvasOverlayAnchor.bottomLeft:
      case CanvasOverlayAnchor.bottomCenter:
      case CanvasOverlayAnchor.bottomRight:
        return null;
      case CanvasOverlayAnchor.custom:
        return top;
    }
  }

  double? _getBottom() {
    switch (anchor) {
      case CanvasOverlayAnchor.topLeft:
      case CanvasOverlayAnchor.topCenter:
      case CanvasOverlayAnchor.topRight:
        return null;
      case CanvasOverlayAnchor.centerLeft:
      case CanvasOverlayAnchor.center:
      case CanvasOverlayAnchor.centerRight:
        return null;
      case CanvasOverlayAnchor.bottomLeft:
      case CanvasOverlayAnchor.bottomCenter:
      case CanvasOverlayAnchor.bottomRight:
        return padding.bottom;
      case CanvasOverlayAnchor.custom:
        return bottom;
    }
  }

  double? _getLeft() {
    switch (anchor) {
      case CanvasOverlayAnchor.topLeft:
      case CanvasOverlayAnchor.centerLeft:
      case CanvasOverlayAnchor.bottomLeft:
        return padding.left;
      case CanvasOverlayAnchor.topCenter:
      case CanvasOverlayAnchor.center:
      case CanvasOverlayAnchor.bottomCenter:
        return null;
      case CanvasOverlayAnchor.topRight:
      case CanvasOverlayAnchor.centerRight:
      case CanvasOverlayAnchor.bottomRight:
        return null;
      case CanvasOverlayAnchor.custom:
        return left;
    }
  }

  double? _getRight() {
    switch (anchor) {
      case CanvasOverlayAnchor.topLeft:
      case CanvasOverlayAnchor.centerLeft:
      case CanvasOverlayAnchor.bottomLeft:
        return null;
      case CanvasOverlayAnchor.topCenter:
      case CanvasOverlayAnchor.center:
      case CanvasOverlayAnchor.bottomCenter:
        return null;
      case CanvasOverlayAnchor.topRight:
      case CanvasOverlayAnchor.centerRight:
      case CanvasOverlayAnchor.bottomRight:
        return padding.right;
      case CanvasOverlayAnchor.custom:
        return right;
    }
  }
}
