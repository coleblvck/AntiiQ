import 'package:antiiq/chaos/chaos_global_constants.dart';
import 'package:antiiq/chaos/chaos_ui_state.dart';
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

class ChaosEqualizer extends StatefulWidget {
  const ChaosEqualizer({super.key});

  @override
  State<ChaosEqualizer> createState() => _ChaosEqualizerState();
}

class _ChaosEqualizerState extends State<ChaosEqualizer>
    with TickerProviderStateMixin {
  late AnimationController _glitchController;
  late AnimationController _floatingController;

  final AndroidEqualizer equalizer = globalAntiiqAudioHandler.equalizer;
  final AndroidLoudnessEnhancer loudnessEnhancer = globalAntiiqAudioHandler.loudnessEnhancer;
  final AudioPlayer audioPlayer = globalAntiiqAudioHandler.audioPlayer;

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
    final radius = chaosUIState.chaosRadius;
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
                  _buildHeader(radius, innerRadius),
                  const SizedBox(height: chaosBasePadding * 2),
                  _buildControlSection(radius, innerRadius),
                  const SizedBox(height: chaosBasePadding * 2),
                  _buildEqualizerSection(radius, innerRadius),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFloatingElements() {
    return Positioned.fill(
      child: Stack(
        children: _buildFloatingIndicators(),
      ),
    );
  }

  List<Widget> _buildFloatingIndicators() {
    final indicators = [
      ('48kHz', 0.85, 0.1, -0.008),
      ('24bit', 0.1, 0.15, 0.012),
      ('∞dB', 0.9, 0.4, -0.015),
      ('±12dB', 0.05, 0.7, 0.008),
      ('THD+N', 0.8, 0.8, -0.01),
    ];

    return indicators.map((indicator) {
      final offset = math.sin(
              _floatingController.value * 2 * math.pi + indicator.$4 * 10) * 2;
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
    }).toList();
  }

  Widget _buildHeader(double radius, double innerRadius) {
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
                  color: AntiiQTheme.of(context).colorScheme.primary.withValues(alpha: 0.6),
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

  Widget _buildControlSection(double radius, double innerRadius) {
    return Column(
      children: [
        _buildGainSlider(radius, innerRadius),
        const SizedBox(height: chaosBasePadding),
        _buildPitchSlider(radius, innerRadius),
        const SizedBox(height: chaosBasePadding),
        _buildSpeedSlider(radius, innerRadius),
      ],
    );
  }

  Widget _buildGainSlider(double radius, double innerRadius) {
    return StreamBuilder<double>(
      stream: loudnessEnhancer.targetGainStream,
      builder: (context, gainSnapshot) {
        final targetGain = gainSnapshot.data ?? 0.0;
        return StreamBuilder<bool>(
          stream: loudnessEnhancer.enabledStream,
          builder: (context, enabledSnapshot) {
            final enabled = enabledSnapshot.data ?? false;
            return _buildControlSlider(
              'GAIN BOOST',
              targetGain,
              (value) {
                loudnessEnhancer.setTargetGain(value);
                _triggerGlitch();
              },
              AntiiQTheme.of(context).colorScheme.secondary,
              '${(targetGain * 30).toInt()}dB',
              radius,
              innerRadius,
              hasSwitch: true,
              switchValue: enabled,
              onSwitchChanged: (value) {
                loudnessEnhancer.setEnabled(value);
                _triggerGlitch();
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPitchSlider(double radius, double innerRadius) {
    return StreamBuilder<double>(
      stream: audioPlayer.pitchStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final pitchValue = snapshot.data!;
        return GestureDetector(
          onDoubleTap: () {
            audioPlayer.setPitch(1.0);
            _triggerGlitch();
          },
          child: _buildControlSlider(
            'PITCH SHIFT',
            pitchValue / 2,
            (value) {
              audioPlayer.setPitch(value != 0.0 ? value * 2 : 0.02);
              _triggerGlitch();
            },
            AntiiQTheme.of(context).colorScheme.primary,
            '${(pitchValue * 100).toInt()}%',
            radius,
            innerRadius,
            centerValue: 0.5,
            subtitle: 'DOUBLE TAP: RESET',
          ),
        );
      },
    );
  }

  Widget _buildSpeedSlider(double radius, double innerRadius) {
    return StreamBuilder<double>(
      stream: audioPlayer.speedStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final speed = snapshot.data!;
        final normalizedSpeed = (speed - 0.5) / 1.5;
        return GestureDetector(
          onDoubleTap: () {
            audioPlayer.setSpeed(1.0);
            _triggerGlitch();
          },
          child: _buildControlSlider(
            'SPEED',
            normalizedSpeed,
            (value) {
              audioPlayer.setSpeed(0.5 + (value * 1.5));
              _triggerGlitch();
            },
            AntiiQTheme.of(context).colorScheme.error,
            '${speed.toStringAsFixed(1)}x',
            radius,
            innerRadius,
            centerValue: 0.33,
            subtitle: 'DBL TAP: RESET',
          ),
        );
      },
    );
  }

  Widget _buildControlSlider(
    String title,
    double value,
    Function(double) onChanged,
    Color color,
    String label,
    double radius,
    double innerRadius, {
    bool hasSwitch = false,
    bool switchValue = false,
    Function(bool)? onSwitchChanged,
    double? centerValue,
    String? subtitle,
  }) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: chaosBasePadding, vertical: chaosBasePadding),
      decoration: BoxDecoration(
        color: AntiiQTheme.of(context).colorScheme.background,
        border: Border.all(
          color: (hasSwitch && !switchValue)
              ? AntiiQTheme.of(context).colorScheme.onBackground.withValues(alpha: 0.2)
              : color.withValues(alpha: 0.4),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(innerRadius),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 85,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.rotate(
                  angle: -0.008,
                  child: Text(
                    title,
                    style: TextStyle(
                      color: (hasSwitch && !switchValue)
                          ? AntiiQTheme.of(context).colorScheme.onBackground.withValues(alpha: 0.5)
                          : AntiiQTheme.of(context).colorScheme.onBackground,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (subtitle != null)
                  Transform.rotate(
                    angle: 0.005,
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        color: AntiiQTheme.of(context).colorScheme.onBackground.withValues(alpha: 0.4),
                        fontSize: 6,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                  onPanUpdate: (details) {
                    if (hasSwitch && !switchValue) return;
                    final newValue = (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
                    onChanged(newValue);
                  },
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: AntiiQTheme.of(context).colorScheme.background.withValues(blue: 0.06, red: 0.06, green: 0.06),
                      borderRadius: BorderRadius.circular(innerRadius / 2),
                      border: Border.all(
                        color: AntiiQTheme.of(context).colorScheme.onBackground.withValues(alpha: 0.1),
                        width: 0.5,
                      ),
                    ),
                    child: Stack(
                      children: [
                        if (centerValue != null)
                          Positioned(
                            left: centerValue * constraints.maxWidth - 0.5,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 1,
                              color: AntiiQTheme.of(context).colorScheme.onBackground.withValues(alpha: 0.3),
                            ),
                          ),
                        FractionallySizedBox(
                          widthFactor: value,
                          child: Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: (hasSwitch && !switchValue)
                                  ? AntiiQTheme.of(context).colorScheme.onBackground.withValues(alpha: 0.2)
                                  : color,
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
                              color: (hasSwitch && !switchValue)
                                  ? AntiiQTheme.of(context).colorScheme.onBackground.withValues(alpha: 0.4)
                                  : color,
                              borderRadius: BorderRadius.circular(innerRadius / 3),
                              border: Border.all(
                                color: AntiiQTheme.of(context).colorScheme.background,
                                width: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: hasSwitch ? 70 : 45,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: (hasSwitch && !switchValue)
                          ? AntiiQTheme.of(context).colorScheme.onBackground.withValues(alpha: 0.4)
                          : color,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasSwitch) ...[
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 32,
                    height: 16,
                    child: _buildToggleSwitch(switchValue, onSwitchChanged!, innerRadius),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSwitch(bool value, Function(bool) onChanged, double innerRadius) {
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
                : AntiiQTheme.of(context).colorScheme.onBackground.withValues(alpha: 0.3),
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
                  : AntiiQTheme.of(context).colorScheme.onBackground.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(innerRadius / 3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEqualizerSection(double radius, double innerRadius) {
    return StreamBuilder<bool>(
      stream: equalizer.enabledStream,
      builder: (context, enabledSnapshot) {
        final enabled = enabledSnapshot.data ?? false;
        return Flexible(
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
                  _buildToggleSwitch(enabled, (value) {
                    antiiqState.audioSetup.preferences.setEqualizerEnabled(value);
                    _triggerGlitch();
                  }, innerRadius),
                ],
              ),
              const SizedBox(height: chaosBasePadding * 2),
              Flexible(
                child: FutureBuilder<AndroidEqualizerParameters>(
                  future: equalizer.parameters,
                  builder: (context, snapshot) {
                    final parameters = snapshot.data;
                    if (parameters == null) {
                      return Center(
                        child: Text(
                          'EQUALIZER NOT AVAILABLE',
                          style: TextStyle(
                            color: AntiiQTheme.of(context).colorScheme.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: List.generate(parameters.bands.length, (index) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: _buildEQBand(parameters.bands[index], parameters, index, innerRadius),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEQBand(AndroidEqualizerBand band, AndroidEqualizerParameters parameters, int index, double innerRadius) {
    return StreamBuilder<double>(
      stream: band.gainStream,
      builder: (context, snapshot) {
        final gain = snapshot.data ?? 0.0;
        final normalizedValue = (gain - parameters.minDecibels) / (parameters.maxDecibels - parameters.minDecibels);
        final label = _getBandLabel(band.centerFrequency);

        return Column(
          children: [
            Transform.rotate(
              angle: (index % 2 == 0) ? -0.01 : 0.01,
              child: Text(
                label,
                style: TextStyle(
                  color: AntiiQTheme.of(context).colorScheme.onBackground.withValues(alpha: 0.7),
                  fontSize: 8,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _buildVerticalSlider(
                normalizedValue,
                (newValue) {
                  final newGain = parameters.minDecibels + (newValue * (parameters.maxDecibels - parameters.minDecibels));
                  band.setGain(newGain);
                  antiiqState.audioSetup.preferences.saveBandFrequencies();
                  _triggerGlitch();
                },
                _getEQColor(gain, parameters),
                innerRadius,
              ),
            ),
            const SizedBox(height: 8),
            Transform.rotate(
              angle: (index % 3 == 0) ? -0.008 : 0.008,
              child: Text(
                gain.toStringAsFixed(1),
                style: TextStyle(
                  color: _getEQColor(gain, parameters),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getBandLabel(double frequency) {
    if (frequency < 1000) {
      return '${frequency.toInt()}Hz';
    } else if (frequency < 1000000) {
      return '${(frequency / 1000).toStringAsFixed(1)}kHz';
    } else {
      return '${(frequency / 1000000).toStringAsFixed(1)}MHz';
    }
  }

  Color _getEQColor(double gain, AndroidEqualizerParameters parameters) {
    final normalizedGain = gain / parameters.maxDecibels;
    if (normalizedGain > 0.1) {
      return AntiiQTheme.of(context).colorScheme.secondary;
    }
    if (normalizedGain < -0.1) {
      return AntiiQTheme.of(context).colorScheme.error;
    }
    return AntiiQTheme.of(context).colorScheme.primary;
  }

  Widget _buildVerticalSlider(double value, Function(double) onChanged, Color color, double innerRadius) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        return GestureDetector(
          onPanUpdate: (details) {
            final newValue = 1.0 - (details.localPosition.dy / height);
            onChanged(newValue.clamp(0.0, 1.0));
          },
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AntiiQTheme.of(context).colorScheme.background.withValues(blue: 0.06, red: 0.06, green: 0.06),
              border: Border.all(
                color: AntiiQTheme.of(context).colorScheme.onBackground.withValues(alpha: 0.1),
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
                    color: AntiiQTheme.of(context).colorScheme.onBackground.withValues(alpha: 0.3),
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
          ),
        );
      },
    );
  }
}