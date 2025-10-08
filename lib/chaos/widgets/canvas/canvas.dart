import 'dart:convert';
import 'package:antiiq/chaos/widgets/chaos/chaos_header.dart';
import 'package:antiiq/chaos/page_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;


class TypographyState {
  final String id;
  final String title;
  final String value;
  Offset position;
  double rotation;
  final double fontSize;
  final FontWeight fontWeight;
  final double letterSpacing;
  final Color color;
  bool isHidden;

  TypographyState({
    required this.id,
    required this.title,
    required this.value,
    required this.position,
    required this.rotation,
    required this.fontSize,
    this.fontWeight = FontWeight.w900,
    this.letterSpacing = 2,
    required this.color,
    this.isHidden = false,
  });

  TypographyState copyWith({
    Offset? position,
    double? rotation,
    bool? isHidden,
  }) {
    return TypographyState(
      id: id,
      title: title,
      value: value,
      position: position ?? this.position,
      rotation: rotation ?? this.rotation,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      color: color,
      isHidden: isHidden ?? this.isHidden,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'value': value,
        'x': position.dx,
        'y': position.dy,
        'rotation': rotation,
        'fontSize': fontSize,
        'fontWeight': fontWeight.index,
        'letterSpacing': letterSpacing,
        'color': color.value,
        'isHidden': isHidden,
      };

  factory TypographyState.fromJson(Map<String, dynamic> json) {
    return TypographyState(
      id: json['id'],
      title: json['title'],
      value: json['value'],
      position: Offset(json['x'], json['y']),
      rotation: json['rotation'],
      fontSize: json['fontSize'],
      fontWeight: FontWeight.values[json['fontWeight'] ?? 8],
      letterSpacing: json['letterSpacing'] ?? 2,
      color: Color(json['color']),
      isHidden: json['isHidden'] ?? false,
    );
  }
}

class TypographyCanvasController extends ChangeNotifier {
  final Size canvasSize;
  final List<TypographyState> _elements = [];
  final List<TypographyState> _floatingNumbers = [];

  late final Rect dragBounds;

  String? _selectedId;
  bool _editMode = false;

  TypographyCanvasController({required this.canvasSize}) {
    // Drag area is 80% of canvas, centered
    final inset = canvasSize.width * 0.1;
    dragBounds = Rect.fromLTRB(
      inset,
      inset,
      canvasSize.width - inset,
      canvasSize.height - inset,
    );
  }

  Offset _panOffset = Offset.zero;
  Offset get panOffset => _panOffset;
  void setPanOffset(Offset offset) {
    _panOffset = offset;
    notifyListeners();
  }

  List<TypographyState> get elements => List.unmodifiable(_elements);
  List<TypographyState> get floatingNumbers =>
      List.unmodifiable(_floatingNumbers);
  List<TypographyState> get allElements => [..._elements, ..._floatingNumbers];
  String? get selectedId => _selectedId;
  bool get editMode => _editMode;

  void addElement(TypographyState element, {bool isFloatingNumber = false}) {
    if (isFloatingNumber) {
      _floatingNumbers.add(element);
    } else {
      _elements.add(element);
    }
    notifyListeners();
  }

  void updateElement(String id,
      {Offset? position, double? rotation, bool? isHidden}) {
    final index = _elements.indexWhere((e) => e.id == id);
    if (index != -1) {
      _elements[index] = _elements[index].copyWith(
        position: position,
        rotation: rotation,
        isHidden: isHidden,
      );
      notifyListeners();
    }

    final floatIndex = _floatingNumbers.indexWhere((e) => e.id == id);
    if (floatIndex != -1) {
      _floatingNumbers[floatIndex] = _floatingNumbers[floatIndex].copyWith(
        position: position,
        rotation: rotation,
        isHidden: isHidden,
      );
      notifyListeners();
    }
  }

  void selectElement(String? id) {
    _selectedId = id;
    notifyListeners();
  }

  void toggleEditMode() {
    _editMode = !_editMode;
    if (!_editMode) {
      _selectedId = null;
    }
    notifyListeners();
  }

  void setEditMode(bool value) {
    _editMode = value;
    if (!_editMode) {
      _selectedId = null;
    }
    notifyListeners();
  }

  String toJson() {
    final data = {
      'elements': _elements.map((e) => e.toJson()).toList(),
      'floatingNumbers': _floatingNumbers.map((e) => e.toJson()).toList(),
      'panOffset': {'dx': _panOffset.dx, 'dy': _panOffset.dy},
    };
    return jsonEncode(data);
  }


  void fromJson(String jsonString) {
    try {
      final data = jsonDecode(jsonString);
      _elements.clear();
      _floatingNumbers.clear();

      for (var json in data['elements']) {
        _elements.add(TypographyState.fromJson(json));
      }

      for (var json in data['floatingNumbers']) {
        _floatingNumbers.add(TypographyState.fromJson(json));
      }


      if (data['panOffset'] != null) {
        _panOffset = Offset(
          data['panOffset']['dx'] ?? 0.0,
          data['panOffset']['dy'] ?? 0.0,
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading typography state: $e');
    }
  }

  // Load from JSON and merge with new defaults
  void fromJsonWithDefaults(String jsonString) {
    try {
      final data = jsonDecode(jsonString);
      _elements.clear();
      _floatingNumbers.clear();


      final loadedElementIds = <String>{};
      for (var json in data['elements']) {
        final element = TypographyState.fromJson(json);
        _elements.add(element);
        loadedElementIds.add(element.id);
      }

      final loadedFloatingIds = <String>{};
      for (var json in data['floatingNumbers']) {
        final element = TypographyState.fromJson(json);
        _floatingNumbers.add(element);
        loadedFloatingIds.add(element.id);
      }


      if (data['panOffset'] != null) {
        _panOffset = Offset(
          data['panOffset']['dx'] ?? 0.0,
          data['panOffset']['dy'] ?? 0.0,
        );
      }


      _mergeWithDefaults(loadedElementIds, loadedFloatingIds);

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading typography state: $e');
    }
  }

  void _mergeWithDefaults(
      Set<String> loadedElementIds, Set<String> loadedFloatingIds) {
    // Create default elements to compare against
    final defaultElements = _createDefaultElements();
    final defaultFloatingNumbers = _createDefaultFloatingNumbers();

    // Add missing main elements
    for (var defaultElement in defaultElements) {
      if (!loadedElementIds.contains(defaultElement.id)) {
        _elements.add(defaultElement);
        debugPrint('Added new element: ${defaultElement.id}');
      }
    }

    // Add missing floating numbers
    for (var defaultFloat in defaultFloatingNumbers) {
      if (!loadedFloatingIds.contains(defaultFloat.id)) {
        _floatingNumbers.add(defaultFloat);
        debugPrint('Added new floating number: ${defaultFloat.id}');
      }
    }
  }

  List<TypographyState> _createDefaultElements() {
    return [
      TypographyState(
        id: 'songs',
        title: 'SONGS',
        value: '1247',
        position: Offset(canvasSize.width * 0.40, canvasSize.height * 0.38),
        rotation: -12 * math.pi / 180,
        fontSize: 72,
        color: Colors.white,
      ),
      TypographyState(
        id: 'albums',
        title: 'ALBUMS',
        value: '89',
        position: Offset(canvasSize.width * 0.60, canvasSize.height * 0.40),
        rotation: 45 * math.pi / 180,
        fontSize: 64,
        color: const Color(0xFFD9B483),
      ),
      TypographyState(
        id: 'artists',
        title: 'ARTISTS',
        value: '156',
        position: Offset(canvasSize.width * 0.35, canvasSize.height * 0.45),
        rotation: -8 * math.pi / 180,
        fontSize: 68,
        color: const Color(0xFF8BA785),
      ),
      TypographyState(
        id: 'genres',
        title: 'GENRES',
        value: '23',
        position: Offset(canvasSize.width * 0.60, canvasSize.height * 0.48),
        rotation: 22 * math.pi / 180,
        fontSize: 56,
        color: Colors.red,
      ),
      TypographyState(
        id: 'playlists',
        title: 'PLAYLISTS',
        value: '12',
        position: Offset(canvasSize.width * 0.36, canvasSize.height * 0.52),
        rotation: -35 * math.pi / 180,
        fontSize: 48,
        color: Colors.blue,
      ),
      TypographyState(
        id: 'favourites',
        title: 'FAVOURITES',
        value: '78',
        position: Offset(canvasSize.width * 0.58, canvasSize.height * 0.54),
        rotation: 15 * math.pi / 180,
        fontSize: 52,
        color: Colors.pink,
      ),
      TypographyState(
        id: 'history',
        title: 'HISTORY',
        value: '456',
        position: Offset(canvasSize.width * 0.64, canvasSize.height * 0.60),
        rotation: -18 * math.pi / 180,
        fontSize: 60,
        color: Colors.orange,
      ),
      TypographyState(
        id: 'smartmix',
        title: 'SMART MIX',
        value: '∞',
        position: Offset(canvasSize.width * 0.40, canvasSize.height * 0.59),
        rotation: 8 * math.pi / 180,
        fontSize: 60,
        color: Colors.purple,
      ),
      TypographyState(
        id: 'selection',
        title: 'SELECTION',
        value: '∞',
        position: Offset(canvasSize.width * 0.48, canvasSize.height * 0.65),
        rotation: -4 * math.pi / 180,
        fontSize: 56,
        color: Colors.deepOrange,
      ),
    ];
  }

  List<TypographyState> _createDefaultFloatingNumbers() {
    return [
      TypographyState(
        id: 'float_1',
        title: '1247',
        value: '1247',
        position: Offset(canvasSize.width * 0.78, canvasSize.height * 0.34),
        rotation: -5 * math.pi / 180,
        fontSize: 28,
        color: const Color(0xFFD9B483).withValues(alpha: 0.7),
        fontWeight: FontWeight.w100,
        letterSpacing: 1,
      ),
      TypographyState(
        id: 'float_2',
        title: '89',
        value: '89',
        position: Offset(canvasSize.width * 0.26, canvasSize.height * 0.43),
        rotation: 12 * math.pi / 180,
        fontSize: 28,
        color: Colors.white.withValues(alpha: 0.6),
        fontWeight: FontWeight.w100,
        letterSpacing: 1,
      ),
      TypographyState(
        id: 'float_3',
        title: '156',
        value: '156',
        position: Offset(canvasSize.width * 0.74, canvasSize.height * 0.56),
        rotation: -8 * math.pi / 180,
        fontSize: 28,
        color: const Color(0xFF8BA785).withValues(alpha: 0.7),
        fontWeight: FontWeight.w100,
        letterSpacing: 1,
      ),

      TypographyState(
        id: 'float_4',
        title: '23',
        value: '23',
        position: Offset(canvasSize.width * 0.48, canvasSize.height * 0.36),
        rotation: 18 * math.pi / 180,
        fontSize: 24,
        color: Colors.red.withValues(alpha: 0.5),
        fontWeight: FontWeight.w100,
        letterSpacing: 1,
      ),
      TypographyState(
        id: 'float_5',
        title: '12',
        value: '12',
        position: Offset(canvasSize.width * 0.68, canvasSize.height * 0.44),
        rotation: -15 * math.pi / 180,
        fontSize: 26,
        color: Colors.blue.withValues(alpha: 0.6),
        fontWeight: FontWeight.w100,
        letterSpacing: 1,
      ),
      TypographyState(
        id: 'float_6',
        title: '78',
        value: '78',
        position: Offset(canvasSize.width * 0.30, canvasSize.height * 0.50),
        rotation: 8 * math.pi / 180,
        fontSize: 25,
        color: Colors.pink.withValues(alpha: 0.55),
        fontWeight: FontWeight.w100,
        letterSpacing: 1,
      ),
      TypographyState(
        id: 'float_7',
        title: '456',
        value: '456',
        position: Offset(canvasSize.width * 0.70, canvasSize.height * 0.64),
        rotation: -12 * math.pi / 180,
        fontSize: 27,
        color: Colors.orange.withValues(alpha: 0.6),
        fontWeight: FontWeight.w100,
        letterSpacing: 1,
      ),
      TypographyState(
        id: 'float_8',
        title: '∞',
        value: '∞',
        position: Offset(canvasSize.width * 0.50, canvasSize.height * 0.63),
        rotation: 20 * math.pi / 180,
        fontSize: 30,
        color: Colors.purple.withValues(alpha: 0.5),
        fontWeight: FontWeight.w100,
        letterSpacing: 1,
      ),
      TypographyState(
        id: 'float_9',
        title: '1247',
        value: '1247',
        position: Offset(canvasSize.width * 0.24, canvasSize.height * 0.58),
        rotation: -6 * math.pi / 180,
        fontSize: 22,
        color: Colors.white.withValues(alpha: 0.4),
        fontWeight: FontWeight.w100,
        letterSpacing: 1,
      ),
      TypographyState(
        id: 'float_10',
        title: '89',
        value: '89',
        position: Offset(canvasSize.width * 0.82, canvasSize.height * 0.48),
        rotation: 14 * math.pi / 180,
        fontSize: 23,
        color: const Color(0xFFD9B483).withValues(alpha: 0.55),
        fontWeight: FontWeight.w100,
        letterSpacing: 1,
      ),
    ];
  }


  void initializeDefault() {
    _elements.clear();
    _floatingNumbers.clear();


    _elements.addAll(_createDefaultElements());
    _floatingNumbers.addAll(_createDefaultFloatingNumbers());

    notifyListeners();
  }
}


class TypographyCanvas extends StatefulWidget {
  final ChaosPageManagerController pageManagerController;
  final TypographyCanvasController controller;
  final AnimationController floatAnimation;
  final Function(String id)? onElementTapped;
  final Function()? onCanvasTapped;
  final bool Function()? canInteract;

  const TypographyCanvas({
    Key? key,
    required this.pageManagerController,
    required this.controller,
    required this.floatAnimation,
    this.onElementTapped,
    this.onCanvasTapped,
    this.canInteract,
  }) : super(key: key);

  @override
  State<TypographyCanvas> createState() => _TypographyCanvasState();
}

class _TypographyCanvasState extends State<TypographyCanvas> {
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
                painter: _TypographyCanvasPainter(
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

              ChaosHeader(
                pageManagerController: widget.pageManagerController,
              ),

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
        widget.onElementTapped?.call(element.id);
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

  Offset _calculateFloatOffset(TypographyState element) {
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

// Custom painter for the canvas
class _TypographyCanvasPainter extends CustomPainter {
  final List<TypographyState> elements;
  final List<TypographyState> floatingNumbers;
  final double animationValue;
  final Offset panOffset;
  final String? selectedId;
  final bool editMode;
  final String? draggedId;
  final Size canvasSize;

  _TypographyCanvasPainter({
    required this.elements,
    required this.floatingNumbers,
    required this.animationValue,
    required this.panOffset,
    this.selectedId,
    required this.editMode,
    this.draggedId,
    required this.canvasSize,
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
      // Adjust for pan offset to keep boundary visible
      // Use the same bounds from controller
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

    // Draw dashed border
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
      Canvas canvas, TypographyState element, int index, bool isFloating) {
    canvas.save();

    // Calculate float animation
    final isDragged = element.id == draggedId;

    // Calculate float animation (freeze if being dragged)
    final floatOffset =
        isDragged ? 0.0 : math.sin(animationValue * 2 * math.pi + index) * 8;
    final verticalDrift = isFloating && !isDragged
        ? math.cos(animationValue * 2 * math.pi + index * 0.8) * 15
        : 0.0;

    // Apply position with animation
    final x = element.position.dx + panOffset.dx;
    final y = element.position.dy + floatOffset + verticalDrift + panOffset.dy;

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

    // Create text painter
    final textPainter = TextPainter(
      text: TextSpan(
        text: element.title,
        style: TextStyle(
          color: element.color.withValues(alpha: isSelected ? 1.0 : opacity),
          fontSize: isFloating ? element.fontSize : element.fontSize,
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

  void _paintSelectionIndicators(Canvas canvas, TypographyState element) {
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
  bool shouldRepaint(_TypographyCanvasPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.panOffset != panOffset ||
        oldDelegate.selectedId != selectedId ||
        oldDelegate.editMode != editMode ||
        oldDelegate.draggedId != draggedId ||
        oldDelegate.elements != elements ||
        oldDelegate.floatingNumbers != floatingNumbers;
  }
}
