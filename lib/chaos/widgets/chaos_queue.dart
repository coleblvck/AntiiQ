import 'dart:math' as math;
import 'package:antiiq/chaos/chaos_global_constants.dart';
import 'package:antiiq/chaos/chaos_ui_state.dart';
import 'package:antiiq/chaos/utilities/chaos_rotation.dart';
import 'package:antiiq/chaos/widgets/track_details_sheet.dart';
import 'package:antiiq/chaos/page_manager.dart';
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/widgets/image_widgets.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';
import 'package:text_scroll/text_scroll.dart';

class ChaosQueue extends StatelessWidget {
  final ScrollController scrollController;
  const ChaosQueue({
    required this.scrollController,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MediaItem>>(
      stream: globalAntiiqAudioHandler.queue,
      builder: (context, snapshot) {
        final queue = snapshot.data ?? [];

        if (queue.isEmpty) {
          return Center(
            child: Text(
              'QUEUE EMPTY',
              style: TextStyle(
                color: AntiiQTheme.of(context)
                    .colorScheme
                    .onBackground
                    .withValues(alpha: 0.3),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          );
        }

        return MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: Scrollbar(
            controller: scrollController,
            scrollbarOrientation: ScrollbarOrientation.left,
            child: CustomScrollView(
              controller: scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _QueueHeader(queueLength: queue.length),
                ),
                SliverReorderableList(
                  onReorder: (oldIndex, newIndex) async {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }

                    await globalAntiiqAudioHandler.moveQueueItem(
                        oldIndex, newIndex);

                    HapticFeedback.lightImpact();
                  },
                  onReorderStart: (p0) {
                    HapticFeedback.lightImpact();
                  },
                  itemCount: queue.length,
                  itemBuilder: (context, index) {
                    return ChaosQueueItem(
                      key: ValueKey(queue[index].id),
                      item: queue[index],
                      index: index,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QueueHeader extends StatelessWidget {
  final int queueLength;

  const _QueueHeader({required this.queueLength});

  @override
  Widget build(BuildContext context) {
    final chaosUIState = context.watch<ChaosUIState>();
    final innerRadius = chaosUIState.getAdjustedRadius(2);

    return Container(
      margin: const EdgeInsets.all(chaosBasePadding),
      padding: const EdgeInsets.symmetric(
        horizontal: chaosBasePadding * 2,
        vertical: chaosBasePadding,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: AntiiQTheme.of(context)
              .colorScheme
              .primary
              .withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(innerRadius),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'UP NEXT',
            style: TextStyle(
              color: AntiiQTheme.of(context).colorScheme.primary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: chaosBasePadding,
              vertical: chaosBasePadding / 2,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: AntiiQTheme.of(context)
                    .colorScheme
                    .secondary
                    .withValues(alpha: 0.5),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(innerRadius - 2),
            ),
            child: Text(
              '$queueLength TRACK${queueLength != 1 ? 'S' : ''}',
              style: TextStyle(
                color: AntiiQTheme.of(context).colorScheme.secondary,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChaosQueueItem extends StatefulWidget {
  final MediaItem item;
  final int index;

  const ChaosQueueItem({
    required this.item,
    required this.index,
    super.key,
  });

  @override
  State<ChaosQueueItem> createState() => _ChaosQueueItemState();
}

class _ChaosQueueItemState extends State<ChaosQueueItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _glitchController;
  late PageController _pageController;
  bool _isGlitching = false;

  @override
  void initState() {
    super.initState();
    _glitchController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _pageController = PageController();
  }

  @override
  void dispose() {
    _glitchController.dispose();
    _pageController.dispose();
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

  void _skipToItem() {
    _triggerGlitch();
    HapticFeedback.mediumImpact();
    globalAntiiqAudioHandler.skipToQueueItem(widget.index);
  }

  void _removeFromQueue() {
    HapticFeedback.lightImpact();
    globalAntiiqAudioHandler.removeQueueItemAt(widget.index);
  }

  @override
  Widget build(BuildContext context) {
    final chaosUIState = context.watch<ChaosUIState>();
    final outerRadius = chaosUIState.chaosRadius;
    final innerRadius = chaosUIState.getAdjustedRadius(2);

    final rotation = ChaosRotation.calculate(
      index: widget.index + 1,
      style: ChaosRotationStyle.fibonacci,
      maxAngle: 0.05,
    );

    return ReorderableDelayedDragStartListener(
      index: widget.index,
      child: Padding(
        padding: const EdgeInsets.only(
          left: chaosBasePadding,
          right: chaosBasePadding,
          bottom: chaosBasePadding,
        ),
        child: Transform.rotate(
          angle: rotation,
          child: AnimatedBuilder(
            animation: _glitchController,
            builder: (context, child) {
              final random = math.Random(widget.index);
              final glitchOffset = _isGlitching
                  ? Offset(
                      _glitchController.value * (random.nextDouble() * 3 - 1.5),
                      _glitchController.value * (random.nextDouble() * 2 - 1),
                    )
                  : Offset.zero;

              return Transform.translate(
                offset: glitchOffset,
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AntiiQTheme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.3),
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
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMainCard(double radius) {
    return GestureDetector(
      onTap: _skipToItem,
      child: Container(
        padding: const EdgeInsets.all(chaosBasePadding),
        decoration: BoxDecoration(
          color: AntiiQTheme.of(context).colorScheme.background,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AntiiQTheme.of(context)
                      .colorScheme
                      .secondary
                      .withValues(alpha: 0.5),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(radius),
              ),
              child: Center(
                child: Text(
                  '${widget.index + 1}',
                  style: TextStyle(
                    color: AntiiQTheme.of(context).colorScheme.secondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AntiiQTheme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.4),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(radius),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: getChaosUriImage(widget.item.artUri!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextScroll(
                    widget.item.title,
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
                  const SizedBox(height: 4),
                  TextScroll(
                    widget.item.artist ?? "Unknown Artist",
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
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                final pageManagerController =
                    ChaosPageManagerNavigator.of(context);
                findTrackAndOpenSheet(
                  context,
                  widget.item,
                  pageManagerController: pageManagerController,
                );
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AntiiQTheme.of(context)
                        .colorScheme
                        .onBackground
                        .withValues(alpha: 0.3),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(radius),
                ),
                child: Icon(
                  RemixIcon.menu_4,
                  color: AntiiQTheme.of(context)
                      .colorScheme
                      .onBackground
                      .withValues(alpha: 0.5),
                  size: 14,
                ),
              ),
            ),
            const SizedBox(width: chaosBasePadding),
            GestureDetector(
              onTap: _removeFromQueue,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.5),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(radius),
                ),
                child: Icon(
                  RemixIcon.close,
                  color: Colors.red.withValues(alpha: 0.8),
                  size: 14,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_left,
              color: AntiiQTheme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard(double radius) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color:
            AntiiQTheme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Icon(
                  Icons.keyboard_arrow_right,
                  color: AntiiQTheme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.6),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'SWIPE RIGHT',
                  style: TextStyle(
                    color: AntiiQTheme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.6),
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildAction(
                      'PLAY NOW', AntiiQTheme.of(context).colorScheme.primary,
                      () {
                    _skipToItem();
                    _pageController.jumpToPage(0);
                  }),
                  const SizedBox(width: 6),
                  _buildAction('MOVE TOP', Colors.blue, () {
                    globalAntiiqAudioHandler.moveQueueItem(widget.index, 0);
                    _pageController.jumpToPage(0);
                  }),
                  const SizedBox(width: 6),
                  _buildAction('MOVE END', Colors.orange, () async {
                    final queueLength = globalAntiiqAudioHandler.queueLength;
                    if (queueLength > 0) {
                      await globalAntiiqAudioHandler.moveQueueItem(
                        widget.index,
                        queueLength - 1,
                      );
                    }
                    _pageController.jumpToPage(0);
                  }),
                  const SizedBox(width: 6),
                  _buildAction('REMOVE', Colors.red, () {
                    _removeFromQueue();
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
