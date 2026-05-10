import 'dart:math' as math;

import 'package:antiiq/chaos/chaos_global_constants.dart';
import 'package:antiiq/chaos/chaos_ui_state.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/state/audio_preferences.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class ChaosEqualizer extends StatefulWidget {
  const ChaosEqualizer({super.key});

  @override
  State<ChaosEqualizer> createState() => _ChaosEqualizerState();
}

class _ChaosEqualizerState extends State<ChaosEqualizer>
    with TickerProviderStateMixin {
  late final AnimationController _glitchController;
  late final AnimationController _floatingController;
  bool _eqEnabled = false;

  AudioPreferences get _preferences => antiiqState.audioSetup.preferences;

  @override
  void initState() {
    super.initState();
    _glitchController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _floatingController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    _load();
  }

  Future<void> _load() async {
    final enabled = await antiiqState.store.get(
      'equalizerEnabled',
      defaultValue: false,
    );
    if (!mounted) return;
    setState(() => _eqEnabled = enabled);
  }

  @override
  void dispose() {
    _glitchController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  void _triggerGlitch() {
    HapticFeedback.mediumImpact();
    _glitchController.forward().then((_) => _glitchController.reverse());
  }

  @override
  Widget build(BuildContext context) {
    final chaosUIState = context.watch<ChaosUIState>();
    final innerRadius = chaosUIState.getAdjustedRadius(2);

    return AnimatedBuilder(
      animation: Listenable.merge([_glitchController, _floatingController]),
      builder: (context, child) {
        return Stack(
          children: [
            _buildFloatingElements(),
            Padding(
              padding: const EdgeInsets.all(chaosBasePadding),
              child: Column(
                children: [
                  _buildHeader(innerRadius),
                  const SizedBox(height: chaosBasePadding * 2),
                  _buildControlSection(innerRadius),
                  const SizedBox(height: chaosBasePadding * 2),
                  _buildEqualizerSection(innerRadius),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFloatingElements() {
    final indicators = [
      ('48kHz', 0.85, 0.1, -0.008),
      ('24bit', 0.1, 0.15, 0.012),
      ('+12dB', 0.9, 0.4, -0.015),
      ('15BAND', 0.05, 0.7, 0.008),
      ('FFMPEG', 0.78, 0.82, -0.01),
    ];

    return Positioned.fill(
      child: Stack(
        children: indicators.map((indicator) {
          final offset = math.sin(
                _floatingController.value * 2 * math.pi + indicator.$4 * 10,
              ) *
              2;
          return Positioned(
            left: MediaQuery.of(context).size.width * indicator.$2,
            top: MediaQuery.of(context).size.height * indicator.$3 + offset,
            child: Transform.rotate(
              angle: indicator.$4,
              child: Opacity(
                opacity: 0.3,
                child: Text(
                  indicator.$1,
                  style: TextStyle(
                    color: AntiiQTheme.of(context).colorScheme.secondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeader(double innerRadius) {
    final glitchOffset = _glitchController.isAnimating
        ? Offset(
            _glitchController.value * (math.Random().nextDouble() * 4 - 2),
            _glitchController.value * (math.Random().nextDouble() * 2 - 1),
          )
        : Offset.zero;

    return Transform.translate(
      offset: glitchOffset,
      child: Row(
        children: [
          Transform.rotate(
            angle: -0.02,
            child: Text(
              'AUDIO ENGINE',
              style: TextStyle(
                color: AntiiQTheme.of(context).colorScheme.onBackground,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
              ),
            ),
          ),
          const Spacer(),
          Transform.rotate(
            angle: 0.015,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AntiiQTheme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.6),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(innerRadius),
              ),
              child: Text(
                'STUDIO MODE',
                style: TextStyle(
                  color: AntiiQTheme.of(context).colorScheme.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlSection(double innerRadius) {
    final audioPlayer = antiiqState.audioSetup.audioHandler.audioPlayer;
    return Column(
      children: [
        StreamBuilder<double>(
          stream: audioPlayer.pitchStream,
          builder: (context, snapshot) {
            final pitch = snapshot.data ?? audioPlayer.pitch;
            return GestureDetector(
              onDoubleTap: () {
                audioPlayer.setPitch(1.0);
                _triggerGlitch();
              },
              child: _buildControlSlider(
                'PITCH SHIFT',
                pitch / 2,
                (value) {
                  audioPlayer.setPitch(value == 0.0 ? 0.5 : value * 2);
                  _triggerGlitch();
                },
                AntiiQTheme.of(context).colorScheme.primary,
                '${(pitch * 100).toInt()}%',
                innerRadius,
                centerValue: 0.5,
                subtitle: 'DOUBLE TAP: RESET',
              ),
            );
          },
        ),
        const SizedBox(height: chaosBasePadding),
        StreamBuilder<double>(
          stream: audioPlayer.speedStream,
          builder: (context, snapshot) {
            final speed = snapshot.data ?? audioPlayer.speed;
            final normalizedSpeed = ((speed - 0.5) / 1.0).clamp(0.0, 1.0);
            return GestureDetector(
              onDoubleTap: () {
                audioPlayer.setSpeed(1.0);
                _triggerGlitch();
              },
              child: _buildControlSlider(
                'SPEED',
                normalizedSpeed,
                (value) {
                  audioPlayer.setSpeed(0.5 + value);
                  _triggerGlitch();
                },
                AntiiQTheme.of(context).colorScheme.error,
                '${speed.toStringAsFixed(1)}x',
                innerRadius,
                centerValue: 0.5,
                subtitle: 'DBL TAP: RESET',
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildControlSlider(
    String title,
    double value,
    ValueChanged<double> onChanged,
    Color color,
    String label,
    double innerRadius, {
    double? centerValue,
    String? subtitle,
  }) {
    final clampedValue = value.clamp(0.0, 1.0);
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(
        horizontal: chaosBasePadding,
        vertical: chaosBasePadding,
      ),
      decoration: BoxDecoration(
        color: AntiiQTheme.of(context).colorScheme.background,
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
        borderRadius: BorderRadius.circular(innerRadius),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AntiiQTheme.of(context).colorScheme.onBackground,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AntiiQTheme.of(context)
                          .colorScheme
                          .onBackground
                          .withValues(alpha: 0.4),
                      fontSize: 6,
                      letterSpacing: 0.5,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapDown: (details) {
                    onChanged(
                      (details.localPosition.dx / constraints.maxWidth)
                          .clamp(0.0, 1.0),
                    );
                  },
                  onPanUpdate: (details) {
                    onChanged(
                      (details.localPosition.dx / constraints.maxWidth)
                          .clamp(0.0, 1.0),
                    );
                  },
                  child: _HorizontalRail(
                    value: clampedValue,
                    centerValue: centerValue,
                    color: color,
                    innerRadius: innerRadius,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 45,
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEqualizerSection(double innerRadius) {
    return Expanded(
      child: Column(
        children: [
          Row(
            children: [
              Transform.rotate(
                angle: -0.008,
                child: Text(
                  'FREQUENCY EQUALIZER',
                  style: TextStyle(
                    color: AntiiQTheme.of(context).colorScheme.onBackground,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const Spacer(),
              _MiniSwitch(
                value: _eqEnabled,
                innerRadius: innerRadius,
                onChanged: (value) async {
                  setState(() => _eqEnabled = value);
                  await _preferences.setEqualizerEnabled(value);
                  await _preferences.setBands();
                  _triggerGlitch();
                },
              ),
            ],
          ),
          const SizedBox(height: chaosBasePadding * 2),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(
                  AudioPreferences.defaultBandFrequencies.length,
                  (index) => SizedBox(
                    width: 48,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _buildEQBand(index, innerRadius),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEQBand(int index, double innerRadius) {
    final gain = _preferences.bandGains[index];
    final normalizedValue = ((gain + 12) / 24).clamp(0.0, 1.0);
    final color = _getEQColor(gain);

    return Column(
      children: [
        Transform.rotate(
          angle: (index % 2 == 0) ? -0.01 : 0.01,
          child: Text(
            _getBandLabel(AudioPreferences.defaultBandFrequencies[index]),
            style: TextStyle(
              color: AntiiQTheme.of(context)
                  .colorScheme
                  .onBackground
                  .withValues(alpha: 0.7),
              fontSize: 8,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final height = constraints.maxHeight;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) {
                  _setBandFromDrag(index, details.localPosition.dy, height);
                },
                onVerticalDragStart: (details) {
                  _setBandFromDrag(index, details.localPosition.dy, height);
                },
                onVerticalDragUpdate: (details) {
                  _setBandFromDrag(index, details.localPosition.dy, height);
                },
                child: _VerticalRail(
                  value: normalizedValue,
                  color: color,
                  innerRadius: innerRadius,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Transform.rotate(
          angle: (index % 3 == 0) ? -0.008 : 0.008,
          child: Text(
            gain.toStringAsFixed(1),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  void _setBandFromDrag(int index, double y, double height) {
    final normalized = (1.0 - (y / height)).clamp(0.0, 1.0);
    final gain = -12.0 + (normalized * 24.0);
    setState(() => _preferences.bandGains[index] = gain);
    _preferences.updateBandGain(index, gain);
  }

  String _getBandLabel(double frequency) {
    if (frequency < 1000) return '${frequency.toInt()}Hz';
    return '${(frequency / 1000).toStringAsFixed(1)}kHz';
  }

  Color _getEQColor(double gain) {
    if (gain > 1.0) return AntiiQTheme.of(context).colorScheme.secondary;
    if (gain < -1.0) return AntiiQTheme.of(context).colorScheme.error;
    return AntiiQTheme.of(context).colorScheme.primary;
  }
}

class _HorizontalRail extends StatelessWidget {
  const _HorizontalRail({
    required this.value,
    required this.color,
    required this.innerRadius,
    this.centerValue,
  });

  final double value;
  final double? centerValue;
  final Color color;
  final double innerRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12,
      decoration: BoxDecoration(
        color: AntiiQTheme.of(context)
            .colorScheme
            .background
            .withValues(blue: 0.06, red: 0.06, green: 0.06),
        borderRadius: BorderRadius.circular(innerRadius / 2),
        border: Border.all(
          color: AntiiQTheme.of(context)
              .colorScheme
              .onBackground
              .withValues(alpha: 0.1),
          width: 0.5,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              if (centerValue != null)
                Positioned(
                  left: centerValue! * constraints.maxWidth - 0.5,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 1,
                    color: AntiiQTheme.of(context)
                        .colorScheme
                        .onBackground
                        .withValues(alpha: 0.3),
                  ),
                ),
              FractionallySizedBox(
                widthFactor: value,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(innerRadius / 2),
                  ),
                ),
              ),
              Positioned(
                left: value * (constraints.maxWidth - 16),
                top: 2,
                child: Container(
                  width: 16,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    border: Border.all(
                      color: AntiiQTheme.of(context).colorScheme.background,
                      width: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(innerRadius / 3),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _VerticalRail extends StatelessWidget {
  const _VerticalRail({
    required this.value,
    required this.color,
    required this.innerRadius,
  });

  final double value;
  final Color color;
  final double innerRadius;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AntiiQTheme.of(context)
                .colorScheme
                .background
                .withValues(blue: 0.06, red: 0.06, green: 0.06),
            border: Border.all(
              color: AntiiQTheme.of(context)
                  .colorScheme
                  .onBackground
                  .withValues(alpha: 0.1),
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(innerRadius / 2),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: height * 0.5,
                child: Container(
                  height: 1,
                  color: AntiiQTheme.of(context)
                      .colorScheme
                      .onBackground
                      .withValues(alpha: 0.3),
                ),
              ),
              Positioned(
                left: 2,
                right: 2,
                top: (1.0 - value) * (height - 20) + 2,
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: color,
                    border: Border.all(
                      color: AntiiQTheme.of(context).colorScheme.background,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(innerRadius / 3),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MiniSwitch extends StatelessWidget {
  const _MiniSwitch({
    required this.value,
    required this.onChanged,
    required this.innerRadius,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final double innerRadius;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 32,
        height: 16,
        decoration: BoxDecoration(
          color: value
              ? AntiiQTheme.of(context).colorScheme.surface
              : AntiiQTheme.of(context).colorScheme.background,
          border: Border.all(
            color: value
                ? AntiiQTheme.of(context).colorScheme.secondary
                : AntiiQTheme.of(context)
                    .colorScheme
                    .onBackground
                    .withValues(alpha: 0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(innerRadius / 2),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 150),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: value
                  ? AntiiQTheme.of(context).colorScheme.secondary
                  : AntiiQTheme.of(context)
                      .colorScheme
                      .onBackground
                      .withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(innerRadius / 3),
            ),
          ),
        ),
      ),
    );
  }
}
