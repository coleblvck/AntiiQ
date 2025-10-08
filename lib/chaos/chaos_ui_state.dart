import 'package:antiiq/player/global_variables.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ChaosUIState extends ChangeNotifier {
  static const String _boxName = 'chaos_ui_settings';
  static const String _radiusKey = 'chaos_radius';
  static const String _canvasStateKey = 'chaos_canvas_state';
  static const String _chaosUIStatusKey = 'chaos_ui_status';

  late Box _box;
  Box get box => _box;

  bool _chaosUIStatus = false;
  bool get chaosUIStatus => _chaosUIStatus;

  String? _canvasState;
  String? get canvasState => _canvasState;

  double _chaosRadius = 2.0;
  double get chaosRadius => _chaosRadius;

  double getAdjustedRadius(double offset) {
    return (_chaosRadius - offset).clamp(0.0, _chaosRadius);
  }

  // Initialize and load from Hive
  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    _chaosUIStatus = _box.get(_chaosUIStatusKey, defaultValue: false);
    // TODO: REMOVE THIS. Temporarily set fallback for statusbar color setting
    chaosUIEnabled = _chaosUIStatus;
    _chaosRadius = _box.get(_radiusKey, defaultValue: 2.0);
    _canvasState = _box.get(_canvasStateKey);
    notifyListeners();
  }

  Future<void> setChaosUIStatus(bool status) async {
    // TODO: REMOVE THIS LINE
    chaosUIEnabled = status;
    if (_chaosUIStatus == status) return;
    _chaosUIStatus = status;
    await _box.put(_chaosUIStatusKey, status);
    notifyListeners();
  }

  Future<void> setCanvasState(String state) async {
    if (_canvasState == state) return;
    _canvasState = state;
    await _box.put(_canvasStateKey, _canvasState);
    notifyListeners();
  }

  // Update radius
  Future<void> setChaosRadius(double value) async {
    if (_chaosRadius == value) return;
    _chaosRadius = value.clamp(0.0, 16.0);
    await _box.put(_radiusKey, _chaosRadius);
    notifyListeners();
  }

  @override
  void dispose() {
    _box.close();
    super.dispose();
  }
}
