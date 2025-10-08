import 'dart:math' as math;
import 'package:antiiq/chaos/chaos_global_constants.dart';
import 'package:antiiq/chaos/chaos_ui_state.dart';
import 'package:antiiq/chaos/widgets/track_details_sheet.dart';
import 'package:antiiq/chaos/page_manager.dart';
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/activity_handlers.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/utilities/playlist_generator/playlist_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';
import 'package:text_scroll/text_scroll.dart';

class TrackListItem extends StatefulWidget {
  final double rotation;
  final Color accentColor;
  final Widget leading;
  final Track track;
  final int index;
  final List albumToPlay;
  final VoidCallback? onTap;

  const TrackListItem({
    required this.rotation,
    required this.accentColor,
    required this.leading,
    required this.track,
    required this.index,
    required this.albumToPlay,
    this.onTap,
    super.key,
  });

  @override
  State<TrackListItem> createState() => _TrackListItemState();
}

class _TrackListItemState extends State<TrackListItem>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _glitchController;
  bool _isGlitching = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _glitchController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _glitchController.dispose();
    super.dispose();
  }

  void _triggerGlitch() {
    if (!_isGlitching && mounted) {
      _isGlitching = true;
      _glitchController.forward().then((_) {
        if (mounted) {
          _glitchController.reverse().then((_) {
            if (mounted) _isGlitching = false;
          });
        }
      });
    }
  }

  void _handleTap() {
    _triggerGlitch();
    HapticFeedback.mediumImpact();
    widget.onTap?.call();
  }

  void _handleLongPress() {
    if (antiiqState.music.selection.list.isEmpty) {
      _triggerGlitch();
      HapticFeedback.heavyImpact();
      antiiqState.music.selection.selectOrDeselect(widget.track);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chaosUIState = context.watch<ChaosUIState>();
    final outerRadius = chaosUIState.chaosRadius;
    final innerRadius = chaosUIState.getAdjustedRadius(2);

    return RepaintBoundary(
      child: Container(
        height: 72,
        margin: const EdgeInsets.only(bottom: chaosBasePadding),
        child: Transform.rotate(
          angle: widget.rotation * 0.2,
          child: _isGlitching
              ? AnimatedBuilder(
                  animation: _glitchController,
                  builder: (context, child) {
                    final random = math.Random(widget.index);
                    final glitchOffset = Offset(
                      _glitchController.value * (random.nextDouble() * 3 - 1.5),
                      _glitchController.value * (random.nextDouble() * 2 - 1),
                    );
                    return Transform.translate(
                      offset: glitchOffset,
                      child: _buildPageView(outerRadius, innerRadius),
                    );
                  },
                )
              : _buildPageView(outerRadius, innerRadius),
        ),
      ),
    );
  }

  Widget _buildPageView(double outerRadius, double innerRadius) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: widget.accentColor.withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(outerRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(outerRadius),
        child: PageView(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          children: [
            _buildMainCard(innerRadius),
            _buildActionsCard(innerRadius),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCard(double radius) {
    return StreamBuilder<List<Track>>(
      stream: antiiqState.music.selection.flow.stream,
      builder: (context, snapshot) {
        final selection = snapshot.data ?? antiiqState.music.selection.list;
        final isSelected = selection.contains(widget.track);

        return GestureDetector(
          onTap: _handleTap,
          onLongPress: _handleLongPress,
          child: Container(
            padding: const EdgeInsets.all(chaosBasePadding),
            decoration: BoxDecoration(
              color: isSelected
                  ? widget.accentColor.withValues(alpha: 0.1)
                  : AntiiQTheme.of(context).colorScheme.background,
              borderRadius: BorderRadius.circular(radius),
            ),
            child: Row(
              children: [
                _buildAlbumArt(radius),
                const SizedBox(width: 12),
                Expanded(child: _buildTrackInfo()),
                if (selection.isNotEmpty) ...[
                  _buildCheckbox(isSelected, radius),
                  const SizedBox(width: chaosBasePadding),
                ],
                _buildMenuButton(radius),
                const SizedBox(width: 4),
                _buildSwipeIndicator(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlbumArt(double radius) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: widget.accentColor.withValues(alpha: 0.15),
        border: Border.all(
          color: widget.accentColor.withValues(alpha: 0.4),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: widget.leading,
      ),
    );
  }

  Widget _buildTrackInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Transform.rotate(
          angle: -widget.rotation * 0.15,
          child: TextScroll(
            widget.track.trackData!.trackName!,
            textAlign: TextAlign.left,
            style: TextStyle(
              color: AntiiQTheme.of(context).colorScheme.onBackground,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
            velocity: defaultTextScrollvelocity,
            delayBefore: delayBeforeScroll,
          ),
        ),
        const SizedBox(height: 4),
        Transform.rotate(
          angle: widget.rotation * 0.1,
          child: TextScroll(
            widget.track.trackData!.trackArtistNames ?? "Unknown Artist",
            textAlign: TextAlign.left,
            style: TextStyle(
              color: AntiiQTheme.of(context)
                  .colorScheme
                  .onBackground
                  .withValues(alpha: 0.6),
              fontSize: 11,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
            ),
            velocity: defaultTextScrollvelocity,
            delayBefore: delayBeforeScroll,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckbox(bool isSelected, double innerRadius) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        antiiqState.music.selection.selectOrDeselect(widget.track);
      },
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: isSelected ? widget.accentColor : Colors.transparent,
          border: Border.all(
            color: widget.accentColor,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(innerRadius),
        ),
        child: isSelected
            ? Icon(
                Icons.check,
                color: AntiiQTheme.of(context).colorScheme.background,
                size: 16,
              )
            : null,
      ),
    );
  }

  Widget _buildMenuButton(double radius) {
    final pageManagerController = ChaosPageManagerNavigator.of(context);
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        openTrackDetailsSheet(context, widget.track,
            pageManagerController: pageManagerController);
      },
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(
            color: AntiiQTheme.of(context)
                .colorScheme
                .onBackground
                .withValues(alpha: 0.2),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Icon(
          RemixIcon.menu_4,
          color: AntiiQTheme.of(context)
              .colorScheme
              .onBackground
              .withValues(alpha: 0.6),
          size: 14,
        ),
      ),
    );
  }

  Widget _buildSwipeIndicator() {
    return Transform.rotate(
      angle: widget.rotation * 0.3,
      child: Icon(
        Icons.keyboard_arrow_left,
        color: widget.accentColor.withValues(alpha: 0.4),
        size: 20,
      ),
    );
  }

  Widget _buildActionsCard(double radius) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: widget.accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Column(
        children: [
          // Back indicator
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Icon(
                  Icons.keyboard_arrow_right,
                  color: widget.accentColor.withValues(alpha: 0.6),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'SWIPE RIGHT',
                  style: TextStyle(
                    color: widget.accentColor.withValues(alpha: 0.6),
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Actions
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildAction('PLAY ONLY', widget.accentColor, () {
                    playOnlyThis(widget.track.mediaItem!);
                    _pageController.jumpToPage(0);
                  }),
                  const SizedBox(width: 6),
                  _buildAction('NEXT', Colors.blue, () {
                    playTrackNext(widget.track.mediaItem!);
                    _pageController.jumpToPage(0);
                  }),
                  const SizedBox(width: 6),
                  _buildAction('LATER', Colors.orange, () {
                    addToQueue(widget.track.mediaItem!);
                    _pageController.jumpToPage(0);
                  }),
                  const SizedBox(width: 6),
                  _buildAction('SIMILAR', Colors.purple, () async {
                    await playlistGenerator.generatePlaylist(
                      type: PlaylistType.similarToTrack,
                      seedTrack: widget.track,
                      similarityThreshold: 0.3,
                      maxTracks: 50,
                    );
                    _pageController.jumpToPage(0);
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAction(String label, Color color, VoidCallback onTap) {
    final radius = context.watch<ChaosUIState>().chaosRadius;
    final actionRadius = (radius - 4);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _triggerGlitch();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: color.withValues(alpha: 0.6),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(actionRadius),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
