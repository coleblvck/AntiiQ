import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum AntiiQSurfacePreset { solid, smoke, frost, glass }

extension AntiiQSurfacePresetDetails on AntiiQSurfacePreset {
  String get label => name.toUpperCase();

  double get opacity => switch (this) {
        AntiiQSurfacePreset.solid => 1.0,
        AntiiQSurfacePreset.smoke => 0.78,
        AntiiQSurfacePreset.frost => 0.62,
        AntiiQSurfacePreset.glass => 0.38,
      };

  double get blur => switch (this) {
        AntiiQSurfacePreset.solid => 0.0,
        AntiiQSurfacePreset.smoke => 0.0,
        AntiiQSurfacePreset.frost => 16.0,
        AntiiQSurfacePreset.glass => 24.0,
      };

  double get tint => switch (this) {
        AntiiQSurfacePreset.solid => 0.02,
        AntiiQSurfacePreset.smoke => 0.08,
        AntiiQSurfacePreset.frost => 0.14,
        AntiiQSurfacePreset.glass => 0.2,
      };

  double get border => switch (this) {
        AntiiQSurfacePreset.solid => 0.24,
        AntiiQSurfacePreset.smoke => 0.32,
        AntiiQSurfacePreset.frost => 0.44,
        AntiiQSurfacePreset.glass => 0.56,
      };

  double get backdrop => switch (this) {
        AntiiQSurfacePreset.solid => 0.06,
        AntiiQSurfacePreset.smoke => 0.12,
        AntiiQSurfacePreset.frost => 0.16,
        AntiiQSurfacePreset.glass => 0.22,
      };
}

@immutable
class AntiiQSurfaceStyle {
  const AntiiQSurfaceStyle({
    required this.opacity,
    required this.blur,
    required this.tint,
    required this.border,
  });

  final double opacity;
  final double blur;
  final double tint;
  final double border;

  @override
  bool operator ==(Object other) =>
      other is AntiiQSurfaceStyle &&
      opacity == other.opacity &&
      blur == other.blur &&
      tint == other.tint &&
      border == other.border;

  @override
  int get hashCode => Object.hash(opacity, blur, tint, border);
}

class ChaosUIState extends ChangeNotifier {
  static const String _boxName = 'chaos_ui_settings';
  static const String _radiusKey = 'chaos_radius';
  static const String _canvasStateKey = 'chaos_canvas_state';
  static const String _chaosLevelKey = 'chaos_level';
  static const String _canvasEnabledKey = 'canvas_enabled';
  static const String _dashboardOrderKey = 'chaos_dashboard_order';
  static const String _coverArtThemeKey = 'cover_art_theme';
  static const String _surfacePresetKey = 'surface_preset';
  static const String _surfaceOpacityKey = 'surface_opacity';
  static const String _surfaceBlurKey = 'surface_blur';
  static const String _surfaceTintKey = 'surface_tint';
  static const String _surfaceBorderKey = 'surface_border';
  static const String _backdropIntensityKey = 'backdrop_intensity';
  static const String _reduceTransparencyKey = 'reduce_transparency';

  late Box _box;
  Timer? _surfaceSaveTimer;
  Box get box => _box;

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

  AntiiQSurfacePreset _surfacePreset = AntiiQSurfacePreset.smoke;
  AntiiQSurfacePreset get surfacePreset => _surfacePreset;

  double _surfaceOpacity = AntiiQSurfacePreset.smoke.opacity;
  double get surfaceOpacity => _reduceTransparency ? 0.96 : _surfaceOpacity;

  double _surfaceBlur = AntiiQSurfacePreset.smoke.blur;
  double get surfaceBlur => _reduceTransparency ? 0 : _surfaceBlur;

  double _surfaceTint = AntiiQSurfacePreset.smoke.tint;
  double get surfaceTint => _surfaceTint;

  double _surfaceBorder = AntiiQSurfacePreset.smoke.border;
  double get surfaceBorder => _surfaceBorder;

  double _backdropIntensity = AntiiQSurfacePreset.smoke.backdrop;
  double get backdropIntensity => _backdropIntensity;

  bool _reduceTransparency = false;
  bool get reduceTransparency => _reduceTransparency;

  AntiiQSurfaceStyle get surfaceStyle => AntiiQSurfaceStyle(
        opacity: surfaceOpacity,
        blur: surfaceBlur,
        tint: surfaceTint,
        border: surfaceBorder,
      );

  bool get isSurfacePresetCustomized =>
      (_surfaceOpacity - _surfacePreset.opacity).abs() > .001 ||
      (_surfaceBlur - _surfacePreset.blur).abs() > .001 ||
      (_surfaceTint - _surfacePreset.tint).abs() > .001 ||
      (_surfaceBorder - _surfacePreset.border).abs() > .001 ||
      (_backdropIntensity - _surfacePreset.backdrop).abs() > .001;

  String get surfaceStyleLabel =>
      isSurfacePresetCustomized ? 'CUSTOM' : surfacePreset.label;

  Future<void> setSurfacePreset(AntiiQSurfacePreset preset) async {
    _surfacePreset = preset;
    _surfaceOpacity = preset.opacity;
    _surfaceBlur = preset.blur;
    _surfaceTint = preset.tint;
    _surfaceBorder = preset.border;
    _backdropIntensity = preset.backdrop;
    await _box.putAll({
      _surfacePresetKey: preset.name,
      _surfaceOpacityKey: _surfaceOpacity,
      _surfaceBlurKey: _surfaceBlur,
      _surfaceTintKey: _surfaceTint,
      _surfaceBorderKey: _surfaceBorder,
      _backdropIntensityKey: _backdropIntensity,
    });
    notifyListeners();
  }

  void setSurfaceOpacity(double value) {
    _surfaceOpacity = value.clamp(0.22, 1.0);
    _scheduleSurfaceSave();
    notifyListeners();
  }

  void setSurfaceBlur(double value) {
    _surfaceBlur = value.clamp(0.0, 28.0);
    _scheduleSurfaceSave();
    notifyListeners();
  }

  void setSurfaceTint(double value) {
    _surfaceTint = value.clamp(0.0, 0.35);
    _scheduleSurfaceSave();
    notifyListeners();
  }

  void setSurfaceBorder(double value) {
    _surfaceBorder = value.clamp(0.08, 0.8);
    _scheduleSurfaceSave();
    notifyListeners();
  }

  void setBackdropIntensity(double value) {
    _backdropIntensity = value.clamp(0.0, 0.32);
    _scheduleSurfaceSave();
    notifyListeners();
  }

  void _scheduleSurfaceSave() {
    _surfaceSaveTimer?.cancel();
    _surfaceSaveTimer = Timer(const Duration(milliseconds: 140), () {
      _box.putAll({
        _surfaceOpacityKey: _surfaceOpacity,
        _surfaceBlurKey: _surfaceBlur,
        _surfaceTintKey: _surfaceTint,
        _surfaceBorderKey: _surfaceBorder,
        _backdropIntensityKey: _backdropIntensity,
      });
    });
  }

  Future<void> setReduceTransparency(bool value) async {
    _reduceTransparency = value;
    await _box.put(_reduceTransparencyKey, value);
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
    final presetName = _box.get(_surfacePresetKey,
        defaultValue: AntiiQSurfacePreset.smoke.name) as String;
    _surfacePreset = AntiiQSurfacePreset.values.firstWhere(
      (preset) => preset.name == presetName,
      orElse: () => AntiiQSurfacePreset.smoke,
    );
    _surfaceOpacity = (_box.get(_surfaceOpacityKey,
            defaultValue: _surfacePreset.opacity) as num)
        .toDouble();
    _surfaceBlur =
        (_box.get(_surfaceBlurKey, defaultValue: _surfacePreset.blur) as num)
            .toDouble();
    _surfaceTint =
        (_box.get(_surfaceTintKey, defaultValue: _surfacePreset.tint) as num)
            .toDouble();
    _surfaceBorder = (_box.get(_surfaceBorderKey,
            defaultValue: _surfacePreset.border) as num)
        .toDouble();
    _backdropIntensity = (_box.get(_backdropIntensityKey,
            defaultValue: _surfacePreset.backdrop) as num)
        .toDouble();
    _reduceTransparency =
        _box.get(_reduceTransparencyKey, defaultValue: false) as bool;
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
    _surfaceSaveTimer?.cancel();
    _box.close();
    super.dispose();
  }
}
