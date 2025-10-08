import 'package:flutter/material.dart';
import 'dart:math' as math;

class ChaosAnimationManager {
  final TickerProvider vsync;
  late AnimationController _floatController;
  late AnimationController _glitchController;
  late AnimationController _playerExpandController;

  // Single Random instance for all glitch calculations
  final math.Random _random = math.Random();

  // Cache glitch offsets to avoid recalculating every frame
  Offset _currentGlitchOffset = Offset.zero;
  bool _glitchOffsetsNeedUpdate = true;

  AnimationController get floatController => _floatController;
  AnimationController get glitchController => _glitchController;
  AnimationController get playerExpandController => _playerExpandController;

  // Expose the random instance for consistent glitch effects
  math.Random get random => _random;

  ChaosAnimationManager({required this.vsync}) {
    _initializeControllers();
  }

  void _initializeControllers() {
    _floatController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: vsync,
    )..repeat();

    _glitchController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: vsync,
    );

    // Update glitch offsets when glitch animation changes
    _glitchController.addListener(_updateGlitchOffsets);

    _playerExpandController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: vsync,
    );
  }

  void _updateGlitchOffsets() {
    _glitchOffsetsNeedUpdate = true;
  }

  /// Get cached glitch offset with specified intensity
  /// This prevents creating new Random instances on every frame
  Offset getGlitchOffset(double intensityX, double intensityY) {
    if (_glitchOffsetsNeedUpdate && _glitchController.isAnimating) {
      _currentGlitchOffset = Offset(
        _glitchController.value * (_random.nextDouble() * intensityX - intensityX / 2),
        _glitchController.value * (_random.nextDouble() * intensityY - intensityY / 2),
      );
      _glitchOffsetsNeedUpdate = false;
    } else if (!_glitchController.isAnimating) {
      _currentGlitchOffset = Offset.zero;
    }
    return _currentGlitchOffset;
  }

  /// Get glitch offset with default intensity
  Offset getDefaultGlitchOffset() => getGlitchOffset(6.0, 4.0);

  /// Get smaller glitch offset for subtle effects
  Offset getSubtleGlitchOffset() => getGlitchOffset(2.0, 1.0);

  void triggerGlitch() {
    _glitchOffsetsNeedUpdate = true;
    _glitchController.reset();
    _glitchController.forward();
  }

  void expandPlayer() => _playerExpandController.forward();
  void collapsePlayer() => _playerExpandController.reverse();

  void togglePlayer(bool isExpanded) {
    if (isExpanded) {
      expandPlayer();
    } else {
      collapsePlayer();
    }
  }

  void dispose() {
    _glitchController.removeListener(_updateGlitchOffsets);
    _floatController.dispose();
    _glitchController.dispose();
    _playerExpandController.dispose();
  }
}