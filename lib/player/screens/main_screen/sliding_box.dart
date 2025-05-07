import 'package:flutter/material.dart';

class AntiiQBoxController {
  bool isBoxClosed = true;
  final List<VoidCallback> _listeners = [];

  void closeBox() {
    isBoxClosed = true;
    _notifyListeners();
  }

  void openBox() {
    isBoxClosed = false;
    _notifyListeners();
  }

  void toggleBox() {
    isBoxClosed = !isBoxClosed;
    _notifyListeners();
  }

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  void dispose() {
    _listeners.clear();
  }
}

class AntiiQSlidingBox extends StatefulWidget {
  final Widget body;
  final Widget collapsedBody;
  final Widget backdrop;
  final AntiiQBoxController controller;
  final double minHeight;
  final double maxHeight;
  final BorderRadius borderRadius;
  final Color color;
  final Color draggableIconColor;
  final bool draggable;
  final bool showDragHandle;
  final VoidCallback? onBoxOpen;
  final VoidCallback? onBoxClose;
  final Duration animationDuration;

  const AntiiQSlidingBox({
    super.key,
    required this.body,
    required this.collapsedBody,
    required this.backdrop,
    required this.controller,
    required this.minHeight,
    required this.maxHeight,
    required this.borderRadius,
    required this.color,
    required this.draggableIconColor,
    this.draggable = true,
    this.showDragHandle = false,
    this.onBoxOpen,
    this.onBoxClose,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<AntiiQSlidingBox> createState() => _AntiiQSlidingBoxState();
}

class _AntiiQSlidingBoxState extends State<AntiiQSlidingBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _heightAnimation;
  late double _dragStartY;
  late double _draggableHeight;
  bool _isDragging = false;
  double _currentMinHeight = 0;
  double _currentMaxHeight = 0;

  @override
  void initState() {
    super.initState();
    _currentMinHeight = widget.minHeight;
    _currentMaxHeight = widget.maxHeight;
    
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    
    _updateAnimation();
    _handleControllerUpdate();
    widget.controller.addListener(_handleControllerUpdate);
  }

  void _updateAnimation() {
    _heightAnimation = Tween<double>(
      begin: _currentMinHeight,
      end: _currentMaxHeight,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(AntiiQSlidingBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check if min or max height has changed
    if (widget.minHeight != _currentMinHeight || widget.maxHeight != _currentMaxHeight) {
      _currentMinHeight = widget.minHeight;
      _currentMaxHeight = widget.maxHeight;
      
      // Update the animation with new values
      _updateAnimation();
    }
    
    // Handle controller listener changes
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerUpdate);
      widget.controller.addListener(_handleControllerUpdate);
      _handleControllerUpdate();
    }
    
    // Handle animation duration changes
    if (oldWidget.animationDuration != widget.animationDuration) {
      _controller.duration = widget.animationDuration;
    }
  }

  void _handleControllerUpdate() {
    if (widget.controller.isBoxClosed) {
      _controller.reverse();
      widget.onBoxClose?.call();
    } else {
      _controller.forward();
      widget.onBoxOpen?.call();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    widget.controller.removeListener(_handleControllerUpdate);
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    if (!widget.draggable) return;
    _isDragging = true;
    _dragStartY = details.globalPosition.dy;
    _draggableHeight = _heightAnimation.value;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!widget.draggable || !_isDragging) return;
    final newHeight = _draggableHeight - (details.globalPosition.dy - _dragStartY);
    final heightPercent = (newHeight - _currentMinHeight) / (_currentMaxHeight - _currentMinHeight);
    _controller.value = heightPercent.clamp(0.0, 1.0);
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!widget.draggable) return;
    _isDragging = false;
    if (_controller.value > 0.5) {
      _controller.forward();
      widget.controller.isBoxClosed = false;
      widget.onBoxOpen?.call();
    } else {
      _controller.reverse();
      widget.controller.isBoxClosed = true;
      widget.onBoxClose?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            widget.backdrop,
            AnimatedBuilder(
              animation: _heightAnimation,
              builder: (context, child) {
                return Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: _heightAnimation.value,
                  child: GestureDetector(
                    onVerticalDragStart: _handleDragStart,
                    onVerticalDragUpdate: _handleDragUpdate,
                    onVerticalDragEnd: _handleDragEnd,
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.color,
                        borderRadius: widget.borderRadius,
                      ),
                      child: Column(
                        children: [
                          if (widget.draggable && widget.showDragHandle)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: widget.draggableIconColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          Expanded(
                            child: _controller.value > 0.5
                                ? widget.body
                                : widget.collapsedBody,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}