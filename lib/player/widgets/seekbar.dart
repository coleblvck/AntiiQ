import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/widgets/ui/antiiq_slider.dart';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:antiiq/player/global_variables.dart';


class SeekBar extends StatefulWidget {
  final int position;
  final int duration;
  final ValueChanged<int>? onChanged;
  final ValueChanged<int>? onChangeEnd;
  final Color activeTrackColor;
  final Color inactiveTrackColor;
  final Color thumbColor;
  final double thumbWidth;
  final double thumbHeight;
  final double thumbBorderRadius;
  final double trackHeight;
  final double trackBorderRadius;
  final Axis orientation;

  const SeekBar({
    Key? key,
    required this.position,
    required this.duration,
    this.onChanged,
    this.onChangeEnd,
    this.activeTrackColor = Colors.blue,
    this.inactiveTrackColor = Colors.grey,
    this.thumbColor = Colors.blue,
    this.thumbWidth = 30.0,
    this.thumbHeight = 20.0,
    this.thumbBorderRadius = 4.0,
    this.trackHeight = 6.0,
    this.trackBorderRadius = 4.0,
    this.orientation = Axis.horizontal,
  }) : super(key: key);

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  double? _draggingValue;

  @override
  Widget build(BuildContext context) {
    double maxDuration = widget.duration.toDouble();
    if (maxDuration <= 0) {
      maxDuration = 0.0;
    }

    double clampedPosition = widget.position.toDouble();
    if (clampedPosition > maxDuration && maxDuration > 0) {
      clampedPosition = maxDuration;
    }

    double sliderValue = _draggingValue ?? clampedPosition;

    return AntiiQSlider(
      min: 0.0,
      max: maxDuration,
      value: sliderValue,
      activeTrackColor: widget.activeTrackColor,
      inactiveTrackColor: widget.inactiveTrackColor,
      thumbColor: widget.thumbColor,
      thumbWidth: widget.thumbWidth,
      thumbHeight: widget.thumbHeight,
      thumbBorderRadius: widget.thumbBorderRadius,
      trackHeight: widget.trackHeight,
      trackBorderRadius: widget.trackBorderRadius,
      orientation: widget.orientation,
      onChanged: (value) {
        setState(() {
          _draggingValue = value;
        });
        if (widget.onChanged != null) {
          widget.onChanged!(value.toInt());
        }
      },
      onChangeEnd: (value) {
        setState(() {
          _draggingValue = null;
        });
        if (widget.onChangeEnd != null) {
          widget.onChangeEnd!(value.toInt());
        }
      },
    );
  }
}

class SeekBarBuilder extends StatelessWidget {
  final MediaItem? currentTrack;
  final Color activeTrackColor;
  final Color inactiveTrackColor;
  final Color thumbColor;
  final double thumbWidth;
  final double thumbHeight;
  final double thumbBorderRadius;
  final double trackHeight;
  final double trackBorderRadius;
  final Axis orientation;

  const SeekBarBuilder({
    Key? key,
    required this.currentTrack,
    required this.activeTrackColor,
    required this.inactiveTrackColor,
    required this.thumbColor,
    this.thumbWidth = 30.0,
    this.thumbHeight = 16.0,
    this.thumbBorderRadius = 4.0,
    this.trackHeight = 20.0,
    this.trackBorderRadius = 4.0,
    this.orientation = Axis.horizontal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: currentPosition(),
      builder: (context, data) {
        int positionMs = data.data?.abs().inMilliseconds ?? 0;
        int durationMs = currentTrack?.duration?.abs().inMilliseconds ?? 0;

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(generalRadius - 6),
            child: SeekBar(
              position: positionMs,
              duration: durationMs,
              activeTrackColor: activeTrackColor,
              inactiveTrackColor: inactiveTrackColor,
              thumbColor: thumbColor,
              thumbWidth: thumbWidth,
              thumbHeight: thumbHeight,
              thumbBorderRadius: generalRadius - 6,
              trackHeight: trackHeight,
              trackBorderRadius: generalRadius - 6,
              orientation: orientation,
              onChangeEnd: (newPosition) {
                globalAntiiqAudioHandler.seek(Duration(milliseconds: newPosition));
              },
            ),
          ),
        );
      },
    );
  }
}

class CustomProgressIndicator extends StatelessWidget {
  final double progress;
  final Color activeColor;
  final Color backgroundColor;
  final double height;
  final double borderRadius;
  final Axis orientation;

  const CustomProgressIndicator({
    Key? key,
    required this.progress,
    this.activeColor = Colors.blue,
    this.backgroundColor = Colors.grey,
    this.height = 4.0,
    this.borderRadius = 2.0,
    this.orientation = Axis.horizontal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double clampedProgress = progress.clamp(0.0, 1.0);
    
    if (orientation == Axis.horizontal) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: FractionallySizedBox(
          widthFactor: clampedProgress,
          alignment: Alignment.centerLeft,
          child: Container(
            decoration: BoxDecoration(
              color: activeColor,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
        ),
      );
    } else {
      return Container(
        width: height,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: FractionallySizedBox(
          heightFactor: clampedProgress,
          alignment: Alignment.bottomCenter,
          child: Container(
            decoration: BoxDecoration(
              color: activeColor,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
        ),
      );
    }
  }
}

class ProgressBarBuilder extends StatelessWidget {
  final MediaItem? currentTrack;
  final Color activeColor;
  final Color backgroundColor;
  final double height;
  final double borderRadius;
  final Axis orientation;

  const ProgressBarBuilder({
    Key? key,
    required this.currentTrack,
    this.activeColor = Colors.blue,
    this.backgroundColor = Colors.grey,
    this.height = 4.0,
    this.borderRadius = 2.0,
    this.orientation = Axis.horizontal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: currentPosition(),
      builder: (context, data) {
        int? position = data.data?.abs().inMilliseconds;
        int? duration = currentTrack?.duration?.abs().inMilliseconds;
        position ??= 0;
        double progress = (duration != null && duration > 0) ? position / duration : 0.0;

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: CustomProgressIndicator(
            progress: progress,
            activeColor: activeColor,
            backgroundColor: backgroundColor,
            height: height,
            borderRadius: borderRadius,
            orientation: orientation,
          ),
        );
      },
    );
  }
}