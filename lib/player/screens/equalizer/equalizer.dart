import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/widgets/ui/antiiq_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_round_slider/flutter_round_slider.dart';
import 'package:just_audio/just_audio.dart';

class Equalizer extends StatefulWidget {
  const Equalizer({
    super.key,
  });

  @override
  State<Equalizer> createState() => _EqualizerState();
}

class _EqualizerState extends State<Equalizer> {
  final AndroidEqualizer equalizer = audioHandler.equalizer;
  final AndroidLoudnessEnhancer loudnessEnhancer =
      audioHandler.loudnessEnhancer;
  final AudioPlayer audioPlayer = audioHandler.audioPlayer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      StreamBuilder<double>(
                          stream: loudnessEnhancer.targetGainStream,
                          builder: (context, snapshot) {
                            final targetGain = snapshot.data ?? 0.0;
                            return RoundSlider(
                              style: RoundSliderStyle(
                                visibleFactor: 1,
                                radius: 70,
                                stepLineCount: 30,
                                glowDistance: 100,
                                borderColor: targetGain == 0.0
                                    ? AntiiQTheme.of(context)
                                        .colorScheme
                                        .primary
                                    : Colors.white,
                                lineColor: AntiiQTheme.of(context)
                                    .colorScheme
                                    .secondary,
                              ),
                              value: targetGain,
                              onChanged: (value) {
                                setState(() {
                                  loudnessEnhancer.setTargetGain(value);
                                });
                              },
                            );
                          }),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Gain!",
                            style: TextStyle(
                              fontSize: 20,
                              color:
                                  AntiiQTheme.of(context).colorScheme.secondary,
                            ),
                          ),
                          StreamBuilder<bool>(
                              stream: loudnessEnhancer.enabledStream,
                              builder: (context, snapshot) {
                                final bool enabled = snapshot.data ?? false;
                                return Switch(
                                  activeTrackColor: AntiiQTheme.of(context)
                                      .colorScheme
                                      .primary,
                                  activeColor: AntiiQTheme.of(context)
                                      .colorScheme
                                      .onPrimary,
                                  value: enabled,
                                  onChanged: (value) {
                                    loudnessEnhancer.setEnabled(value);
                                  },
                                );
                              })
                        ],
                      ),
                    ],
                  ),
                ),
                StreamBuilder<double>(
                    stream: audioPlayer.pitchStream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Text("Unavailable");
                      }
                      final double pitchValue = snapshot.data!;
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
                                Text(
                                  "Pitch",
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: AntiiQTheme.of(context)
                                        .colorScheme
                                        .primary,
                                  ),
                                ),
                                RoundSlider(
                                  style: RoundSliderStyle(
                                    visibleFactor: 1,
                                    lineStroke: 5,
                                    borderStroke: 5,
                                    lineLengths: [5, 10, 25],
                                    radius: 70,
                                    friction: 2,
                                    borderColor: AntiiQTheme.of(context)
                                        .colorScheme
                                        .secondary,
                                    lineColor: pitchValue == 1.0
                                        ? AntiiQTheme.of(context)
                                            .colorScheme
                                            .primary
                                        : Colors.white,
                                  ),
                                  value: pitchValue / 2,
                                  onChanged: (value) {
                                    if (value != 0.0) {
                                      audioPlayer.setPitch(value * 2);
                                    } else {
                                      audioPlayer.setPitch(0.02);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
              ],
            ),
          ),
          SizedBox(
            height: 40, // Increased to accommodate larger track height
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: CustomButton(
                    style: AntiiQTheme.of(context).buttonStyles.style3,
                    function: () {
                      audioPlayer.setSpeed(1.0);
                    },
                    child: const Text(
                      "Speed:",
                    ),
                  ),
                ),
                StreamBuilder<double>(
                    stream: audioPlayer.speedStream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Text("Unavailable");
                      }
                      double speed = snapshot.data!;
                      return Expanded(
                        child: AntiiQSlider(
                          min: 10,
                          max: 30,
                          value: speed * 20,
                          activeTrackColor:
                              AntiiQTheme.of(context).colorScheme.secondary,
                          inactiveTrackColor:
                              AntiiQTheme.of(context).colorScheme.primary,
                          thumbColor: speed == 1.0
                              ? AntiiQTheme.of(context).colorScheme.onPrimary
                              : Colors.white,
                          thumbWidth: 30.0,
                          thumbHeight: 16.0,
                          thumbBorderRadius: generalRadius / 2,
                          trackHeight:
                              20.0,
                          trackBorderRadius: generalRadius - 6,
                          orientation: Axis.horizontal,
                          selectByTap: true,
                          onChangeEnd: (value) {
                            audioPlayer.setSpeed(value / 20);
                          },
                        ),
                      );
                    }),
              ],
            ),
          ),
          StreamBuilder<bool>(
            stream: equalizer.enabledStream,
            builder: (context, snapshot) {
              final enabled = snapshot.data ?? false;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "EQ",
                        style: TextStyle(
                          fontSize: 20,
                          color: AntiiQTheme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                    Switch(
                      activeTrackColor:
                          AntiiQTheme.of(context).colorScheme.primary,
                      activeColor:
                          AntiiQTheme.of(context).colorScheme.onPrimary,
                      value: enabled,
                      onChanged: (value) {
                        antiiqState.audioSetup.preferences
                            .setEqualizerEnabled(value);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: FutureBuilder<AndroidEqualizerParameters>(
              future: equalizer.parameters,
              builder: (context, snapshot) {
                final parameters = snapshot.data;

                if (parameters == null) {
                  return const Center(
                    child: Text("Equalizer not available"),
                  );
                }
                return Row(
                  children: [
                    for (var band in parameters.bands)
                      StreamBuilder<double>(
                        stream: band.gainStream,
                        builder: (context, snapshot) {
                          final double gain = snapshot.data ?? 0.0;
                          final double minValue = parameters.minDecibels * 100;
                          final double maxValue = parameters.maxDecibels * 100;

                          return Expanded(
                            child: AntiiQSlider(
                              min: minValue,
                              max: maxValue,
                              value: gain * 100,
                              activeTrackColor:
                                  AntiiQTheme.of(context).colorScheme.secondary,
                              inactiveTrackColor:
                                  AntiiQTheme.of(context).colorScheme.primary,
                              thumbColor:
                                  AntiiQTheme.of(context).colorScheme.onPrimary,
                              thumbWidth: 16.0,
                              thumbHeight: 30.0,
                              thumbBorderRadius: generalRadius - 6,
                              trackHeight: 20.0,
                              trackBorderRadius: generalRadius - 6,
                              orientation: Axis.vertical,
                              selectByTap: true,
                              onChangeEnd: (value) {
                                band.setGain(value / 100);
                                antiiqState.audioSetup.preferences
                                    .saveBandFrequencies();
                              },
                            ),
                          );
                        },
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
