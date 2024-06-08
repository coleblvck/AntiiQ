import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/audio_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_round_slider/flutter_round_slider.dart';
import 'package:flutter_xlider/flutter_xlider.dart';
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
    return Column(
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
                                  ? AntiiQTheme.of(context).colorScheme.primary
                                  : Colors.white,
                              lineColor:
                                  AntiiQTheme.of(context).colorScheme.secondary,
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
                            color: AntiiQTheme.of(context).colorScheme.secondary,
                          ),
                        ),
                        StreamBuilder<bool>(
                            stream: loudnessEnhancer.enabledStream,
                            builder: (context, snapshot) {
                              final bool enabled = snapshot.data ?? false;
                              return Switch(
                                activeTrackColor:
                                AntiiQTheme.of(context).colorScheme.primary,
                                activeColor:
                                AntiiQTheme.of(context).colorScheme.onPrimary,
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
                                  color: AntiiQTheme.of(context).colorScheme.primary,
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
                                  borderColor:
                                      AntiiQTheme.of(context).colorScheme.secondary,
                                  lineColor: pitchValue == 1.0
                                      ? AntiiQTheme.of(context).colorScheme.primary
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
          height: 25,
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
                      child: FlutterSlider(
                        tooltip: FlutterSliderTooltip(
                          disabled: true,
                        ),
                        handlerHeight: 15,
                        handlerWidth: 30,
                        selectByTap: true,
                        axis: Axis.horizontal,
                        rtl: false,
                        values: [speed * 20],
                        min: 10,
                        max: 30,
                        handler: FlutterSliderHandler(
                          decoration: BoxDecoration(
                              color: speed == 1.0
                                  ? AntiiQTheme.of(context).colorScheme.primary
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(generalRadius/2)),
                          child: Container(),
                        ),
                        foregroundDecoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(generalRadius)),
                        trackBar: FlutterSliderTrackBar(
                          inactiveTrackBar: BoxDecoration(
                            borderRadius: BorderRadius.circular(generalRadius),
                            color: AntiiQTheme.of(context).colorScheme.secondary,
                            border: Border.all(
                              width: 3,
                              color: AntiiQTheme.of(context).colorScheme.secondary,
                            ),
                          ),
                          activeTrackBar: BoxDecoration(
                            borderRadius: BorderRadius.circular(generalRadius),
                            color: AntiiQTheme.of(context).colorScheme.primary,
                          ),
                        ),
                        onDragCompleted:
                            (handlerIndex, lowerValue, upperValue) => {
                          audioPlayer.setSpeed(lowerValue / 20),
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
                      setEqualizerEnabled(value);
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
                        return Expanded(
                          child: FlutterSlider(
                            tooltip: FlutterSliderTooltip(
                              disabled: true,
                            ),
                            handlerHeight: 30,
                            handlerWidth: 15,
                            selectByTap: true,
                            axis: Axis.vertical,
                            rtl: true,
                            values: [band.gain * 100],
                            min: parameters.minDecibels * 100,
                            max: parameters.maxDecibels * 100,
                            handler: FlutterSliderHandler(
                              decoration: BoxDecoration(
                                  color: AntiiQTheme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(generalRadius/2)),
                              child: Container(),
                            ),
                            foregroundDecoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(generalRadius)),
                            trackBar: FlutterSliderTrackBar(
                              inactiveTrackBar: BoxDecoration(
                                borderRadius: BorderRadius.circular(generalRadius),
                                color: AntiiQTheme.of(context).colorScheme.primary,
                                border: Border.all(
                                  width: 3,
                                  color: AntiiQTheme.of(context).colorScheme.primary,
                                ),
                              ),
                              activeTrackBar: BoxDecoration(
                                borderRadius: BorderRadius.circular(generalRadius),
                                color: AntiiQTheme.of(context).colorScheme.secondary,
                              ),
                            ),
                            onDragCompleted:
                                (handlerIndex, lowerValue, upperValue) => {
                              band.setGain(
                                lowerValue / 100,
                              ),
                              saveBandFreqs(),
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
    );
  }
}
