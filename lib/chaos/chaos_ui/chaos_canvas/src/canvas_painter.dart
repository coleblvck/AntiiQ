import 'dart:math' as math;

import 'package:antiiq/chaos/chaos_ui/chaos_canvas/models/canvas_element.dart';
import 'package:flutter/rendering.dart';

class CanvasPainter extends CustomPainter {
  final List<CanvasElement> elements;
  final List<CanvasElement> floatingNumbers;
  final double animationValue;
  final Offset panOffset;
  final String? selectedId;
  final bool editMode;
  final String? draggedId;
  final Size canvasSize;
  final double zoomScale;

  CanvasPainter({
    required this.elements,
    required this.floatingNumbers,
    required this.animationValue,
    required this.panOffset,
    this.selectedId,
    required this.editMode,
    this.draggedId,
    required this.canvasSize,
    this.zoomScale = 1.0, // Default zoom
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw drag boundary guide in edit mode
    if (editMode) {
      _paintDragBoundary(canvas);
    }
    // Draw floating numbers first (background)
    for (var i = 0; i < floatingNumbers.length; i++) {
      if (!editMode && floatingNumbers[i].isHidden) continue;
      _paintElement(canvas, floatingNumbers[i], i, true);
    }

    // Draw main elements
    for (var i = 0; i < elements.length; i++) {
      if (!editMode && elements[i].isHidden) continue;
      _paintElement(canvas, elements[i], i, false);
    }
  }

  void _paintDragBoundary(Canvas canvas) {
    final bounds = Rect.fromLTRB(
      canvasSize.width * 0.1 + panOffset.dx,
      canvasSize.height * 0.1 + panOffset.dy,
      canvasSize.width * 0.9 + panOffset.dx,
      canvasSize.height * 0.9 + panOffset.dy,
    );

    final paint = Paint()
      ..color = const Color(0xFFD9B483).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.square;

    const dashWidth = 10.0;
    const dashSpace = 8.0;

    // Top edge
    double startX = bounds.left;
    while (startX < bounds.right) {
      canvas.drawLine(
        Offset(startX, bounds.top),
        Offset(
            (startX + dashWidth).clamp(bounds.left, bounds.right), bounds.top),
        paint,
      );
      startX += dashWidth + dashSpace;
    }

    // Bottom edge
    startX = bounds.left;
    while (startX < bounds.right) {
      canvas.drawLine(
        Offset(startX, bounds.bottom),
        Offset((startX + dashWidth).clamp(bounds.left, bounds.right),
            bounds.bottom),
        paint,
      );
      startX += dashWidth + dashSpace;
    }

    // Left edge
    double startY = bounds.top;
    while (startY < bounds.bottom) {
      canvas.drawLine(
        Offset(bounds.left, startY),
        Offset(
            bounds.left, (startY + dashWidth).clamp(bounds.top, bounds.bottom)),
        paint,
      );
      startY += dashWidth + dashSpace;
    }

    // Right edge
    startY = bounds.top;
    while (startY < bounds.bottom) {
      canvas.drawLine(
        Offset(bounds.right, startY),
        Offset(bounds.right,
            (startY + dashWidth).clamp(bounds.top, bounds.bottom)),
        paint,
      );
      startY += dashWidth + dashSpace;
    }
  }

  void _paintElement(
      Canvas canvas, CanvasElement element, int index, bool isFloating) {
    canvas.save();

    final isDragged = element.id == draggedId;

    // Calculate float animation (freeze if being dragged)
    final floatOffset =
        isDragged ? 0.0 : math.sin(animationValue * 2 * math.pi + index) * 8;
    final verticalDrift = isFloating && !isDragged
        ? math.cos(animationValue * 2 * math.pi + index * 0.8) * 15
        : 0.0;

    // Apply zoom to position (elements scale with canvas)
    final scaledPosition = element.position * zoomScale;

    // Apply position with animation
    final x = scaledPosition.dx + panOffset.dx;
    final y = scaledPosition.dy + floatOffset + verticalDrift + panOffset.dy;

    canvas.translate(x, y);
    canvas.rotate(element.rotation);

    // Determine opacity
    final baseOpacity = isFloating ? 0.6 : 0.8;
    final opacity = element.isHidden ? 0.3 : baseOpacity;
    final isSelected = element.id == selectedId;

    // Draw selection indicators
    if (isSelected && editMode) {
      _paintSelectionIndicators(canvas, element);
    }

    // Scale font size with zoom
    final scaledFontSize = element.fontSize * zoomScale;

    // Create text painter
    final textPainter = TextPainter(
      text: TextSpan(
        text: element.title,
        style: TextStyle(
          color: element.color.withValues(alpha: isSelected ? 1.0 : opacity),
          fontSize: scaledFontSize, // Use scaled font size
          fontWeight: element.fontWeight,
          letterSpacing: element.letterSpacing,
          shadows: isSelected && !isFloating
              ? [
                  Shadow(
                    color: element.color.withValues(alpha: 0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 0),
                  )
                ]
              : null,
          decoration:
              isSelected && !editMode ? TextDecoration.lineThrough : null,
          decorationColor: element.color,
          decorationThickness: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );

    // Draw corner brackets if selected and not in edit mode
    if (isSelected && !editMode && !isFloating) {
      _paintCornerBrackets(
          canvas, textPainter.width, textPainter.height, element.color);
    }

    canvas.restore();
  }

  void _paintSelectionIndicators(Canvas canvas, CanvasElement element) {
    final paint = Paint()
      ..color = const Color(0xFFD9B483).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(Offset.zero, 50, paint);
  }

  void _paintCornerBrackets(
      Canvas canvas, double width, double height, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final left = -width / 2 - 8;
    final right = width / 2 + 8;
    final top = -height / 2 - 8;
    final bottom = height / 2 + 8;
    final cornerSize = 12.0;

    // Top-left
    canvas.drawLine(Offset(left, top), Offset(left + cornerSize, top), paint);
    canvas.drawLine(Offset(left, top), Offset(left, top + cornerSize), paint);

    // Bottom-right
    canvas.drawLine(
        Offset(right, bottom), Offset(right - cornerSize, bottom), paint);
    canvas.drawLine(
        Offset(right, bottom), Offset(right, bottom - cornerSize), paint);
  }

  @override
  bool shouldRepaint(CanvasPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.panOffset != panOffset ||
        oldDelegate.selectedId != selectedId ||
        oldDelegate.editMode != editMode ||
        oldDelegate.draggedId != draggedId ||
        oldDelegate.elements != elements ||
        oldDelegate.floatingNumbers != floatingNumbers ||
        oldDelegate.zoomScale != zoomScale;
  }
}
