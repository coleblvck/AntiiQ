import 'dart:convert';
import 'dart:math' as math;

import 'package:antiiq/chaos/chaos_ui/chaos_canvas/models/canvas_element.dart';
import 'package:flutter/material.dart';

class CanvasController extends ChangeNotifier {
  final Size canvasSize;
  final List<CanvasElement> _elements = [];
  final List<CanvasElement> _floatingNumbers = [];

  late final Rect dragBounds;

  String? _selectedId;
  bool _editMode = false;

  CanvasController({required this.canvasSize}) {
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

  List<CanvasElement> _createDefaultElements() {
    return [
      CanvasElement(
        id: 'songs',
        title: 'SONGS',
        value: '1247',
        position: Offset(canvasSize.width * 0.40, canvasSize.height * 0.38),
        rotation: -12 * math.pi / 180,
        fontSize: 72,
        color: Colors.white,
      ),
      CanvasElement(
        id: 'albums',
        title: 'ALBUMS',
        value: '89',
        position: Offset(canvasSize.width * 0.60, canvasSize.height * 0.40),
        rotation: 45 * math.pi / 180,
        fontSize: 64,
        color: const Color(0xFFD9B483),
      ),
      CanvasElement(
        id: 'artists',
        title: 'ARTISTS',
        value: '156',
        position: Offset(canvasSize.width * 0.35, canvasSize.height * 0.45),
        rotation: -8 * math.pi / 180,
        fontSize: 68,
        color: const Color(0xFF8BA785),
      ),
      CanvasElement(
        id: 'genres',
        title: 'GENRES',
        value: '23',
        position: Offset(canvasSize.width * 0.60, canvasSize.height * 0.48),
        rotation: 22 * math.pi / 180,
        fontSize: 56,
        color: Colors.red,
      ),
      CanvasElement(
        id: 'playlists',
        title: 'PLAYLISTS',
        value: '12',
        position: Offset(canvasSize.width * 0.36, canvasSize.height * 0.52),
        rotation: -35 * math.pi / 180,
        fontSize: 48,
        color: Colors.blue,
      ),
      CanvasElement(
        id: 'favourites',
        title: 'FAVOURITES',
        value: '78',
        position: Offset(canvasSize.width * 0.58, canvasSize.height * 0.54),
        rotation: 15 * math.pi / 180,
        fontSize: 52,
        color: Colors.pink,
      ),
      CanvasElement(
        id: 'history',
        title: 'HISTORY',
        value: '456',
        position: Offset(canvasSize.width * 0.64, canvasSize.height * 0.60),
        rotation: -18 * math.pi / 180,
        fontSize: 60,
        color: Colors.orange,
      ),
      CanvasElement(
        id: 'smartmix',
        title: 'SMART MIX',
        value: '∞',
        position: Offset(canvasSize.width * 0.40, canvasSize.height * 0.59),
        rotation: 8 * math.pi / 180,
        fontSize: 60,
        color: Colors.purple,
      ),
      CanvasElement(
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

  List<CanvasElement> _createDefaultFloatingNumbers() {
    return [
      CanvasElement(
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
      CanvasElement(
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
      CanvasElement(
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
      CanvasElement(
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
      CanvasElement(
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
      CanvasElement(
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
      CanvasElement(
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
      CanvasElement(
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
      CanvasElement(
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
      CanvasElement(
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
