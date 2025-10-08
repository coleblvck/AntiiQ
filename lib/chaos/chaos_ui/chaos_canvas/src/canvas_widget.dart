import 'dart:math' as math;

import 'package:antiiq/chaos/chaos_ui/chaos_canvas/models/canvas_element.dart';
import 'package:antiiq/chaos/chaos_ui/chaos_canvas/src/canvas_controller.dart';
import 'package:antiiq/chaos/chaos_ui/chaos_canvas/src/canvas_overlay.dart';
import 'package:antiiq/chaos/chaos_ui/chaos_canvas/src/canvas_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChaosCanvas extends StatefulWidget {
  final CanvasController controller;
  final AnimationController floatAnimation;
  final List<CanvasOverlay> overlays;
  final Function(CanvasElement element)? onElementTapped;
  final Function()? onCanvasTapped;
  final bool Function()? canInteract;

  const ChaosCanvas({
    Key? key,
    required this.controller,
    required this.floatAnimation,
    this.overlays = const [],
    this.onElementTapped,
    this.onCanvasTapped,
    this.canInteract,
  }) : super(key: key);

  @override
  State<ChaosCanvas> createState() => _ChaosCanvasState();
}

class _ChaosCanvasState extends State<ChaosCanvas> {
  Offset _panOffset = Offset.zero;
  String? _draggedId;
  Offset? _dragStartPosition;
  Offset _dragOffset = Offset.zero;
  //TODO: Implement? double? _dragStartRotation;
  bool get _canInteract => widget.canInteract?.call() ?? true;

  @override
  void initState() {
    super.initState();
    // Initialize local pan offset from controller
    _panOffset = widget.controller.panOffset;

    // Listen for controller updates
    widget.controller.addListener(_syncPanOffset);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncPanOffset);
    super.dispose();
  }

  void _syncPanOffset() {
    // Only sync if not currently dragging (to avoid fighting user input)
    if (_draggedId == null && !widget.controller.editMode) {
      setState(() {
        _panOffset = widget.controller.panOffset;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.controller, widget.floatAnimation]),
      builder: (context, child) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapUp: _canInteract
              ? (details) {
                  if (!widget.controller.editMode) {
                    _handleCanvasTap(details.localPosition);
                  }
                }
              : null,
          onLongPressStart: _canInteract
              ? (details) {
                  if (!widget.controller.editMode) {
                    _handleLongPressOnCanvas(details);
                  }
                }
              : null,
          onPanUpdate: _canInteract
              ? (details) {
                  if (!widget.controller.editMode || _draggedId == null) {
                    final screenSize = MediaQuery.of(context).size;
                    setState(() {
                      _panOffset += details.delta;
                      _panOffset = Offset(
                        _panOffset.dx.clamp(
                          -(widget.controller.canvasSize.width -
                              screenSize.width),
                          0.0,
                        ),
                        _panOffset.dy.clamp(
                          -(widget.controller.canvasSize.height -
                              screenSize.height),
                          0.0,
                        ),
                      );
                    });
                  }
                }
              : null,
          onPanEnd: _canInteract
              ? (details) {
                  if (_draggedId == null) {
                    widget.controller.setPanOffset(_panOffset);
                  }
                }
              : null,
          child: Stack(
            children: [
              // Render canvas
              CustomPaint(
                size: Size.infinite,
                painter: CanvasPainter(
                  elements: widget.controller.elements,
                  floatingNumbers: widget.controller.floatingNumbers,
                  animationValue: widget.floatAnimation.value,
                  panOffset: _panOffset,
                  selectedId: widget.controller.selectedId,
                  editMode: widget.controller.editMode,
                  draggedId: _draggedId,
                  canvasSize: widget.controller.canvasSize,
                ),
              ),

              // Render overlays
              ...widget.overlays.map((overlay) => overlay.build(context)),

              // Interaction layer - only in edit mode
              ..._buildInteractionLayer(),

              // Edit mode overlay
              if (widget.controller.editMode) _buildEditModeOverlay(),
            ],
          ),
        );
      },
    );
  }

  void _handleCanvasTap(Offset tapPosition) {
    for (var i = 0; i < widget.controller.elements.length; i++) {
      final element = widget.controller.elements[i];
      if (element.isHidden) continue;

      final floatOffset = _calculateFloatOffset(element);
      final elementPosition = element.position + _panOffset + floatOffset;

      // Create a TextPainter to get actual bounds
      final textPainter = TextPainter(
        text: TextSpan(
          text: element.title,
          style: TextStyle(
            fontSize: element.fontSize,
            fontWeight: element.fontWeight,
            letterSpacing: element.letterSpacing,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Get text bounds (accounting for rotation)
      final textWidth = textPainter.width;
      final textHeight = textPainter.height;

      // Transform tap position to element's local coordinate system
      final dx = tapPosition.dx - elementPosition.dx;
      final dy = tapPosition.dy - elementPosition.dy;

      // Rotate tap position inverse to element rotation
      final cos = math.cos(-element.rotation);
      final sin = math.sin(-element.rotation);
      final localX = dx * cos - dy * sin;
      final localY = dx * sin + dy * cos;

      // Check if tap is within text bounds (with some padding)
      const padding = 10.0;
      if (localX >= -textWidth / 2 - padding &&
          localX <= textWidth / 2 + padding &&
          localY >= -textHeight / 2 - padding &&
          localY <= textHeight / 2 + padding) {
        widget.onElementTapped?.call(element);
        HapticFeedback.mediumImpact();
        return;
      }
    }

    // No hit
    widget.onCanvasTapped?.call();
  }

  List<Widget> _buildInteractionLayer() {
    if (!widget.controller.editMode) {
      return [];
    }

    return [
      Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: (details) => _handleEditModeTap(details.localPosition),
          onLongPressStart: (details) =>
              _handleEditModeLongPress(details.localPosition),
          onPanStart: (details) =>
              _handleEditModePanStart(details.localPosition),
          onPanUpdate: _handleEditModePanUpdate,
          onPanEnd: _handleEditModePanEnd,
          child: const SizedBox.expand(),
        ),
      ),
    ];
  }

  String? _findElementAtPosition(Offset position,
      {bool includeHidden = false}) {
    final allElements = widget.controller.allElements.reversed.toList();

    for (var element in allElements) {
      if (!includeHidden && element.isHidden) {
        continue; // Skip hidden only if not in edit mode
      }

      final floatOffset = _calculateFloatOffset(element);
      final elementPosition = element.position + _panOffset + floatOffset;

      final textPainter = TextPainter(
        text: TextSpan(
          text: element.title,
          style: TextStyle(
            fontSize: element.fontSize,
            fontWeight: element.fontWeight,
            letterSpacing: element.letterSpacing,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final textWidth = textPainter.width;
      final textHeight = textPainter.height;

      final dx = position.dx - elementPosition.dx;
      final dy = position.dy - elementPosition.dy;

      final cos = math.cos(-element.rotation);
      final sin = math.sin(-element.rotation);
      final localX = dx * cos - dy * sin;
      final localY = dx * sin + dy * cos;

      const padding = 10.0;
      if (localX >= -textWidth / 2 - padding &&
          localX <= textWidth / 2 + padding &&
          localY >= -textHeight / 2 - padding &&
          localY <= textHeight / 2 + padding) {
        return element.id;
      }
    }

    return null;
  }

  Offset _calculateFloatOffset(CanvasElement element) {
    if (element.id == _draggedId) return Offset.zero;
    final index = widget.controller.allElements.indexOf(element);
    final floatOffset =
        math.sin(widget.floatAnimation.value * 2 * math.pi + index) * 8;
    return Offset(0, floatOffset);
  }

  void _handleEditModeTap(Offset position) {
    final hitId = _findElementAtPosition(position, includeHidden: true);
    if (hitId != null) {
      widget.controller.selectElement(hitId);
      HapticFeedback.mediumImpact();
    } else {
      widget.controller.selectElement(null);
    }
  }

  void _handleEditModeLongPress(Offset position) {
    final hitId = _findElementAtPosition(position, includeHidden: true);
    if (hitId != null) {
      widget.controller.selectElement(hitId);
      HapticFeedback.heavyImpact();
    }
  }

  void _handleEditModePanStart(Offset position) {
    final hitId = _findElementAtPosition(position, includeHidden: true);
    if (hitId != null) {
      // Dragging an element
      final element =
          widget.controller.allElements.firstWhere((e) => e.id == hitId);
      final floatOffset = _calculateFloatOffset(element);
      final elementPosition = element.position + _panOffset + floatOffset;

      setState(() {
        _draggedId = hitId;
        _dragStartPosition = element.position;
        _dragOffset = Offset(
          position.dx - elementPosition.dx,
          position.dy - elementPosition.dy,
        );
      });
    } else {
      // Panning the canvas - no element hit
      setState(() {
        _draggedId = null; // Explicitly null means we're panning
      });
    }
  }

  void _handleEditModePanUpdate(DragUpdateDetails details) {
    if (_draggedId != null && _dragStartPosition != null) {
      final element =
          widget.controller.allElements.firstWhere((e) => e.id == _draggedId);
      final floatOffset = _calculateFloatOffset(element);

      final newPosition = Offset(
        details.localPosition.dx -
            _panOffset.dx -
            floatOffset.dx -
            _dragOffset.dx,
        details.localPosition.dy -
            _panOffset.dy -
            floatOffset.dy -
            _dragOffset.dy,
      );

      // Get accurate bounds using TextPainter
      final textPainter = TextPainter(
        text: TextSpan(
          text: element.title,
          style: TextStyle(
            fontSize: element.fontSize,
            fontWeight: element.fontWeight,
            letterSpacing: element.letterSpacing,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Calculate rotated bounding box dimensions
      final textWidth = textPainter.width;
      final textHeight = textPainter.height;

      // Account for rotation - calculate the axis-aligned bounding box
      final cosAbs = math.cos(element.rotation).abs();
      final sinAbs = math.sin(element.rotation).abs();
      final rotatedWidth = (textWidth * cosAbs + textHeight * sinAbs) / 2;
      final rotatedHeight = (textWidth * sinAbs + textHeight * cosAbs) / 2;

      // Clamp to drag bounds with rotation-aware dimensions
      final bounds = widget.controller.dragBounds;
      final clampedPosition = Offset(
        newPosition.dx.clamp(
          bounds.left + rotatedWidth,
          bounds.right - rotatedWidth,
        ),
        newPosition.dy.clamp(
          bounds.top + rotatedHeight,
          bounds.bottom - rotatedHeight,
        ),
      );

      widget.controller.updateElement(_draggedId!, position: clampedPosition);
    } else {
      final screenSize = MediaQuery.of(context).size;
      setState(() {
        _panOffset += details.delta;
        _panOffset = Offset(
          _panOffset.dx.clamp(
            -(widget.controller.canvasSize.width - screenSize.width),
            0.0,
          ),
          _panOffset.dy.clamp(
            -(widget.controller.canvasSize.height - screenSize.height),
            0.0,
          ),
        );
      });
    }
  }

  void _handleEditModePanEnd(DragEndDetails details) {
    if (_draggedId == null) {
      // Was panning - sync to controller
      widget.controller.setPanOffset(_panOffset);
    }

    setState(() {
      _draggedId = null;
      _dragStartPosition = null;
      _dragOffset = Offset.zero;
    });
  }

  void _handleLongPressOnCanvas(LongPressStartDetails details) {
    widget.controller.toggleEditMode();
    HapticFeedback.heavyImpact();
  }

  Widget _buildEditModeOverlay() {
    return SafeArea(
      child: Stack(
        children: [
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Done button
                GestureDetector(
                  onTap: _canInteract
                      ? () {
                          widget.controller.setEditMode(false);
                          HapticFeedback.mediumImpact();
                        }
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9B483),
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: const Text(
                      'DONE',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),

                // Control panel for selected element
                if (widget.controller.selectedId != null)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C0C0C).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ELEMENT CONTROLS',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Hide/Show button
                        GestureDetector(
                          onTap: () {
                            final element = widget.controller.allElements
                                .firstWhere((e) =>
                                    e.id == widget.controller.selectedId);
                            widget.controller.updateElement(
                              element.id,
                              isHidden: !element.isHidden,
                            );
                            HapticFeedback.lightImpact();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.controller.allElements
                                          .firstWhere((e) =>
                                              e.id ==
                                              widget.controller.selectedId)
                                          .isHidden
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.controller.allElements
                                          .firstWhere((e) =>
                                              e.id ==
                                              widget.controller.selectedId)
                                          .isHidden
                                      ? 'SHOW'
                                      : 'HIDE',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Rotation controls
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                final element = widget.controller.allElements
                                    .firstWhere((e) =>
                                        e.id == widget.controller.selectedId);
                                widget.controller.updateElement(
                                  element.id,
                                  rotation:
                                      element.rotation - (15 * math.pi / 180),
                                );
                                HapticFeedback.lightImpact();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: const Icon(
                                  Icons.rotate_left,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                final element = widget.controller.allElements
                                    .firstWhere((e) =>
                                        e.id == widget.controller.selectedId);
                                widget.controller.updateElement(
                                  element.id,
                                  rotation:
                                      element.rotation + (15 * math.pi / 180),
                                );
                                HapticFeedback.lightImpact();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: const Icon(
                                  Icons.rotate_right,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                final element = widget.controller.allElements
                                    .firstWhere((e) =>
                                        e.id == widget.controller.selectedId);
                                widget.controller.updateElement(
                                  element.id,
                                  rotation: 0,
                                );
                                HapticFeedback.lightImpact();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: const Text(
                                  'RESET',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
