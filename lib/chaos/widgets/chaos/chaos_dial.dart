import 'dart:math' as math;

import 'package:flutter/material.dart';

class AntiiQDial extends StatefulWidget {
  final double value;
  final Function(double) onChanged;
  final double size;
  final Color color;
  final String label;
  final bool enabled;
  final double centerValue;

  const AntiiQDial({
    required this.value,
    required this.onChanged,
    this.size = 100,
    this.color = Colors.white,
    this.label = '',
    this.enabled = true,
    this.centerValue =
        0.0, // 0.0 means no center line, 0.5 means center at middle
    super.key,
  });

  @override
  State<AntiiQDial> createState() => _AntiiQDialState();
}

class _AntiiQDialState extends State<AntiiQDial> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        final center = Offset(widget.size / 2, widget.size / 2);
        final angle = math.atan2(
          details.localPosition.dy - center.dy,
          details.localPosition.dx - center.dx,
        );

        // Convert angle to value (0.0 to 1.0)
        double normalizedAngle = (angle + math.pi) / (2 * math.pi);
        normalizedAngle =
            (normalizedAngle + 0.75) % 1.0; // Rotate to start at top

        widget.onChanged(normalizedAngle);
      },
      child: CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _DialPainter(
          value: widget.value,
          color: widget.color,
          enabled: widget.enabled,
          centerValue: widget.centerValue,
        ),
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.label.isNotEmpty)
                  Transform.rotate(
                    angle: -0.005,
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        color: widget.enabled
                            ? widget.color
                            : Colors.white.withValues(alpha: 0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  final double value;
  final Color color;
  final bool enabled;
  final double centerValue;

  _DialPainter({
    required this.value,
    required this.color,
    required this.enabled,
    required this.centerValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw outer ring
    paint.color = Colors.white.withValues(alpha: 0.2);
    canvas.drawCircle(center, radius, paint);

    // Draw inner ring
    paint.color = Colors.white.withValues(alpha: 0.1);
    canvas.drawCircle(center, radius - 4, paint);

    // Draw tick marks
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * math.pi - math.pi / 2;
      final startRadius = radius - 2;
      final endRadius = radius + (i % 3 == 0 ? 4 : 2);

      final start = Offset(
        center.dx + math.cos(angle) * startRadius,
        center.dy + math.sin(angle) * startRadius,
      );
      final end = Offset(
        center.dx + math.cos(angle) * endRadius,
        center.dy + math.sin(angle) * endRadius,
      );

      paint.color = Colors.white.withValues(alpha: i % 3 == 0 ? 0.6 : 0.3);
      canvas.drawLine(start, end, paint);
    }

    // Draw center indicator if specified
    if (centerValue > 0) {
      final centerAngle = (centerValue * 2 * math.pi) - math.pi / 2;
      final centerStart = Offset(
        center.dx + math.cos(centerAngle) * (radius - 6),
        center.dy + math.sin(centerAngle) * (radius - 6),
      );
      final centerEnd = Offset(
        center.dx + math.cos(centerAngle) * (radius + 2),
        center.dy + math.sin(centerAngle) * (radius + 2),
      );

      paint.color = Colors.white.withValues(alpha: 0.8);
      paint.strokeWidth = 3;
      canvas.drawLine(centerStart, centerEnd, paint);
    }

    // Draw value indicator
    final valueAngle = (value * 2 * math.pi) - math.pi / 2;
    final valueStart = Offset(
      center.dx + math.cos(valueAngle) * (radius - 8),
      center.dy + math.sin(valueAngle) * (radius - 8),
    );
    final valueEnd = Offset(
      center.dx + math.cos(valueAngle) * (radius + 6),
      center.dy + math.sin(valueAngle) * (radius + 6),
    );

    paint.color = enabled ? color : Colors.white.withValues(alpha: 0.5);
    paint.strokeWidth = 4;
    canvas.drawLine(valueStart, valueEnd, paint);

    // Draw center dot
    paint.style = PaintingStyle.fill;
    paint.color = enabled
        ? color.withValues(alpha: 0.8)
        : Colors.white.withValues(alpha: 0.3);
    canvas.drawCircle(center, 3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
