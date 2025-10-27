import 'package:antiiq/player/global_variables.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ChaosUIState extends ChangeNotifier {
  static const String _boxName = 'chaos_ui_settings';
  static const String _radiusKey = 'chaos_radius';
  static const String _canvasStateKey = 'chaos_canvas_state';
  static const String _chaosUIStatusKey = 'chaos_ui_status';
  static const String _chaosLevelKey = 'chaos_level';
  static const String _canvasEnabledKey = 'canvas_enabled';
  static const String _dashboardOrderKey = 'chaos_dashboard_order';
  static const String _coverArtThemeKey = 'cover_art_theme';

  late Box _box;
  Box get box => _box;

  bool _chaosUIStatus = false;
  bool get chaosUIStatus => _chaosUIStatus;

  double _chaosLevel = 0.0;
  double get chaosLevel => _chaosLevel;
  Future<void> setChaosLevel(double value) async {
    _chaosLevel = value.clamp(0.0, 1.0);
    await _box.put(_chaosLevelKey, _chaosLevel);
    notifyListeners();
  }

  bool _canvasEnabled = false;
  bool get canvasEnabled => _canvasEnabled;
  Future<void> setCanvasEnabled(bool value) async {
    _canvasEnabled = value;
    await _box.put(_canvasEnabledKey, _canvasEnabled);
    notifyListeners();
  }

  List<String> _dashboardOrder = [];
  List<String> get dashboardOrder => _dashboardOrder;

  Future<void> setDashboardOrder(List<String> order) async {
    if (listEquals(_dashboardOrder, order)) return;
    _dashboardOrder = order;
    await _box.put(_dashboardOrderKey, order);
    notifyListeners();
  }

  bool _coverArtTheme = false;
  bool get coverArtTheme => _coverArtTheme;
  Future<void> setCoverArtTheme(bool value) async {
    if (_coverArtTheme == value) return;
    _coverArtTheme = value;
    await _box.put(_coverArtThemeKey, _coverArtTheme);
    notifyListeners();
  }

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
    _chaosLevel = _box.get(_chaosLevelKey, defaultValue: 0.0);
    _canvasEnabled = _box.get(_canvasEnabledKey, defaultValue: false);

    _dashboardOrder = (_box.get(_dashboardOrderKey) as List?)?.cast<String>() ??
        [
          'songs',
          'albums',
          'artists',
          'genres',
          'playlists',
          'smartmix',
          'favourites',
          'history',
          'selection'
        ];
    _coverArtTheme = _box.get(_coverArtThemeKey, defaultValue: false);
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
