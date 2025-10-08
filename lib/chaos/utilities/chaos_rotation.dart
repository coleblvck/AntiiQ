import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Utility class for calculating chaos-style rotation patterns
class ChaosRotation {
  /// Calculate rotation based on index and style
  static double calculate({
    required int index,
    required ChaosRotationStyle style,
    required double maxAngle,
    int? totalItems,
  }) {
    switch (style) {
      case ChaosRotationStyle.oscillating:
        return _oscillating(index, maxAngle);
      case ChaosRotationStyle.wave:
        return _wave(index, maxAngle);
      case ChaosRotationStyle.fibonacci:
        return _fibonacci(index, maxAngle);
      case ChaosRotationStyle.spiral:
        return _spiral(index, maxAngle, totalItems ?? 100);
      case ChaosRotationStyle.random:
        return _random(index, maxAngle);
      case ChaosRotationStyle.alternating:
        return _alternating(index, maxAngle);
      case ChaosRotationStyle.decay:
        return _decay(index, maxAngle);
      case ChaosRotationStyle.simple:
        return _simple(index, maxAngle);
    }
  }

  /// Simple wave pattern - good for cards, grids
  static double _simple(int index, double maxAngle) {
    return (index % 7 - 3) * maxAngle * 0.015;
  }

  /// Oscillating with decay - calms down over time
  static double _oscillating(int index, double maxAngle) {
    final cycle = (index / 7).floor();
    final position = index % 7;
    final direction = cycle % 2 == 0 ? 1 : -1;
    final amplitude = maxAngle * math.exp(-cycle * 0.1);
    return direction * amplitude * math.sin(position * math.pi / 6);
  }

  /// Continuous wave - never decays
  static double _wave(int index, double maxAngle) {
    return maxAngle * math.sin(index * 0.5);
  }

  /// Golden ratio based - organic, non-repeating
  static double _fibonacci(int index, double maxAngle) {
    final goldenRatio = (1 + math.sqrt(5)) / 2;
    final fibAngle = (index * goldenRatio * math.pi) % (2 * math.pi);
    return maxAngle * math.sin(fibAngle);
  }

  /// Spiral - tightens as it progresses
  static double _spiral(int index, double maxAngle, int totalItems) {
    final progress = index / totalItems;
    final spiralAngle = index * 0.3;
    final amplitude = maxAngle * (1 - progress * 0.5);
    return amplitude * math.sin(spiralAngle);
  }

  /// Deterministic pseudo-random
  static double _random(int index, double maxAngle) {
    final seed = index * 97 + 23;
    final random = math.sin(seed) * 43758.5453;
    final normalized = (random - random.floor()) * 2 - 1;
    return maxAngle * normalized;
  }

  /// Zigzag with variation
  static double _alternating(int index, double maxAngle) {
    final baseRotation = (index % 2 == 0) ? maxAngle : -maxAngle;
    final variation = math.sin(index * 0.1) * 0.3;
    return baseRotation * (1 + variation);
  }

  /// Pattern with exponential decay
  static double _decay(int index, double maxAngle) {
    final direction = (index % 3 == 0)
        ? 1
        : (index % 3 == 1)
            ? -1
            : 0;
    final decay = math.exp(-index * 0.05);
    return maxAngle * direction * decay;
  }

  /// Generate a list of rotations for batch processing
  static List<double> generateList({
    required int count,
    required ChaosRotationStyle style,
    required double maxAngle,
  }) {
    return List.generate(
      count,
      (index) => calculate(
        index: index,
        style: style,
        maxAngle: maxAngle,
        totalItems: count,
      ),
    );
  }
}

enum ChaosRotationStyle {
  simple,
  oscillating,
  wave,
  fibonacci,
  spiral,
  random,
  alternating,
  decay,
}

class ChaosRotatedWidget extends StatelessWidget {
  final Widget child;
  final ChaosRotationStyle style;
  final double maxAngle;
  final int? index;
  final double? angle;

  const ChaosRotatedWidget({
    required this.child,
    this.style = ChaosRotationStyle.random,
    this.maxAngle = 0.1,
    this.index,
    this.angle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle ??
          ChaosRotation.calculate(
            index: index ?? math.Random().nextInt(1000),
            style: style,
            maxAngle: maxAngle,
          ),
      child: child,
    );
  }
}

class ChaosRotatedStatefulWidget extends StatefulWidget {
  final Widget child;
  final ChaosRotationStyle style;
  final double maxAngle;
  final int? index;
  final double? angle;

  const ChaosRotatedStatefulWidget({
    required this.child,
    this.style = ChaosRotationStyle.random,
    this.maxAngle = 0.1,
    this.index,
    this.angle,
    super.key,
  });

  @override
  State<ChaosRotatedStatefulWidget> createState() =>
      _ChaosRotatedStatefulWidgetState();
}

class _ChaosRotatedStatefulWidgetState
    extends State<ChaosRotatedStatefulWidget> {
  late final int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.index ?? math.Random().nextInt(1000);
  }

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: widget.angle ??
          ChaosRotation.calculate(
            index: _index,
            style: widget.style,
            maxAngle: widget.maxAngle,
          ),
      child: widget.child,
    );
  }
}
