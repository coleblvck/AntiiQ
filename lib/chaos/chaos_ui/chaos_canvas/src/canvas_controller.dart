import 'dart:convert';

import 'package:antiiq/chaos/chaos_ui/chaos_canvas/models/canvas_element.dart';
import 'package:flutter/material.dart';

class CanvasController extends ChangeNotifier {
  Size _baseCanvasSize; // Original size (e.g., screenSize * 2.5)
  Size _canvasSize;
  Size get canvasSize => _canvasSize;

  final List<CanvasElement> _elements = [];
  final List<CanvasElement> _floatingNumbers = [];
  late final List<CanvasElement> defaultElements;
  late final List<CanvasElement> defaultFloatingElements;

  late Rect dragBounds;

  String? _selectedId;
  bool _editMode = false;

  double _zoomScale = 1.0;
  double get zoomScale => _zoomScale;

  CanvasController({
    required Size canvasSize,
  })  : _baseCanvasSize = canvasSize,
        _canvasSize = canvasSize {
    _updateDragBounds();
  }

  void _updateDragBounds() {
    final inset = _canvasSize.width * 0.1;
    dragBounds = Rect.fromLTRB(
      inset,
      inset,
      _canvasSize.width - inset,
      _canvasSize.height - inset,
    );
  }

  // Update base canvas size (for orientation changes, screen size changes)
  void updateBaseCanvasSize(Size newSize, {bool scaleElements = false}) {
    if (_baseCanvasSize == newSize) return;
    final oldSize = _baseCanvasSize;

    // Update base size
    _baseCanvasSize = newSize;

    // Recalculate current canvas size with current zoom
    _canvasSize = Size(
      _baseCanvasSize.width * _zoomScale,
      _baseCanvasSize.height * _zoomScale,
    );

    _updateDragBounds();

    if (scaleElements) {
      _scaleElementPositions(oldSize, _baseCanvasSize);
    }

    notifyListeners();
  }

  // Set zoom level (for pinch-to-zoom)
  void setZoomScale(double scale) {
    _zoomScale = scale.clamp(0.5, 1.0); // Min 50%, Max 300%

    // Scale canvas size with zoom
    _canvasSize = Size(
      _baseCanvasSize.width * _zoomScale,
      _baseCanvasSize.height * _zoomScale,
    );

    _updateDragBounds();
    notifyListeners();
  }

  // Zoom at a specific focal point (for pinch gesture)
  void zoomAt(double scale, Offset focalPoint) {
    final oldScale = _zoomScale;
    _zoomScale = scale.clamp(0.5, 1.0);

    // Scale canvas size
    _canvasSize = Size(
      _baseCanvasSize.width * _zoomScale,
      _baseCanvasSize.height * _zoomScale,
    );

    // Adjust pan offset so zoom happens at focal point
    final scaleDelta = _zoomScale / oldScale;
    _panOffset = focalPoint + (_panOffset - focalPoint) * scaleDelta;

    _updateDragBounds();
    notifyListeners();
  }

  void _scaleElementPositions(Size oldSize, Size newSize) {
    final scaleX = newSize.width / oldSize.width;
    final scaleY = newSize.height / oldSize.height;

    for (var i = 0; i < _elements.length; i++) {
      _elements[i] = _elements[i].copyWith(
        position: Offset(
          _elements[i].position.dx * scaleX,
          _elements[i].position.dy * scaleY,
        ),
      );
    }

    for (var i = 0; i < _floatingNumbers.length; i++) {
      _floatingNumbers[i] = _floatingNumbers[i].copyWith(
        position: Offset(
          _floatingNumbers[i].position.dx * scaleX,
          _floatingNumbers[i].position.dy * scaleY,
        ),
      );
    }

    _panOffset = Offset(
      _panOffset.dx * scaleX,
      _panOffset.dy * scaleY,
    );
  }

  Offset _panOffset = Offset.zero;
  Offset get panOffset => _panOffset;
  void setPanOffset(Offset offset) {
    _panOffset = offset;
    notifyListeners();
  }

  /// MUST BE CALLED AFTER SETTING ACTUAL CANVAS SIZE TO BE USED AND BEFORE CALLING initializeDefault OR fromJsonWithDefaults
  void setCanvasDefaults({
    required List<CanvasElement> elements,
    List<CanvasElement> floatingElements = const [],
  }) {
    defaultElements = elements;
    defaultFloatingElements = floatingElements;
  }

  List<CanvasElement> get elements => List.unmodifiable(_elements);
  List<CanvasElement> get floatingNumbers =>
      List.unmodifiable(_floatingNumbers);
  List<CanvasElement> get allElements => [..._elements, ..._floatingNumbers];
  String? get selectedId => _selectedId;
  bool get editMode => _editMode;

  void addElement(CanvasElement element, {bool isFloatingNumber = false}) {
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
      'zoomScale': _zoomScale,
    };
    return jsonEncode(data);
  }

  void fromJson(String jsonString) {
    try {
      final data = jsonDecode(jsonString);
      _elements.clear();
      _floatingNumbers.clear();

      for (var json in data['elements']) {
        _elements.add(CanvasElement.fromJson(json));
      }

      for (var json in data['floatingNumbers']) {
        _floatingNumbers.add(CanvasElement.fromJson(json));
      }

      if (data['panOffset'] != null) {
        _panOffset = Offset(
          data['panOffset']['dx'] ?? 0.0,
          data['panOffset']['dy'] ?? 0.0,
        );
      }

      if (data['zoomScale'] != null) {
        setZoomScale(data['zoomScale']);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading canvas state: $e');
    }
  }

  void fromJsonWithDefaults(String jsonString) {
    try {
      final data = jsonDecode(jsonString);
      _elements.clear();
      _floatingNumbers.clear();

      final loadedElementIds = <String>{};
      for (var json in data['elements']) {
        final element = CanvasElement.fromJson(json);
        _elements.add(element);
        loadedElementIds.add(element.id);
      }

      final loadedFloatingIds = <String>{};
      for (var json in data['floatingNumbers']) {
        final element = CanvasElement.fromJson(json);
        _floatingNumbers.add(element);
        loadedFloatingIds.add(element.id);
      }

      if (data['panOffset'] != null) {
        _panOffset = Offset(
          data['panOffset']['dx'] ?? 0.0,
          data['panOffset']['dy'] ?? 0.0,
        );
      }

      if (data['zoomScale'] != null) {
        setZoomScale(data['zoomScale']);
      }

      _mergeWithDefaults(loadedElementIds, loadedFloatingIds);

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading canvas state: $e');
    }
  }

  void _mergeWithDefaults(
      Set<String> loadedElementIds, Set<String> loadedFloatingIds) {
    for (var defaultElement in defaultElements) {
      if (!loadedElementIds.contains(defaultElement.id)) {
        _elements.add(defaultElement);
        debugPrint('Added new element: ${defaultElement.id}');
      }
    }

    for (var defaultFloat in defaultFloatingElements) {
      if (!loadedFloatingIds.contains(defaultFloat.id)) {
        _floatingNumbers.add(defaultFloat);
        debugPrint('Added new floating number: ${defaultFloat.id}');
      }
    }
  }

  void initializeDefault() {
    _elements.clear();
    _floatingNumbers.clear();

    _elements.addAll(defaultElements);
    _floatingNumbers.addAll(defaultFloatingElements);

    notifyListeners();
  }
}
