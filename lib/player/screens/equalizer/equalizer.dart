import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/state/audio_preferences.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/widgets/ui/antiiq_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_round_slider/flutter_round_slider.dart';

class Equalizer extends StatefulWidget {
  const Equalizer({super.key});

  @override
  State<Equalizer> createState() => _EqualizerState();
}

class _EqualizerState extends State<Equalizer> {
  bool _eqEnabled = false;

  AudioPreferences get _preferences => antiiqState.audioSetup.preferences;

  @override
  void initState() {
    super.initState();
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

  Future<void> _setEqEnabled(bool enabled) async {
    setState(() => _eqEnabled = enabled);
    await _preferences.setEqualizerEnabled(enabled);
    await _preferences.setBands();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AntiiQTheme.of(context);
    final audioPlayer = antiiqState.audioSetup.audioHandler.audioPlayer;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                StreamBuilder<double>(
                  stream: audioPlayer.speedStream,
                  builder: (context, snapshot) {
                    final double speed = snapshot.data ?? audioPlayer.speed;
                    final normalizedSpeed = ((speed - 0.5) / 1.0).clamp(
                      0.0,
                      1.0,
                    );
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GestureDetector(
                          onDoubleTap: () {
                            audioPlayer.setSpeed(1.0);
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Speed",
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${speed.toStringAsFixed(1)}x",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onBackground,
                                    ),
                                  ),
                                ],
                              ),
                              RoundSlider(
                                style: RoundSliderStyle(
                                  visibleFactor: 1,
                                  lineStroke: 5,
                                  borderStroke: 5,
                                  lineLengths: const [5, 10, 25],
                                  radius: 70,
                                  friction: 2,
                                  borderColor: theme.colorScheme.secondary,
                                  lineColor: speed == 1.0
                                      ? theme.colorScheme.primary
                                      : Colors.white,
                                ),
                                value: normalizedSpeed,
                                onChanged: (value) {
                                  audioPlayer.setSpeed(0.5 + value);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                StreamBuilder<double>(
                  stream: audioPlayer.pitchStream,
                  builder: (context, snapshot) {
                    final double pitchValue =
                        snapshot.data ?? audioPlayer.pitch;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GestureDetector(
                          onDoubleTap: () {
                            audioPlayer.setPitch(1.0);
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Pitch",
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${(pitchValue * 100).round()}%",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onBackground,
                                    ),
                                  ),
                                ],
                              ),
                              RoundSlider(
                                style: RoundSliderStyle(
                                  visibleFactor: 1,
                                  lineStroke: 5,
                                  borderStroke: 5,
                                  lineLengths: const [5, 10, 25],
                                  radius: 70,
                                  friction: 2,
                                  borderColor: theme.colorScheme.secondary,
                                  lineColor: pitchValue == 1.0
                                      ? theme.colorScheme.primary
                                      : Colors.white,
                                ),
                                value: pitchValue / 2,
                                onChanged: (value) {
                                  audioPlayer.setPitch(
                                    value == 0.0 ? 0.5 : value * 2,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: theme.colorScheme.background.withValues(alpha: 0.26),
              borderRadius: BorderRadius.circular(generalRadius),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.45),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "Equalizer",
                    style: TextStyle(
                      color: theme.colorScheme.onBackground,
                      fontSize: 16,
                    ),
                  ),
                ),
                Switch(
                  value: _eqEnabled,
                  activeThumbColor: theme.colorScheme.secondary,
                  inactiveThumbColor: theme.colorScheme.primary,
                  inactiveTrackColor:
                      theme.colorScheme.primary.withValues(alpha: 0.28),
                  onChanged: _setEqEnabled,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (int i = 0;
                      i < AudioPreferences.defaultBandFrequencies.length;
                      i++)
                    SizedBox(
                      width: 54,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3.0),
                        child: Column(
                          children: [
                            Expanded(
                              child: AntiiQSlider(
                                min: -12,
                                max: 12,
                                value: _preferences.bandGains[i],
                                activeTrackColor: theme.colorScheme.secondary,
                                inactiveTrackColor: theme.colorScheme.primary,
                                thumbColor: theme.colorScheme.onPrimary,
                                thumbWidth: 16.0,
                                thumbHeight: 30.0,
                                thumbBorderRadius: generalRadius - 6,
                                trackHeight: 20.0,
                                trackBorderRadius: generalRadius - 6,
                                orientation: Axis.vertical,
                                selectByTap: true,
                                onChangeEnd: (value) async {
                                  setState(() {
                                    _preferences.bandGains[i] = value;
                                  });
                                  await _preferences.updateBandGain(i, value);
                                },
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _labelFor(
                                AudioPreferences.defaultBandFrequencies[i],
                              ),
                              style: TextStyle(
                                color: theme.colorScheme.onBackground,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _labelFor(double frequency) {
    if (frequency >= 1000) {
      return '${(frequency / 1000).toStringAsFixed(frequency >= 10000 ? 0 : 1)}k';
    }
    return frequency.round().toString();
  }
}
