import 'package:flutter/material.dart';
import 'dart:math' as math;

class AntiiQSlider extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final double? step;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;
  final ValueChanged<double>? onChangeStart;
  final double thumbWidth;
  final double thumbHeight;
  final double thumbBorderRadius;
  final Color activeTrackColor;
  final Color inactiveTrackColor;
  final Color thumbColor;
  final double trackHeight;
  final double trackBorderRadius;
  final bool enabled;
  final bool selectByTap;
  final Axis orientation;

  const AntiiQSlider({
    Key? key,
    required this.value,
    required this.min,
    required this.max,
    this.step,
    this.onChanged,
    this.onChangeEnd,
    this.onChangeStart,
    this.thumbWidth = 30.0,
    this.thumbHeight = 20.0,
    this.thumbBorderRadius = 4.0,
    this.activeTrackColor = Colors.blue,
    this.inactiveTrackColor = Colors.grey,
    this.thumbColor = Colors.blue,
    this.trackHeight = 6.0,
    this.trackBorderRadius = 4.0,
    this.enabled = true,
    this.selectByTap = true,
    this.orientation = Axis.horizontal,
  }) : super(key: key);

  @override
  State<AntiiQSlider> createState() => _AntiiQSliderState();
}

class _AntiiQSliderState extends State<AntiiQSlider> {
  double _currentDragValue = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _currentDragValue = widget.value;
  }

  @override
  void didUpdateWidget(AntiiQSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDragging && oldWidget.value != widget.value) {
      _currentDragValue = widget.value;
    }
  }

  double _getValueFromGlobalPosition(Offset globalPosition) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset localPosition = box.globalToLocal(globalPosition);
    
    double percent;
    if (widget.orientation == Axis.horizontal) {
      percent = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
    } else {
      percent = 1.0 - (localPosition.dy / box.size.height).clamp(0.0, 1.0);
    }
    
    double newValue = widget.min + percent * (widget.max - widget.min);
    
    if (widget.step != null) {
      //final double stepCount = (widget.max - widget.min) / widget.step!;
      final double stepValue = (newValue - widget.min) / widget.step!;
      final int roundedStepValue = stepValue.round();
      newValue = widget.min + roundedStepValue * widget.step!;
    }
    
    return newValue.clamp(widget.min, widget.max);
  }

  void _handleDragStart(DragStartDetails details) {
    if (!widget.enabled) return;
    
    _isDragging = true;
    if (widget.selectByTap) {
      _currentDragValue = _getValueFromGlobalPosition(details.globalPosition);
      setState(() {});
    }
    
    if (widget.onChangeStart != null) {
      widget.onChangeStart!(_currentDragValue);
    }
    
    if (widget.onChanged != null) {
      widget.onChanged!(_currentDragValue);
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!widget.enabled || !_isDragging) return;
    
    _currentDragValue = _getValueFromGlobalPosition(details.globalPosition);
    setState(() {});
    
    if (widget.onChanged != null) {
      widget.onChanged!(_currentDragValue);
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!widget.enabled || !_isDragging) return;
    
    _isDragging = false;
    
    if (widget.onChangeEnd != null) {
      widget.onChangeEnd!(_currentDragValue);
    }
  }

  void _handleTap(TapUpDetails details) {
    if (!widget.enabled || !widget.selectByTap) return;
    
    _currentDragValue = _getValueFromGlobalPosition(details.globalPosition);
    setState(() {});
    
    if (widget.onChanged != null) {
      widget.onChanged!(_currentDragValue);
    }
    
    if (widget.onChangeEnd != null) {
      widget.onChangeEnd!(_currentDragValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double percent = (_currentDragValue - widget.min) / (widget.max - widget.min);
    
    Widget sliderWidget = LayoutBuilder(
      builder: (context, constraints) {
        final double maxLength = widget.orientation == Axis.horizontal 
            ? constraints.maxWidth 
            : constraints.maxHeight;
        
        final double thumbPosition = percent * maxLength;
        
        return Stack(
          clipBehavior: Clip.none,
          children: [
            _buildTrack(maxLength, percent),
            _buildThumb(thumbPosition, maxLength),
          ],
        );
      },
    );
    
    return GestureDetector(
      onTapUp: _handleTap,
      onHorizontalDragStart: widget.orientation == Axis.horizontal ? _handleDragStart : null,
      onHorizontalDragUpdate: widget.orientation == Axis.horizontal ? _handleDragUpdate : null,
      onHorizontalDragEnd: widget.orientation == Axis.horizontal ? _handleDragEnd : null,
      onVerticalDragStart: widget.orientation == Axis.vertical ? _handleDragStart : null,
      onVerticalDragUpdate: widget.orientation == Axis.vertical ? _handleDragUpdate : null,
      onVerticalDragEnd: widget.orientation == Axis.vertical ? _handleDragEnd : null,
      child: widget.orientation == Axis.horizontal
          ? SizedBox(
              height: math.max(widget.trackHeight, widget.thumbHeight),
              width: double.infinity,
              child: sliderWidget,
            )
          : SizedBox(
              width: math.max(widget.trackHeight, widget.thumbWidth),
              height: double.infinity,
              child: sliderWidget,
            ),
    );
  }

  Widget _buildTrack(double maxLength, double percent) {
    if (widget.orientation == Axis.horizontal) {
      return Center(
        child: Container(
          height: widget.trackHeight,
          width: maxLength,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.trackBorderRadius),
            color: widget.inactiveTrackColor,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              height: widget.trackHeight,
              width: maxLength * percent,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.trackBorderRadius),
                color: widget.activeTrackColor,
              ),
            ),
          ),
        ),
      );
    } else {
      return Center(
        child: Container(
          width: widget.trackHeight,
          height: maxLength,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.trackBorderRadius),
            color: widget.inactiveTrackColor,
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: widget.trackHeight,
              height: maxLength * percent,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.trackBorderRadius),
                color: widget.activeTrackColor,
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildThumb(double position, double maxLength) {
    final double effectivePosition = position.clamp(0.0, maxLength);
    
    if (widget.orientation == Axis.horizontal) {
      return Positioned(
        left: effectivePosition - (widget.thumbWidth / 2),
        top: 0,
        bottom: 0,
        child: Center(
          child: Container(
            width: widget.thumbWidth,
            height: widget.thumbHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.thumbBorderRadius),
              color: widget.thumbColor,
            ),
          ),
        ),
      );
    } else {
      return Positioned(
        top: maxLength - effectivePosition - (widget.thumbHeight / 2),
        left: 0,
        right: 0,
        child: Center(
          child: Container(
            width: widget.thumbWidth,
            height: widget.thumbHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.thumbBorderRadius),
              color: widget.thumbColor,
            ),
          ),
        ),
      );
    }
  }
}