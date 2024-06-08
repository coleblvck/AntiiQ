//Flutter Packages
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:flutter/material.dart';

//Audio Service
import 'package:audio_service/audio_service.dart';

//Flutter Xlider
import 'package:flutter_xlider/flutter_xlider.dart';

//Antiiq Packages
import 'package:antiiq/player/global_variables.dart';

class SeekBarBuilder extends StatelessWidget {
  const SeekBarBuilder({
    super.key,
    required this.currentTrack,
  });

  final MediaItem? currentTrack;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: currentPosition(),
      builder: (context, data) {
        int? position = data.data?.abs().inMilliseconds;
        int? duration = currentTrack?.duration?.abs().inMilliseconds;
        position ??= 0;
        final progress = position / duration!;
        return SeekBar(progress: progress, duration: duration);
      },
    );
  }
}

class SeekBar extends StatelessWidget {
  const SeekBar({
    super.key,
    required this.progress,
    required this.duration,
  });

  final double progress;
  final int? duration;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: FlutterSlider(
        selectByTap: true,
        tooltip: FlutterSliderTooltip(
          disabled: true,
        ),
        handlerHeight: 20,
        handlerWidth: 30,
        values: [progress * 1000],
        min: 0,
        max: 1000,
        handler: FlutterSliderHandler(
          decoration: BoxDecoration(
              color: AntiiQTheme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(generalRadius/2)),
          child: Container(),
        ),
        foregroundDecoration:
            BoxDecoration(borderRadius: BorderRadius.circular(generalRadius)),
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
        onDragCompleted: (handlerIndex, lowerValue, upperValue) =>
            audioHandler.seek(Duration(
                milliseconds: (duration! * (lowerValue / 1000)).toInt())),
      ),
    );
  }
}

class ProgressBarBuilder extends StatelessWidget {
  const ProgressBarBuilder({
    super.key,
    required this.currentTrack,
  });

  final MediaItem? currentTrack;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: currentPosition(),
      builder: (context, data) {
        int? position = data.data?.abs().inMilliseconds;
        int? duration = currentTrack?.duration?.abs().inMilliseconds;
        position ??= 0;
        final progress = position / duration!;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: CustomProgressIndicator(progress: progress),
        );
      },
    );
  }
}
