import 'package:flutter/material.dart';
import 'dart:async';

class AntiiQBoxController {
  bool isBoxClosed = true;
  bool isCollapsedBodyVisible = true;
  final List<VoidCallback> _listeners = [];
  
  final StreamController<bool> _stateStreamController = StreamController<bool>.broadcast();
  final StreamController<bool> _visibilityStreamController = StreamController<bool>.broadcast();
  
  Stream<bool> get stateStream => _stateStreamController.stream;
  Stream<bool> get visibilityStream => _visibilityStreamController.stream;
  
  AntiiQBoxController() {
    _stateStreamController.add(isBoxClosed);
    _visibilityStreamController.add(isCollapsedBodyVisible);
  }

  void closeBox() {
    isBoxClosed = true;
    isCollapsedBodyVisible = true;
    _notifyListeners();
    _stateStreamController.add(isBoxClosed);
    _visibilityStreamController.add(isCollapsedBodyVisible);
  }

  void openBox() {
    isBoxClosed = false;
    isCollapsedBodyVisible = false;
    _notifyListeners();
    _stateStreamController.add(isBoxClosed);
    _visibilityStreamController.add(isCollapsedBodyVisible);
  }

  void toggleBox() {
    isBoxClosed = !isBoxClosed;
    isCollapsedBodyVisible = isBoxClosed;
    _notifyListeners();
    _stateStreamController.add(isBoxClosed);
    _visibilityStreamController.add(isCollapsedBodyVisible);
  }

  void updateVisibility(bool isCollapsed) {
    isCollapsedBodyVisible = isCollapsed;
    _visibilityStreamController.add(isCollapsedBodyVisible);
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
    _stateStreamController.close();
    _visibilityStreamController.close();
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
  StreamSubscription? _stateStreamSubscription;
  StreamSubscription? _visibilityStreamSubscription;
  bool _isCollapsedBodyVisible = true;

  @override
  void initState() {
    super.initState();
    _currentMinHeight = widget.minHeight;
    _currentMaxHeight = widget.maxHeight;
    _isCollapsedBodyVisible = widget.controller.isCollapsedBodyVisible;
    
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    
    _updateAnimation();
    _handleControllerUpdate();
    widget.controller.addListener(_handleControllerUpdate);
    
    _controller.addListener(_handleAnimationChanged);
    
    _stateStreamSubscription = widget.controller.stateStream.listen(_handleStateChange);
    _visibilityStreamSubscription = widget.controller.visibilityStream.listen(_handleVisibilityChange);
  }

  void _handleAnimationChanged() {
    final isCollapsed = _controller.value <= 0.5;
    if (_isCollapsedBodyVisible != isCollapsed) {
      _isCollapsedBodyVisible = isCollapsed;
      widget.controller.updateVisibility(isCollapsed);
    }
  }

  void _handleStateChange(bool isBoxClosed) {
    if (isBoxClosed) {
      _controller.reverse();
      widget.onBoxClose?.call();
    } else {
      _controller.forward();
      widget.onBoxOpen?.call();
    }
  }

  void _handleVisibilityChange(bool isCollapsedVisible) {
    _isCollapsedBodyVisible = isCollapsedVisible;
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
    
    if (widget.minHeight != _currentMinHeight || widget.maxHeight != _currentMaxHeight) {
      _currentMinHeight = widget.minHeight;
      _currentMaxHeight = widget.maxHeight;
      _updateAnimation();
    }
    
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerUpdate);
      widget.controller.addListener(_handleControllerUpdate);
      _handleControllerUpdate();
      
      _stateStreamSubscription?.cancel();
      _visibilityStreamSubscription?.cancel();
      _stateStreamSubscription = widget.controller.stateStream.listen(_handleStateChange);
      _visibilityStreamSubscription = widget.controller.visibilityStream.listen(_handleVisibilityChange);
    }
    
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
    _controller.removeListener(_handleAnimationChanged);
    _controller.dispose();
    widget.controller.removeListener(_handleControllerUpdate);
    _stateStreamSubscription?.cancel();
    _visibilityStreamSubscription?.cancel();
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
      widget.controller.openBox();
      widget.onBoxOpen?.call();
    } else {
      _controller.reverse();
      widget.controller.closeBox();
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