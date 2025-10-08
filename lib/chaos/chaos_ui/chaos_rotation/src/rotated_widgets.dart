import 'dart:math' as math;

import 'package:antiiq/chaos/chaos_ui/chaos_rotation/src/rotation_calculator.dart';
import 'package:antiiq/chaos/chaos_ui/chaos_rotation/src/rotation_styles.dart';
import 'package:flutter/widgets.dart';

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
