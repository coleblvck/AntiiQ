import 'package:flutter/material.dart';

/// A highly customizable switch widget with comprehensive styling options
class CustomSwitch extends StatefulWidget {
  /// Current value of the switch
  final bool value;

  /// Callback when switch value changes
  final ValueChanged<bool>? onChanged;

  /// Width of the switch track
  final double width;

  /// Height of the switch track
  final double height;

  /// Size of the thumb (width and height)
  final double thumbSize;

  /// Color of the track when switch is ON
  final Color activeTrackColor;

  /// Color of the track when switch is OFF
  final Color inactiveTrackColor;

  /// Color of the thumb when switch is ON
  final Color activeThumbColor;

  /// Color of the thumb when switch is OFF
  final Color inactiveThumbColor;

  /// Border color of the track when switch is ON
  final Color? activeTrackBorderColor;

  /// Border color of the track when switch is OFF
  final Color? inactiveTrackBorderColor;

  /// Width of the track border
  final double trackBorderWidth;

  /// Border radius of the track
  final double trackBorderRadius;

  /// Border radius of the thumb
  final double thumbBorderRadius;

  /// Elevation of the thumb (shadow)
  final double thumbElevation;

  /// Duration of the animation
  final Duration animationDuration;

  /// Curve of the animation
  final Curve animationCurve;

  /// Padding inside the track (affects thumb movement range)
  final double trackPadding;

  /// Shadow color of the thumb
  final Color thumbShadowColor;

  /// Icon to display on the thumb when ON
  final IconData? activeIcon;

  /// Icon to display on the thumb when OFF
  final IconData? inactiveIcon;

  /// Icon color when ON
  final Color? activeIconColor;

  /// Icon color when OFF
  final Color? inactiveIconColor;

  /// Icon size
  final double? iconSize;

  /// Whether the switch is disabled
  final bool disabled;

  /// Opacity when disabled
  final double disabledOpacity;

  const CustomSwitch({
    Key? key,
    required this.value,
    required this.onChanged,
    this.width = 56.0,
    this.height = 32.0,
    this.thumbSize = 26.0,
    this.activeTrackColor = const Color(0xFF4CAF50),
    this.inactiveTrackColor = const Color(0xFFE0E0E0),
    this.activeThumbColor = Colors.white,
    this.inactiveThumbColor = Colors.white,
    this.activeTrackBorderColor,
    this.inactiveTrackBorderColor,
    this.trackBorderWidth = 0.0,
    this.trackBorderRadius = 16.0,
    this.thumbBorderRadius = 13.0,
    this.thumbElevation = 2.0,
    this.animationDuration = const Duration(milliseconds: 200),
    this.animationCurve = Curves.easeInOut,
    this.trackPadding = 3.0,
    this.thumbShadowColor = Colors.black26,
    this.activeIcon,
    this.inactiveIcon,
    this.activeIconColor,
    this.inactiveIconColor,
    this.iconSize,
    this.disabled = false,
    this.disabledOpacity = 0.5,
  }) : super(key: key);

  @override
  State<CustomSwitch> createState() => _CustomSwitchState();
}

class _CustomSwitchState extends State<CustomSwitch>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
      value: widget.value ? 1.0 : 0.0,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: widget.animationCurve,
    );
  }

  @override
  void didUpdateWidget(CustomSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (widget.value) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.disabled && widget.onChanged != null) {
      widget.onChanged!(!widget.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxThumbOffset =
        widget.width - widget.thumbSize - (widget.trackPadding * 2);

    return Opacity(
      opacity: widget.disabled ? widget.disabledOpacity : 1.0,
      child: GestureDetector(
        onTap: _handleTap,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final trackColor = Color.lerp(
                widget.inactiveTrackColor,
                widget.activeTrackColor,
                _animation.value,
              )!;

              final thumbColor = Color.lerp(
                widget.inactiveThumbColor,
                widget.activeThumbColor,
                _animation.value,
              )!;

              final trackBorderColor = widget.trackBorderWidth > 0
                  ? Color.lerp(
                      widget.inactiveTrackBorderColor ?? Colors.transparent,
                      widget.activeTrackBorderColor ?? Colors.transparent,
                      _animation.value,
                    )!
                  : Colors.transparent;

              final thumbOffset = _animation.value * maxThumbOffset;

              return Stack(
                children: [
                  // Track
                  Container(
                    width: widget.width,
                    height: widget.height,
                    decoration: BoxDecoration(
                      color: trackColor,
                      borderRadius:
                          BorderRadius.circular(widget.trackBorderRadius),
                      border: widget.trackBorderWidth > 0
                          ? Border.all(
                              color: trackBorderColor,
                              width: widget.trackBorderWidth,
                            )
                          : null,
                    ),
                  ),
                  // Thumb
                  Positioned(
                    left: widget.trackPadding + thumbOffset,
                    top: (widget.height - widget.thumbSize) / 2,
                    child: Container(
                      width: widget.thumbSize,
                      height: widget.thumbSize,
                      decoration: BoxDecoration(
                        color: thumbColor,
                        borderRadius:
                            BorderRadius.circular(widget.thumbBorderRadius),
                        boxShadow: widget.thumbElevation > 0
                            ? [
                                BoxShadow(
                                  color: widget.thumbShadowColor,
                                  blurRadius: widget.thumbElevation * 2,
                                  spreadRadius: widget.thumbElevation / 2,
                                  offset: Offset(0, widget.thumbElevation),
                                ),
                              ]
                            : null,
                      ),
                      child: _buildIcon(),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget? _buildIcon() {
    final currentIcon = widget.value ? widget.activeIcon : widget.inactiveIcon;
    if (currentIcon == null) return null;

    final iconColor = widget.value
        ? (widget.activeIconColor ?? widget.activeTrackColor)
        : (widget.inactiveIconColor ?? Colors.grey);

    return Center(
      child: Icon(
        currentIcon,
        size: widget.iconSize ?? widget.thumbSize * 0.6,
        color: iconColor,
      ),
    );
  }
}
