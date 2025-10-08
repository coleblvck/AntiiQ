import 'package:antiiq/chaos/chaos_ui_state.dart';
import 'package:antiiq/chaos/chaos_ui/chaos_rotation.dart';
import 'package:antiiq/chaos/widgets/chaos/chaos_animation_manager.dart';
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/activity_handlers.dart';
import 'package:antiiq/player/utilities/audio_handler.dart';
import 'package:antiiq/player/widgets/ui/antiiq_slider.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';
import 'dart:math' as math;
import 'dart:io';

enum ChaosMiniPlayerState {
  collapsed,
  expanding,
  expanded,
  collapsing,
}

enum ChaosMiniPlayerDragDirection {
  left,
  right,
  up,
  down,
}

class ChaosMiniPlayerAnimationConfig {
  final Duration expansionDuration;
  final Curve expansionCurve;
  final Duration dragSnapBackDuration;
  final Curve dragSnapBackCurve;
  final double dragVisualDampening;
  final double horizontalThreshold;
  final double verticalThreshold;
  final bool usePhysicsBasedDrag;
  final double dragFriction;
  final double dragSpringStiffness;

  const ChaosMiniPlayerAnimationConfig({
    this.expansionDuration = const Duration(milliseconds: 400),
    this.expansionCurve = Curves.easeInOut,
    this.dragSnapBackDuration = const Duration(milliseconds: 200),
    this.dragSnapBackCurve = Curves.easeOutCubic,
    this.dragVisualDampening = 0.3,
    this.horizontalThreshold = 80.0,
    this.verticalThreshold = 60.0,
    this.usePhysicsBasedDrag = true,
    this.dragFriction = 0.05,
    this.dragSpringStiffness = 200.0,
  });
}

class DragGestureData {
  final ChaosMiniPlayerDragDirection direction;
  final MediaItem track;
  final PlaybackState playbackState;
  final double dragDistance;
  final double threshold;
  final ChaosMiniPlayerState playerState;
  final DateTime timestamp;

  const DragGestureData({
    required this.direction,
    required this.track,
    required this.playbackState,
    required this.dragDistance,
    required this.threshold,
    required this.playerState,
    required this.timestamp,
  });
}

typedef DragGestureCallback = void Function(DragGestureData data);
typedef TrackInfoCallback = void Function(
  MediaItem track,
  PlaybackState playbackState,
);

class ChaosMiniPlayerController extends ChangeNotifier {
  _ChaosMiniPlayerState? _state;

  void _attach(_ChaosMiniPlayerState state) => _state = state;
  void _detach() => _state = null;

  void expand() => _state?._expand();
  void collapse() => _state?._collapse();
  void toggle() => _state?._toggle();

  ChaosMiniPlayerState get currentState =>
      _state?._currentState ?? ChaosMiniPlayerState.collapsed;
  bool get isExpanded => currentState == ChaosMiniPlayerState.expanded;
  bool get isCollapsed => currentState == ChaosMiniPlayerState.collapsed;

  double get currentHeight => _state?._currentHeight ?? 0.0;
  double get expansionProgress => _state?._expandController.value ?? 0.0;
}

class ChaosMiniPlayer extends StatefulWidget {
  final ChaosMiniPlayerAnimationConfig animationConfig;
  final Function(ChaosMiniPlayerState state, double progress)? onStateChanged;
  final Function(double height)? onHeightChanged;
  final Function(ChaosMiniPlayerController controller)? onControllerReady;
  final ChaosAnimationManager? chaosAnimationManager;
  final DragGestureCallback? onLeftDrag;
  final DragGestureCallback? onRightDrag;
  final DragGestureCallback? onUpDrag;
  final DragGestureCallback? onDownDrag;
  final void Function()? onLongPress;
  final TrackInfoCallback? onTrackInfoChanged;

  const ChaosMiniPlayer({
    Key? key,
    this.animationConfig = const ChaosMiniPlayerAnimationConfig(),
    this.onStateChanged,
    this.onHeightChanged,
    this.onControllerReady,
    this.chaosAnimationManager,
    this.onLeftDrag,
    this.onRightDrag,
    this.onUpDrag,
    this.onDownDrag,
    this.onLongPress,
    this.onTrackInfoChanged,
  }) : super(key: key);

  @override
  State<ChaosMiniPlayer> createState() => _ChaosMiniPlayerState();
}

class _ChaosMiniPlayerState extends State<ChaosMiniPlayer>
    with TickerProviderStateMixin {
  late AnimationController _expandController;
  late AnimationController _dragController;
  late ChaosMiniPlayerController _controller;
  late ChaosMiniPlayerAnimationConfig _config;

  final GlobalKey _containerKey = GlobalKey();
  double _lastReportedHeight = 0.0;

  ChaosMiniPlayerState _currentState = ChaosMiniPlayerState.collapsed;

  Offset _dragStartPosition = Offset.zero;
  Offset _currentDragOffset = Offset.zero;
  bool _isDragging = false;
  bool _dragThresholdReached = false;
  bool _isSeekbarDragging = false;

  bool get _isExpanded => _currentState == ChaosMiniPlayerState.expanded;

  double get _currentHeight {
    final renderBox =
        _containerKey.currentContext?.findRenderObject() as RenderBox?;
    return renderBox?.size.height ?? 0.0;
  }

  void _notifyHeightIfChanged() {
    final currentHeight = _currentHeight;
    if ((currentHeight - _lastReportedHeight).abs() > 0.5) {
      _lastReportedHeight = currentHeight;
      widget.onHeightChanged?.call(currentHeight);
    }
  }

  @override
  void initState() {
    super.initState();

    _config = widget.animationConfig;
    _controller = ChaosMiniPlayerController();
    _controller._attach(this);

    _expandController = AnimationController(
      duration: _config.expansionDuration,
      vsync: this,
    );

    _dragController = AnimationController(
      duration: _config.dragSnapBackDuration,
      vsync: this,
    );

    _expandController.addStatusListener((status) {
      final newState = switch (status) {
        AnimationStatus.forward => ChaosMiniPlayerState.expanding,
        AnimationStatus.completed => ChaosMiniPlayerState.expanded,
        AnimationStatus.reverse => ChaosMiniPlayerState.collapsing,
        AnimationStatus.dismissed => ChaosMiniPlayerState.collapsed,
      };

      if (newState != _currentState) {
        setState(() => _currentState = newState);
        widget.onStateChanged?.call(newState, _expandController.value);
      }
    });

    _expandController.addListener(() {
      widget.onStateChanged?.call(_currentState, _expandController.value);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onControllerReady?.call(_controller);
      _notifyHeightIfChanged();
    });
  }

  @override
  void dispose() {
    _controller._detach();
    _expandController.dispose();
    _dragController.dispose();
    super.dispose();
  }

  void _expand() => _expandController.forward();
  void _collapse() => _expandController.reverse();
  void _toggle() {
    if (_isExpanded) {
      _collapse();
    } else {
      _expand();
    }
  }

  void _togglePlayer() {
    _toggle();
    HapticFeedback.mediumImpact();
    widget.chaosAnimationManager?.triggerGlitch();
  }

  void _handlePanStart(DragStartDetails details) {
    if (_isSeekbarDragging) return;
    _dragStartPosition = details.localPosition;
    _isDragging = true;
    _dragThresholdReached = false;
    _currentDragOffset = Offset.zero;
    _dragController.stop();
    _dragController.reset();
  }

  void _handlePanUpdate(DragUpdateDetails details, MediaItem currentTrack) {
    if (!_isDragging || _isSeekbarDragging) return;

    _currentDragOffset = details.localPosition - _dragStartPosition;

    if (_config.usePhysicsBasedDrag) {
      final distance = _currentDragOffset.distance;
      final dampeningFactor = 1.0 / (1.0 + (_config.dragFriction * distance));
      _currentDragOffset = _currentDragOffset * dampeningFactor;
    }

    final dragDistance = _currentDragOffset.distance;
    final horizontalDistance = _currentDragOffset.dx.abs();
    final verticalDistance = _currentDragOffset.dy.abs();

    bool thresholdReached = false;
    ChaosMiniPlayerDragDirection? direction;

    if (horizontalDistance > _config.horizontalThreshold &&
        horizontalDistance > verticalDistance) {
      thresholdReached = true;
      direction = _currentDragOffset.dx > 0
          ? ChaosMiniPlayerDragDirection.right
          : ChaosMiniPlayerDragDirection.left;
    } else if (verticalDistance > _config.verticalThreshold &&
        verticalDistance > horizontalDistance) {
      thresholdReached = true;
      direction = _currentDragOffset.dy > 0
          ? ChaosMiniPlayerDragDirection.down
          : ChaosMiniPlayerDragDirection.up;
    }

    if (thresholdReached && !_dragThresholdReached && direction != null) {
      _dragThresholdReached = true;
      HapticFeedback.mediumImpact();
      widget.chaosAnimationManager?.triggerGlitch();

      final antiiQState = context.read<AntiiqState>();
      final playbackState =
          antiiQState.audioSetup.audioHandler.playbackState.value;

      final dragData = DragGestureData(
        direction: direction,
        track: currentTrack,
        playbackState: playbackState,
        dragDistance: dragDistance,
        threshold: direction == ChaosMiniPlayerDragDirection.left ||
                direction == ChaosMiniPlayerDragDirection.right
            ? _config.horizontalThreshold
            : _config.verticalThreshold,
        playerState: _currentState,
        timestamp: DateTime.now(),
      );

      switch (direction) {
        case ChaosMiniPlayerDragDirection.left:
          widget.onLeftDrag?.call(dragData);
          break;
        case ChaosMiniPlayerDragDirection.right:
          widget.onRightDrag?.call(dragData);
          break;
        case ChaosMiniPlayerDragDirection.up:
          widget.onUpDrag?.call(dragData);
          break;
        case ChaosMiniPlayerDragDirection.down:
          widget.onDownDrag?.call(dragData);
          break;
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    _isDragging = false;
    _dragThresholdReached = false;

    _dragController.forward().then((_) {
      if (mounted) {
        setState(() {
          _currentDragOffset = Offset.zero;
        });
        _dragController.reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentRadius = context.watch<ChaosUIState>().chaosRadius;
    final antiiQState = context.read<AntiiqState>();
    final antiiQAudioHandler = context.read<AntiiqAudioHandler>();

    return StreamBuilder<MediaItem?>(
      stream: antiiQAudioHandler.mediaItem.stream,
      builder: (context, trackSnapshot) {
        final currentTrack =
            trackSnapshot.data ?? antiiQAudioHandler.blankMediaItem;

        return StreamBuilder<Duration>(
          stream: antiiQAudioHandler.audioPlayer.positionStream,
          builder: (context, positionSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;

            return StreamBuilder<PlaybackState>(
              stream: antiiQState.audioSetup.audioHandler.playbackState.stream,
              builder: (context, playbackSnapshot) {
                final playbackState = playbackSnapshot.data ?? PlaybackState();
                final shuffleMode =
                    playbackState.shuffleMode != AudioServiceShuffleMode.none;
                final repeatMode = playbackState.repeatMode;

                return _DragLayer(
                  dragOffset: _currentDragOffset,
                  dragController: _dragController,
                  config: _config,
                  child: AnimatedBuilder(
                    animation: _expandController,
                    builder: (context, child) {
                      final expandProgress = _expandController.value;

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          _notifyHeightIfChanged();
                        }
                      });

                      return AnimatedSize(
                        duration: _config.expansionDuration,
                        curve: _config.expansionCurve,
                        alignment: Alignment.bottomCenter,
                        child: GestureDetector(
                          onTap: _togglePlayer,
                          onLongPress: () {
                            HapticFeedback.mediumImpact();
                            widget.onLongPress?.call();
                          },
                          onPanStart: _handlePanStart,
                          onPanUpdate: (details) =>
                              _handlePanUpdate(details, currentTrack),
                          onPanEnd: _handlePanEnd,
                          child: Container(
                            key: _containerKey,
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AntiiQTheme.of(context)
                                  .colorScheme
                                  .surface
                                  .withValues(
                                      alpha: (0.85 + (0.1 * expandProgress))
                                          .clamp(0.0, 1.0)),
                              border: Border.all(
                                color: AntiiQTheme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(
                                        alpha: (0.3 + (0.2 * expandProgress))
                                            .clamp(0.0, 1.0)),
                                width: 1 + expandProgress,
                              ),
                              borderRadius:
                                  BorderRadius.circular(currentRadius),
                              boxShadow: expandProgress > 0.3
                                  ? [
                                      BoxShadow(
                                        color: AntiiQTheme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(
                                                alpha: 0.15 * expandProgress),
                                        blurRadius: 12 * expandProgress,
                                        offset: const Offset(0, 4),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildCollapsedContent(
                                  expandProgress,
                                  currentTrack,
                                  playbackState,
                                  shuffleMode,
                                  repeatMode,
                                ),
                                if (expandProgress < 0.3)
                                  _buildCollapsedProgressIndicator(
                                      expandProgress, currentTrack, position),
                                if (expandProgress > 0.1) ...[
                                  SizedBox(height: 16 * expandProgress),
                                  _buildExpandedSeekbar(
                                      expandProgress, currentTrack),
                                  SizedBox(height: 16 * expandProgress),
                                  _buildControls(
                                      expandProgress, repeatMode, shuffleMode),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCollapsedContent(
      double expandProgress,
      MediaItem currentTrack,
      PlaybackState playbackState,
      bool shuffleMode,
      AudioServiceRepeatMode repeatMode) {
    return Row(
      children: [
        ChaosRotatedStatefulWidget(
          index: hashCode % 2000,
          style: ChaosRotationStyle.fibonacci,
          maxAngle: 0.2,
          child: _buildAlbumArt(
            expandProgress,
            currentTrack,
          ),
        ),
        SizedBox(width: 16 + (8 * expandProgress)),
        Expanded(child: _buildTrackInfo(expandProgress, currentTrack)),
        if (expandProgress < 0.3) ...[
          _buildCompactStateIndicators(shuffleMode, repeatMode),
          const SizedBox(width: 8),
        ],
        ChaosRotatedStatefulWidget(
          index: hashCode % 100,
          style: ChaosRotationStyle.fibonacci,
          maxAngle: 0.2,
          child: _buildMainControl(
            expandProgress,
            playbackState,
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsedProgressIndicator(
      double expandProgress, MediaItem currentTrack, Duration position) {
    return StreamBuilder<bool>(
      stream: interactiveSeekbarStream.stream,
      builder: (context, snapshot) {
        final isInteractive = snapshot.data ?? interactiveMiniPlayerSeekbar;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _notifyHeightIfChanged();
          }
        });

        return Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: isInteractive
              ? _buildInteractiveSeekbar(currentTrack,
                  displayProgressRow: false)
              : _buildStaticProgressBar(currentTrack),
        );
      },
    );
  }

  Widget _buildExpandedSeekbar(double expandProgress, MediaItem currentTrack) {
    return StreamBuilder<bool>(
        stream: trackDurationDisplayStream.stream,
        builder: (context, snapshot) {
          final displayProgressRow = snapshot.data ?? showTrackDuration;
          return Opacity(
            opacity: ((expandProgress - 0.1) / 0.4).clamp(0.0, 1.0),
            child: _buildInteractiveSeekbar(
              currentTrack,
              displayProgressRow: displayProgressRow,
            ),
          );
        });
  }

  Widget _buildInteractiveSeekbar(MediaItem currentTrack,
      {bool displayProgressRow = true}) {
    final chaosUIState = context.watch<ChaosUIState>();
    final radius = chaosUIState.getAdjustedRadius(6);
    final antiiQAudioHandler = context.read<AntiiqAudioHandler>();

    return StreamBuilder<Duration>(
      stream: antiiQAudioHandler.audioPlayer.positionStream,
      builder: (context, snapshot) {
        final currentPosition = snapshot.data ?? Duration.zero;
        final totalDuration = currentTrack.duration ?? Duration.zero;

        final currentMinutes = currentPosition.inMinutes;
        final currentSeconds = currentPosition.inSeconds % 60;
        final totalMinutes = totalDuration.inMinutes;
        final totalSeconds = totalDuration.inSeconds % 60;

        return Column(
          children: [
            ChaosRotatedWidget(
              angle: -0.025,
              child: AntiiQSlider(
                value: currentPosition.inMilliseconds.toDouble(),
                min: 0,
                max: totalDuration.inMilliseconds.toDouble(),
                activeTrackColor: AntiiQTheme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.3),
                inactiveTrackColor: AntiiQTheme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.05),
                thumbColor: AntiiQTheme.of(context).colorScheme.secondary,
                thumbWidth: 2.0,
                thumbHeight: 24.0,
                thumbBorderRadius: 0,
                trackHeight: 24.0,
                trackBorderRadius: radius,
                orientation: Axis.horizontal,
                selectByTap: true,
                onChangeStart: (value) {
                  setState(() => _isSeekbarDragging = true);
                },
                onChangeEnd: (value) {
                  final seekPosition = Duration(milliseconds: value.toInt());
                  antiiQAudioHandler.seek(seekPosition);
                  setState(() => _isSeekbarDragging = false);
                  HapticFeedback.selectionClick();
                  widget.chaosAnimationManager?.triggerGlitch();
                },
              ),
            ),
            if (displayProgressRow) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Transform.rotate(
                    angle: -0.018,
                    child: Text(
                      '$currentMinutes:${currentSeconds.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: AntiiQTheme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  Transform.rotate(
                    angle: 0.025,
                    child: Text(
                      '$totalMinutes:${totalSeconds.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: AntiiQTheme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildStaticProgressBar(MediaItem currentTrack) {
    final antiiQState = context.watch<AntiiqState>();

    return StreamBuilder<Duration>(
      stream: antiiQState.audioSetup.audioHandler.audioPlayer.positionStream,
      builder: (context, snapshot) {
        final currentPosition = snapshot.data ?? Duration.zero;
        final totalDuration = currentTrack.duration ?? Duration.zero;

        final progress = totalDuration.inMilliseconds > 0
            ? currentPosition.inMilliseconds / totalDuration.inMilliseconds
            : 0.0;

        return Transform.rotate(
          angle: -0.025,
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              border: Border.all(
                color: AntiiQTheme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
            child: Stack(
              children: [
                Container(
                  color: AntiiQTheme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: 0.3),
                ),
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    color: AntiiQTheme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactStateIndicators(
      bool shuffleMode, AudioServiceRepeatMode repeatMode) {
    final hasActiveState =
        shuffleMode || repeatMode != AudioServiceRepeatMode.none;
    if (!hasActiveState) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (shuffleMode)
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: AntiiQTheme.of(context).colorScheme.secondary,
              border: Border.all(
                color: AntiiQTheme.of(context)
                    .colorScheme
                    .secondary
                    .withValues(alpha: 0.5),
                width: 1,
              ),
            ),
          ),
        if (shuffleMode && repeatMode != AudioServiceRepeatMode.none)
          const SizedBox(width: 4),
        if (repeatMode != AudioServiceRepeatMode.none)
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: AntiiQTheme.of(context).colorScheme.primary,
              border: Border.all(
                color: AntiiQTheme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.5),
                width: 1,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAlbumArt(double expandProgress, MediaItem currentTrack) {
    final chaosUIState = context.watch<ChaosUIState>();
    final artRadius = chaosUIState.getAdjustedRadius(6);
    return RepaintBoundary(
      child: AnimatedContainer(
        duration: _config.expansionDuration,
        curve: _config.expansionCurve,
        width: 40 + (80 * expandProgress),
        height: 40 + (80 * expandProgress),
        decoration: BoxDecoration(
          color: AntiiQTheme.of(context)
              .colorScheme
              .primary
              .withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(artRadius),
          border: Border.all(
            color: AntiiQTheme.of(context)
                .colorScheme
                .primary
                .withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            if (currentTrack.artUri != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(artRadius),
                child: Image.file(
                  File.fromUri(currentTrack.artUri!),
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  cacheWidth: 120,
                  cacheHeight: 120,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildDefaultAlbumArt(expandProgress),
                ),
              )
            else
              _buildDefaultAlbumArt(expandProgress),
            _buildCornerBracket(true, expandProgress),
            _buildCornerBracket(false, expandProgress),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAlbumArt(double expandProgress) {
    return Center(
      child: Icon(
        Icons.music_note,
        color: AntiiQTheme.of(context).colorScheme.primary,
        size: 16 + (24 * expandProgress),
      ),
    );
  }

  Widget _buildCornerBracket(bool isTopLeft, double expandProgress) {
    const baseOpacity = 0.3;
    const expandedOpacity = 0.7;
    final opacity =
        baseOpacity + ((expandedOpacity - baseOpacity) * expandProgress);

    return Positioned(
      left: isTopLeft ? 4 : null,
      top: isTopLeft ? 4 : null,
      right: isTopLeft ? null : 4,
      bottom: isTopLeft ? null : 4,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: 8 + (4 * expandProgress),
          height: 8 + (4 * expandProgress),
          decoration: BoxDecoration(
            border: Border(
              top: isTopLeft
                  ? BorderSide(
                      color: AntiiQTheme.of(context).colorScheme.secondary,
                      width: 1.5)
                  : BorderSide.none,
              left: isTopLeft
                  ? BorderSide(
                      color: AntiiQTheme.of(context).colorScheme.secondary,
                      width: 1.5)
                  : BorderSide.none,
              bottom: !isTopLeft
                  ? BorderSide(
                      color: AntiiQTheme.of(context).colorScheme.secondary,
                      width: 1.5)
                  : BorderSide.none,
              right: !isTopLeft
                  ? BorderSide(
                      color: AntiiQTheme.of(context).colorScheme.secondary,
                      width: 1.5)
                  : BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrackInfo(double expandProgress, MediaItem currentTrack) {
    final title = (currentTrack.title.isEmpty ? 'NO TITLE' : currentTrack.title)
        .toUpperCase();
    final artist = (currentTrack.artist?.isEmpty ?? true
            ? 'UNKNOWN ARTIST'
            : currentTrack.artist!)
        .toUpperCase();
    final album = (currentTrack.album?.isEmpty ?? true
            ? 'UNKNOWN ALBUM'
            : currentTrack.album!)
        .toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: widget.chaosAnimationManager?.glitchController ??
              const AlwaysStoppedAnimation(0.0),
          builder: (context, child) {
            final glitchController =
                widget.chaosAnimationManager?.glitchController;
            final glitchOffset =
                glitchController?.isAnimating == true && _isExpanded
                    ? Offset(
                        glitchController!.value *
                            (math.Random().nextDouble() * 3 - 1.5),
                        glitchController.value *
                            (math.Random().nextDouble() * 2 - 1),
                      )
                    : Offset.zero;

            return Transform.translate(
              offset: glitchOffset,
              child: Transform.rotate(
                angle: -0.025 + (expandProgress * 0.008),
                child: Text(
                  title,
                  maxLines: expandProgress > 0.3 ? 3 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AntiiQTheme.of(context).colorScheme.onSurface,
                    fontSize: 11 + (5 * expandProgress),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.8 + (0.7 * expandProgress),
                    shadows: expandProgress > 0.5
                        ? [
                            Shadow(
                              color: AntiiQTheme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 0),
                            )
                          ]
                        : null,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 2),
        Transform.rotate(
          angle: 0.012 - (expandProgress * 0.006),
          child: Text(
            artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AntiiQTheme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.65),
              fontSize: 9 + (2 * expandProgress),
              fontWeight: FontWeight.w500,
              letterSpacing: 2.2 + (0.5 * expandProgress),
            ),
          ),
        ),
        if (expandProgress > 0.3)
          Opacity(
            opacity: ((expandProgress - 0.3) / 0.7).clamp(0.0, 1.0),
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Transform.rotate(
                angle: -0.01,
                child: Text(
                  album,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AntiiQTheme.of(context).colorScheme.secondary,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.8,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMainControl(double expandProgress, PlaybackState playbackState) {
    final currentRadius = context.watch<ChaosUIState>().chaosRadius;
    return AnimatedBuilder(
      animation: widget.chaosAnimationManager?.glitchController ??
          const AlwaysStoppedAnimation(0.0),
      builder: (context, child) {
        final glitchController = widget.chaosAnimationManager?.glitchController;
        final glitchOffset = glitchController?.isAnimating == true
            ? Offset(
                glitchController!.value * (math.Random().nextDouble() * 2 - 1),
                glitchController.value * (math.Random().nextDouble() * 1 - 0.5),
              )
            : Offset.zero;

        return Transform.translate(
          offset: glitchOffset,
          child: InkWell(
            onTap: () {
              if (playbackState.playing) {
                pause();
              } else {
                resume();
              }
              HapticFeedback.mediumImpact();
              widget.chaosAnimationManager?.triggerGlitch();
            },
            child: Container(
              width: 32 + (8 * expandProgress),
              height: 32 + (8 * expandProgress),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AntiiQTheme.of(context)
                      .colorScheme
                      .secondary
                      .withValues(
                          alpha:
                              (0.4 + (0.3 * expandProgress)).clamp(0.0, 1.0)),
                  width: 1 + (0.5 * expandProgress),
                ),
                borderRadius: BorderRadius.circular(currentRadius - 4),
              ),
              child: Icon(
                playbackState.playing ? Icons.pause : Icons.play_arrow,
                color: AntiiQTheme.of(context).colorScheme.secondary,
                size: 14 + (4 * expandProgress),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildControls(double expandProgress,
      AudioServiceRepeatMode repeatMode, bool shuffleModeEnabled) {
    final antiiQState = context.read<AntiiqState>();
    final controls = [
      (Icons.skip_previous, -0.025, false, () => previous()),
      (Icons.replay_10, 0.018, false, () => rewind()),
      (Icons.forward_30, -0.012, false, () => forward()),
      (Icons.skip_next, 0.022, false, () => next()),
      (
        Icons.shuffle,
        -0.02,
        shuffleModeEnabled,
        () {
          antiiQState.audioSetup.preferences
              .updateShuffleMode(!shuffleModeEnabled);
        }
      ),
      (
        (repeatMode == AudioServiceRepeatMode.none ||
                repeatMode == AudioServiceRepeatMode.all)
            ? RemixIcon.repeat
            : RemixIcon.repeat_one,
        0.015,
        repeatMode == AudioServiceRepeatMode.none ? false : true,
        () {
          final nextMode = switch (repeatMode) {
            AudioServiceRepeatMode.none => AudioServiceRepeatMode.one,
            AudioServiceRepeatMode.one => AudioServiceRepeatMode.all,
            AudioServiceRepeatMode.all => AudioServiceRepeatMode.none,
            AudioServiceRepeatMode.group => AudioServiceRepeatMode.none,
          };
          antiiQState.audioSetup.preferences.updateLoopMode(nextMode);
        }
      ),
    ];

    return Opacity(
      opacity: ((expandProgress - 0.1) / 0.4).clamp(0.0, 1.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: controls
            .map((control) => _buildExpandedControl(
                control.$1, control.$2, control.$3, control.$4))
            .toList(),
      ),
    );
  }

  Widget _buildExpandedControl(
      IconData icon, double rotation, bool enabled, VoidCallback onTap) {
    final currentRadius = context.watch<ChaosUIState>().chaosRadius;
    return AnimatedBuilder(
      animation: widget.chaosAnimationManager?.glitchController ??
          const AlwaysStoppedAnimation(0.0),
      builder: (context, child) {
        final glitchController = widget.chaosAnimationManager?.glitchController;
        final glitchOffset = glitchController?.isAnimating == true
            ? Offset(
                glitchController!.value * (math.Random().nextDouble() * 2 - 1),
                glitchController.value *
                    (math.Random().nextDouble() * 1.5 - 0.75),
              )
            : Offset.zero;

        return Transform.translate(
          offset: glitchOffset,
          child: Transform.rotate(
            angle: rotation,
            child: InkWell(
              onTap: () {
                onTap();
                HapticFeedback.selectionClick();
                widget.chaosAnimationManager?.triggerGlitch();
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: enabled
                        ? AntiiQTheme.of(context).colorScheme.primary
                        : AntiiQTheme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.3),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(currentRadius - 4),
                ),
                child: Icon(
                  icon,
                  color: enabled
                      ? AntiiQTheme.of(context).colorScheme.primary
                      : AntiiQTheme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                  size: 16,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DragLayer extends StatelessWidget {
  final Offset dragOffset;
  final AnimationController dragController;
  final ChaosMiniPlayerAnimationConfig config;
  final Widget child;

  const _DragLayer({
    required this.dragOffset,
    required this.dragController,
    required this.config,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: dragController,
      builder: (context, _) {
        final interpolatedOffset = Offset.lerp(
              dragOffset,
              Offset.zero,
              Curves.easeOutCubic.transform(dragController.value),
            ) ??
            Offset.zero;

        return Transform.translate(
          offset: interpolatedOffset * config.dragVisualDampening,
          child: child,
        );
      },
    );
  }
}
