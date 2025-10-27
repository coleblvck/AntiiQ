import 'dart:math' as math;
import 'package:antiiq/chaos/chaos_global_constants.dart';
import 'package:antiiq/chaos/chaos_ui_state.dart';
import 'package:antiiq/chaos/utilities/angle.dart';
import 'package:chaos_ui/chaos_rotation.dart';
import 'package:antiiq/chaos/widgets/track_details_sheet.dart';
import 'package:antiiq/chaos/page_manager.dart';
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/state/list_states/playlists_state.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/activity_handlers.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/utilities/pick_and_crop.dart';
import 'package:antiiq/player/utilities/playlist_generator/playlist_generator.dart';
import 'package:antiiq/player/widgets/image_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';
import 'package:text_scroll/text_scroll.dart';

/// Playlists Grid - Main view for all playlists
class ChaosPlaylistsGrid extends StatefulWidget {
  const ChaosPlaylistsGrid({
    required this.scrollController,
    super.key,
  });

  final ScrollController scrollController;

  @override
  State<ChaosPlaylistsGrid> createState() => _ChaosPlaylistsGridState();
}

class _ChaosPlaylistsGridState extends State<ChaosPlaylistsGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _glitchController;

  @override
  void initState() {
    super.initState();
    _glitchController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _glitchController.dispose();
    super.dispose();
  }

  void _showCreatePlaylistSheet() {
    HapticFeedback.mediumImpact();
    _glitchController.forward().then((_) => _glitchController.reverse());

    showChaosPlaylistCreator(context, onCreated: () {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final chaosUIState = context.watch<ChaosUIState>();
    final innerRadius = chaosUIState.getAdjustedRadius(2);

    return Column(
      children: [
        // Create playlist button
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AntiiQTheme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(chaosBasePadding),
            child: GestureDetector(
              onTap: _showCreatePlaylistSheet,
              child: AnimatedBuilder(
                animation: _glitchController,
                builder: (context, child) {
                  final random = math.Random(42);
                  final glitchOffset = Offset(
                    _glitchController.value * (random.nextDouble() * 4 - 2),
                    _glitchController.value * (random.nextDouble() * 3 - 1.5),
                  );
                  return Transform.translate(
                    offset: glitchOffset,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AntiiQTheme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.5),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(innerRadius),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              RemixIcon.add,
                              color: AntiiQTheme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.5),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'CREATE PLAYLIST',
                              style: TextStyle(
                                color: AntiiQTheme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.5),
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        // Playlists grid
        Expanded(
          child: StreamBuilder<List<PlayList>>(
            stream: antiiqState.music.playlists.flow.stream,
            builder: (context, snapshot) {
              final playlists =
                  snapshot.data ?? antiiqState.music.playlists.list;

              if (playlists.isEmpty) {
                return Center(
                  child: Text(
                    'NO PLAYLISTS',
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
                  controller: widget.scrollController,
                  scrollbarOrientation: ScrollbarOrientation.left,
                  child: GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    controller: widget.scrollController,
                    padding: const EdgeInsets.all(chaosBasePadding),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: chaosBasePadding,
                      mainAxisSpacing: chaosBasePadding,
                    ),
                    itemCount: playlists.length,
                    itemBuilder: (context, index) {
                      return ChaosPlaylistCard(
                        playlist: playlists[index],
                        index: index,
                        onDeleted: () => setState(() {}),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Individual playlist card with glitch effect
class ChaosPlaylistCard extends StatefulWidget {
  final PlayList playlist;
  final int index;
  final VoidCallback onDeleted;

  const ChaosPlaylistCard({
    required this.playlist,
    required this.index,
    required this.onDeleted,
    super.key,
  });

  @override
  State<ChaosPlaylistCard> createState() => _ChaosPlaylistCardState();
}

class _ChaosPlaylistCardState extends State<ChaosPlaylistCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _glitchController;
  bool _isGlitching = false;

  @override
  void initState() {
    super.initState();
    _glitchController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
  }

  @override
  void dispose() {
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

  void _openPlaylist() {
    _triggerGlitch();
    HapticFeedback.mediumImpact();

    final pageManagerController = ChaosPageManagerNavigator.of(context);
    openChaosPlaylist(context, widget.playlist, pageManagerController,
        onUpdate: widget.onDeleted);
  }

  @override
  Widget build(BuildContext context) {
    final chaosUIState = context.watch<ChaosUIState>();
    final currentRadius = chaosUIState.chaosRadius;
    final chaosLevel = chaosUIState.chaosLevel;
    //final innerRadius = chaosUIState.getAdjustedRadius(2);

    final rotation = (widget.index % 5 - 2) * 0.02;

    return GestureDetector(
      onTap: _openPlaylist,
      child: ChaosRotatedStatefulWidget(
        angle: getAnglePercentage(rotation, chaosLevel),
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
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AntiiQTheme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.4),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(currentRadius),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(currentRadius),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Album art
                      Expanded(
                        flex: 3,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AntiiQTheme.of(context)
                                .colorScheme
                                .surface
                                .withValues(alpha: 0.3),
                          ),
                          child: getUriImage(widget.playlist.playlistArt),
                        ),
                      ),

                      // Info section
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AntiiQTheme.of(context).colorScheme.background,
                          border: Border(
                            top: BorderSide(
                              color: AntiiQTheme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ChaosRotatedStatefulWidget(
                              angle: getAnglePercentage(-rotation * 0.5, chaosLevel),
                              child: Text(
                                widget.playlist.playlistName!.toUpperCase(),
                                style: TextStyle(
                                  color: AntiiQTheme.of(context)
                                      .colorScheme
                                      .onBackground,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ChaosRotatedStatefulWidget(
                              angle: getAnglePercentage(rotation * 0.3, chaosLevel),
                              child: Text(
                                '${widget.playlist.playlistTracks!.length} TRACKS',
                                style: TextStyle(
                                  color: AntiiQTheme.of(context)
                                      .colorScheme
                                      .onBackground
                                      .withValues(alpha: 0.5),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

void openChaosPlaylist(
  BuildContext context,
  PlayList playlist,
  ChaosPageManagerController? pageManagerController, {
  VoidCallback? onUpdate,
}) {
  final scrollController = ScrollController();

  pageManagerController?.push(
    _ChaosPlaylistDetail(
      playlist: playlist,
      scrollController: scrollController,
      onUpdate: onUpdate,
      pageManagerController: pageManagerController,
    ),
    title: playlist.playlistName!.toUpperCase(),
    scrollController: scrollController,
    listToShuffle: playlist.playlistTracks,
    onPop: () {
      scrollController.dispose();
    },
  );
}

/// Playlist detail view with proper header and reorderable tracks
class _ChaosPlaylistDetail extends StatefulWidget {
  final PlayList playlist;
  final ScrollController scrollController;
  final VoidCallback? onUpdate;
  final ChaosPageManagerController? pageManagerController;

  const _ChaosPlaylistDetail({
    required this.playlist,
    required this.scrollController,
    required this.pageManagerController,
    this.onUpdate,
  });

  @override
  State<_ChaosPlaylistDetail> createState() => _ChaosPlaylistDetailState();
}

class _ChaosPlaylistDetailState extends State<_ChaosPlaylistDetail> {
  late List<Track> _tracks;

  @override
  void initState() {
    super.initState();
    _tracks = List.from(widget.playlist.playlistTracks!);
  }

  @override
  Widget build(BuildContext context) {
    final chaosUIState = context.watch<ChaosUIState>();
    final chaosLevel = chaosUIState.chaosLevel;
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: Scrollbar(
        controller: widget.scrollController,
        scrollbarOrientation: ScrollbarOrientation.left,
        child: CustomScrollView(
          controller: widget.scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Playlist header
            SliverToBoxAdapter(
              child: PlaylistHeader(
                playlist: widget.playlist,
                onEdit: () {
                  showChaosPlaylistEditor(
                    context,
                    widget.playlist,
                    onUpdate: widget.onUpdate,
                    pageManagerController: widget.pageManagerController,
                  );
                },
              ),
            ),

            // Reorderable track list
            SliverReorderableList(
              onReorder: (oldIndex, newIndex) async {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final track = _tracks.removeAt(oldIndex);
                  _tracks.insert(newIndex, track);
                });

                widget.playlist.playlistTracks!.clear();
                widget.playlist.playlistTracks!.addAll(_tracks);
                await antiiqState.music.playlists
                    .save(widget.playlist.playlistId!);
                widget.onUpdate?.call();

                HapticFeedback.lightImpact();
              },
              itemCount: _tracks.length,
              itemExtent: 80,
              itemBuilder: (context, index) {
                final track = _tracks[index];
                return ChaosRotatedStatefulWidget(
                  maxAngle: getAnglePercentage(0.1, chaosLevel),
                  key: ValueKey('chaos_${track.mediaItem!.id}'),
                  child: _ChaosPlaylistTrackItem(
                    key: ValueKey(track.mediaItem!.id),
                    track: track,
                    index: index,
                    playlist: widget.playlist,
                    onRemoved: () {
                      setState(() {
                        _tracks.removeAt(index);
                      });
                      widget.onUpdate?.call();
                    },
                    pageManagerController: widget.pageManagerController,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Playlist header with art, info, and edit button
class PlaylistHeader extends StatelessWidget {
  final PlayList playlist;
  final VoidCallback onEdit;

  const PlaylistHeader({
    super.key,
    required this.playlist,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final outerRadius = context.watch<ChaosUIState>().chaosRadius;
    final innerRadius = (outerRadius - 2);

    return Padding(
      padding: const EdgeInsets.all(chaosBasePadding),
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Playlist art
            Container(
              height: 280,
              decoration: BoxDecoration(
                color: AntiiQTheme.of(context)
                    .colorScheme
                    .surface
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(outerRadius),
                  topRight: Radius.circular(outerRadius),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(outerRadius),
                  topRight: Radius.circular(outerRadius),
                ),
                child: getUriImage(playlist.playlistArt),
              ),
            ),

            // Info section
            Container(
              padding: const EdgeInsets.all(chaosBasePadding * 2),
              decoration: BoxDecoration(
                color: AntiiQTheme.of(context).colorScheme.background,
                border: Border(
                  top: BorderSide(
                    color: AntiiQTheme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(outerRadius),
                  bottomRight: Radius.circular(outerRadius),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextScroll(
                              playlist.playlistName!,
                              style: TextStyle(
                                color:
                                    AntiiQTheme.of(context).colorScheme.primary,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                              velocity: defaultTextScrollvelocity,
                              delayBefore: delayBeforeScroll,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'PLAYLIST',
                              style: TextStyle(
                                color: AntiiQTheme.of(context)
                                    .colorScheme
                                    .onBackground
                                    .withValues(alpha: 0.6),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onEdit();
                        },
                        child: Container(
                          width: 44,
                          height: 44,
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
                          child: Icon(
                            RemixIcon.edit,
                            color: AntiiQTheme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: chaosBasePadding,
                        vertical: chaosBasePadding / 2),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AntiiQTheme.of(context)
                            .colorScheme
                            .secondary
                            .withValues(alpha: 0.5),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(innerRadius),
                    ),
                    child: Text(
                      '${playlist.playlistTracks!.length} TRACK${playlist.playlistTracks!.length != 1 ? 'S' : ''}',
                      style: TextStyle(
                        color: AntiiQTheme.of(context).colorScheme.secondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual track item with PageView for swipe actions
class _ChaosPlaylistTrackItem extends StatefulWidget {
  final Track track;
  final int index;
  final PlayList playlist;
  final VoidCallback onRemoved;
  final ChaosPageManagerController? pageManagerController;

  const _ChaosPlaylistTrackItem({
    required this.track,
    required this.index,
    required this.playlist,
    required this.onRemoved,
    required this.pageManagerController,
    super.key,
  });

  @override
  State<_ChaosPlaylistTrackItem> createState() =>
      _ChaosPlaylistTrackItemState();
}

class _ChaosPlaylistTrackItemState extends State<_ChaosPlaylistTrackItem>
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

  void _playTrack() {
    _triggerGlitch();
    HapticFeedback.mediumImpact();
    playFromList(
      widget.index,
      widget.playlist.playlistTracks!.map((e) => e.mediaItem!).toList(),
    );
  }

  void _removeTrack() async {
    // Show confirmation dialog
    final confirmed = await showChaosConfirmDialog(
      context,
      title: 'REMOVE TRACK',
      message:
          'Remove "${widget.track.trackData!.trackName}" from playlist "${widget.playlist.playlistName}"?',
      confirmText: 'REMOVE',
      confirmColor: Colors.red,
    );

    if (confirmed == true) {
      HapticFeedback.heavyImpact();
      await antiiqState.music.playlists.removeTrack(
        widget.playlist.playlistId!,
        widget.index,
      );
      widget.onRemoved();
    }
  }

  @override
  Widget build(BuildContext context) {
    final chaosUIState = context.watch<ChaosUIState>();
    final currentRadius = chaosUIState.chaosRadius;
    final chaosLevel = chaosUIState.chaosLevel;
    final innerRadius = chaosUIState.getAdjustedRadius(2);

    final rotation = (widget.index % 7 - 3) * 0.015;

    return ReorderableDelayedDragStartListener(
      index: widget.index,
      child: Padding(
        padding: const EdgeInsets.only(
          left: chaosBasePadding,
          right: chaosBasePadding,
          bottom: chaosBasePadding,
        ),
        child: ChaosRotatedStatefulWidget(
          angle: getAnglePercentage(rotation * 0.2, chaosLevel),
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
                    borderRadius: BorderRadius.circular(currentRadius),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(currentRadius),
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
      onTap: _playTrack,
      child: Container(
        padding: const EdgeInsets.all(chaosBasePadding),
        decoration: BoxDecoration(
          color: AntiiQTheme.of(context).colorScheme.background,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Row(
          children: [
            // Album art
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
                child: getChaosUriImage(widget.track.mediaItem!.artUri!),
              ),
            ),

            const SizedBox(width: 12),

            // Track info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextScroll(
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
                  const SizedBox(height: 4),
                  TextScroll(
                    widget.track.trackData!.trackArtistNames ??
                        "Unknown Artist",
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
                openTrackDetailsSheet(context, widget.track,
                    pageManagerController: widget.pageManagerController);
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

            // Delete button
            GestureDetector(
              onTap: _removeTrack,
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
                  RemixIcon.delete_bin_2,
                  color: Colors.red.withValues(alpha: 0.8),
                  size: 14,
                ),
              ),
            ),

            const SizedBox(width: 4),

            // Swipe indicator
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
          // Back indicator
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
          // Actions
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildAction(
                      'PLAY ONLY', AntiiQTheme.of(context).colorScheme.primary,
                      () {
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

/// Playlist creator sheet
void showChaosPlaylistCreator(BuildContext context, {VoidCallback? onCreated}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _ChaosPlaylistCreator(onCreated: onCreated),
  );
}

class _ChaosPlaylistCreator extends StatefulWidget {
  final VoidCallback? onCreated;

  const _ChaosPlaylistCreator({this.onCreated});

  @override
  State<_ChaosPlaylistCreator> createState() => _ChaosPlaylistCreatorState();
}

class _ChaosPlaylistCreatorState extends State<_ChaosPlaylistCreator> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  List<Track> _selectedTracks = [];
  List<Track> _searchResults = [];
  Uint8List? _art;

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _search(String term) {
    setState(() {
      _searchResults.clear();
      if (term.isNotEmpty) {
        for (Track track in antiiqState.music.tracks.list) {
          if (track.trackData!.trackName!
                  .toLowerCase()
                  .contains(term.toLowerCase()) ||
              track.trackData!.trackArtistNames!
                  .toLowerCase()
                  .contains(term.toLowerCase())) {
            _searchResults.add(track);
          }
        }
      }
    });
  }

  void _toggleTrack(Track track) {
    setState(() {
      if (_selectedTracks.contains(track)) {
        _selectedTracks.remove(track);
      } else {
        _selectedTracks.add(track);
      }
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _selectArt() async {
    _art = await pickAndCrop();
    setState(() {});
    HapticFeedback.mediumImpact();
  }

  Future<void> _create() async {
    if (_nameController.text.isNotEmpty) {
      await antiiqState.music.playlists.create(
        _nameController.text,
        tracks: _selectedTracks,
        art: _art,
      );
      if (mounted) {
        Navigator.of(context).pop();
        widget.onCreated?.call();
      }
      HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final chaosUIState = context.watch<ChaosUIState>();
    final currentRadius = chaosUIState.chaosRadius;
    final chaosLevel = chaosUIState.chaosLevel;
    final innerRadius = chaosUIState.getAdjustedRadius(2);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AntiiQTheme.of(context).colorScheme.background,
        border: Border.all(
          color: AntiiQTheme.of(context)
              .colorScheme
              .primary
              .withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(currentRadius),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(chaosBasePadding),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AntiiQTheme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
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
                    child: TextField(
                      controller: _nameController,
                      style: TextStyle(
                        color: AntiiQTheme.of(context).colorScheme.onBackground,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'PLAYLIST NAME',
                        hintStyle: TextStyle(
                          color: AntiiQTheme.of(context)
                              .colorScheme
                              .onBackground
                              .withValues(alpha: 0.4),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _selectArt,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AntiiQTheme.of(context)
                            .colorScheme
                            .secondary
                            .withValues(alpha: 0.5),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(innerRadius),
                    ),
                    child: Icon(
                      RemixIcon.image,
                      color: AntiiQTheme.of(context).colorScheme.secondary,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _create,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AntiiQTheme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.6),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(innerRadius),
                    ),
                    child: Icon(
                      RemixIcon.check,
                      color: AntiiQTheme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(chaosBasePadding),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
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
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _search,
                      style: TextStyle(
                        color: AntiiQTheme.of(context).colorScheme.onBackground,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'SEARCH TRACKS...',
                        hintStyle: TextStyle(
                          color: AntiiQTheme.of(context)
                              .colorScheme
                              .onBackground
                              .withValues(alpha: 0.4),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        _search("");
                      },
                      child: Icon(
                        RemixIcon.close,
                        color: AntiiQTheme.of(context)
                            .colorScheme
                            .onBackground
                            .withValues(alpha: 0.6),
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Selected count
          Container(
            padding: const EdgeInsets.only(bottom: chaosBasePadding),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AntiiQTheme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: chaosBasePadding),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_selectedTracks.length} SELECTED',
                  style: TextStyle(
                    color: AntiiQTheme.of(context)
                        .colorScheme
                        .secondary
                        .withValues(alpha: 0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ),
          // Track list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(
                  left: chaosBasePadding,
                  right: chaosBasePadding,
                  top: chaosBasePadding),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final track = _searchResults[index];
                final isSelected = _selectedTracks.contains(track);

                return ChaosRotatedStatefulWidget(
                  maxAngle: getAnglePercentage(0.1, chaosLevel),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: chaosBasePadding),
                    child: GestureDetector(
                      onTap: () => _toggleTrack(track),
                      child: Container(
                        height: 64,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AntiiQTheme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withValues(alpha: 0.1)
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? AntiiQTheme.of(context)
                                    .colorScheme
                                    .secondary
                                    .withValues(alpha: 0.6)
                                : AntiiQTheme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.2),
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(innerRadius),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AntiiQTheme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.3),
                                  width: 1,
                                ),
                                borderRadius:
                                    BorderRadius.circular(innerRadius),
                              ),
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(innerRadius),
                                child:
                                    getChaosUriImage(track.mediaItem!.artUri!),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    track.trackData!.trackName!,
                                    style: TextStyle(
                                      color: AntiiQTheme.of(context)
                                          .colorScheme
                                          .onBackground,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.6,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    track.trackData!.trackArtistNames ??
                                        "Unknown Artist",
                                    style: TextStyle(
                                      color: AntiiQTheme.of(context)
                                          .colorScheme
                                          .onBackground
                                          .withValues(alpha: 0.6),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AntiiQTheme.of(context)
                                        .colorScheme
                                        .secondary
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isSelected
                                      ? AntiiQTheme.of(context)
                                          .colorScheme
                                          .secondary
                                      : AntiiQTheme.of(context)
                                          .colorScheme
                                          .onBackground
                                          .withValues(alpha: 0.3),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: isSelected
                                  ? Icon(
                                      Icons.check,
                                      color: AntiiQTheme.of(context)
                                          .colorScheme
                                          .background,
                                      size: 14,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Playlist editor sheet
void showChaosPlaylistEditor(
  BuildContext context,
  PlayList playlist, {
  VoidCallback? onUpdate,
  ChaosPageManagerController? pageManagerController,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _ChaosPlaylistEditor(
      playlist: playlist,
      onUpdate: onUpdate,
      pageManagerController: pageManagerController,
    ),
  );
}

class _ChaosPlaylistEditor extends StatefulWidget {
  final PlayList playlist;
  final VoidCallback? onUpdate;
  final ChaosPageManagerController? pageManagerController;

  const _ChaosPlaylistEditor({
    required this.playlist,
    required this.pageManagerController,
    this.onUpdate,
  });

  @override
  State<_ChaosPlaylistEditor> createState() => _ChaosPlaylistEditorState();
}

class _ChaosPlaylistEditorState extends State<_ChaosPlaylistEditor> {
  late TextEditingController _nameController;
  Uint8List? _art;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.playlist.playlistName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectArt() async {
    _art = await pickAndCrop();
    setState(() {});
    HapticFeedback.mediumImpact();
  }

  Future<void> _update() async {
    await antiiqState.music.playlists.update(
      widget.playlist.playlistId!,
      name: _nameController.text,
      art: _art,
    );
    if (mounted) {
      Navigator.of(context).pop();
      widget.onUpdate?.call();
    }
    HapticFeedback.mediumImpact();
  }

  Future<void> _delete() async {
    final confirmed = await showChaosConfirmDialog(
      context,
      title: 'DELETE PLAYLIST',
      message:
          'Delete "${widget.playlist.playlistName}"? This cannot be undone.',
      confirmText: 'DELETE',
      confirmColor: Colors.red,
    );

    if (confirmed == true) {
      await antiiqState.music.playlists.delete(widget.playlist);
      if (mounted) {
        Navigator.of(context).pop();
        widget.pageManagerController?.pop();
        widget.onUpdate?.call();
      }
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final chaosUIState = context.watch<ChaosUIState>();
    final radius = chaosUIState.chaosRadius;
    final innerRadius = chaosUIState.getAdjustedRadius(2);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AntiiQTheme.of(context).colorScheme.background,
        border: Border.all(
          color: AntiiQTheme.of(context)
              .colorScheme
              .primary
              .withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(chaosBasePadding * 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Text(
              'EDIT PLAYLIST',
              style: TextStyle(
                color: AntiiQTheme.of(context).colorScheme.primary,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: chaosBasePadding * 2),

            // Name field
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
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
              child: TextField(
                controller: _nameController,
                style: TextStyle(
                  color: AntiiQTheme.of(context).colorScheme.onBackground,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'PLAYLIST NAME',
                  hintStyle: TextStyle(
                    color: AntiiQTheme.of(context)
                        .colorScheme
                        .onBackground
                        .withValues(alpha: 0.4),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),

            const SizedBox(height: chaosBasePadding),

            // Warning text
            Text(
              'Note: Art changes may require app restart',
              style: TextStyle(
                color: AntiiQTheme.of(context)
                    .colorScheme
                    .onBackground
                    .withValues(alpha: 0.5),
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: chaosBasePadding * 2),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _selectArt,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AntiiQTheme.of(context)
                              .colorScheme
                              .secondary
                              .withValues(alpha: 0.5),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(innerRadius),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              RemixIcon.image,
                              color:
                                  AntiiQTheme.of(context).colorScheme.secondary,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'IMAGE',
                              style: TextStyle(
                                color: AntiiQTheme.of(context)
                                    .colorScheme
                                    .secondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: chaosBasePadding),
                Expanded(
                  child: GestureDetector(
                    onTap: _update,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AntiiQTheme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.6),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(innerRadius),
                      ),
                      child: Center(
                        child: Text(
                          'UPDATE',
                          style: TextStyle(
                            color: AntiiQTheme.of(context).colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: chaosBasePadding),

            // Delete button
            GestureDetector(
              onTap: _delete,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.6),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(innerRadius),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        RemixIcon.delete_bin_2,
                        color: Colors.red.withValues(alpha: 0.8),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'DELETE PLAYLIST',
                        style: TextStyle(
                          color: Colors.red.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Add to playlist dialog (for selection)
void showChaosAddToPlaylist(BuildContext context, List<Track> tracks) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _ChaosAddToPlaylist(tracks: tracks),
  );
}

class _ChaosAddToPlaylist extends StatefulWidget {
  final List<Track> tracks;

  const _ChaosAddToPlaylist({required this.tracks});

  @override
  State<_ChaosAddToPlaylist> createState() => _ChaosAddToPlaylistState();
}

class _ChaosAddToPlaylistState extends State<_ChaosAddToPlaylist> {
  final TextEditingController _nameController = TextEditingController();
  Uint8List? _art;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectArt() async {
    _art = await pickAndCrop();
    setState(() {});
    HapticFeedback.mediumImpact();
  }

  Future<void> _createNew() async {
    if (_nameController.text.isNotEmpty) {
      await antiiqState.music.playlists.create(
        _nameController.text,
        tracks: widget.tracks,
        art: _art,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _addToExisting(PlayList playlist) async {
    await antiiqState.music.playlists.addTracks(
      playlist.playlistId!,
      widget.tracks,
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final chaosUIState = context.watch<ChaosUIState>();
    final currentRadius = chaosUIState.chaosRadius;
    final chaosLevel = chaosUIState.chaosLevel;
    final innerRadius = chaosUIState.getAdjustedRadius(2);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AntiiQTheme.of(context).colorScheme.background,
        border: Border.all(
          color: AntiiQTheme.of(context)
              .colorScheme
              .primary
              .withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(currentRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header - Create new
          Container(
            padding: const EdgeInsets.all(chaosBasePadding * 2),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AntiiQTheme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NEW PLAYLIST',
                  style: TextStyle(
                    color: AntiiQTheme.of(context).colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: chaosBasePadding),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
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
                        child: TextField(
                          controller: _nameController,
                          style: TextStyle(
                            color: AntiiQTheme.of(context)
                                .colorScheme
                                .onBackground,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'NAME',
                            hintStyle: TextStyle(
                              color: AntiiQTheme.of(context)
                                  .colorScheme
                                  .onBackground
                                  .withValues(alpha: 0.4),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _selectArt,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AntiiQTheme.of(context)
                                .colorScheme
                                .secondary
                                .withValues(alpha: 0.5),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(innerRadius),
                        ),
                        child: Icon(
                          RemixIcon.image,
                          color: AntiiQTheme.of(context).colorScheme.secondary,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _createNew,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AntiiQTheme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.6),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(innerRadius),
                        ),
                        child: Icon(
                          RemixIcon.check,
                          color: AntiiQTheme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Existing playlists
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AntiiQTheme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(chaosBasePadding * 2),
              child: Text(
                'ADD TO EXISTING',
                style: TextStyle(
                  color: AntiiQTheme.of(context)
                      .colorScheme
                      .onBackground
                      .withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(
                  top: chaosBasePadding,
                  left: chaosBasePadding,
                  right: chaosBasePadding),
              itemCount: antiiqState.music.playlists.list.length,
              itemBuilder: (context, index) {
                final playlist = antiiqState.music.playlists.list[index];
                return ChaosRotatedStatefulWidget(
                  maxAngle: getAnglePercentage(0.1, chaosLevel),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: chaosBasePadding),
                    child: GestureDetector(
                      onTap: () => _addToExisting(playlist),
                      child: Container(
                        height: 72,
                        padding: const EdgeInsets.all(6),
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
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AntiiQTheme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.3),
                                  width: 1,
                                ),
                                borderRadius:
                                    BorderRadius.circular(innerRadius),
                              ),
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(innerRadius),
                                child: getUriImage(playlist.playlistArt),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    playlist.playlistName!.toUpperCase(),
                                    style: TextStyle(
                                      color: AntiiQTheme.of(context)
                                          .colorScheme
                                          .onBackground,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${playlist.playlistTracks!.length} TRACKS',
                                    style: TextStyle(
                                      color: AntiiQTheme.of(context)
                                          .colorScheme
                                          .onBackground
                                          .withValues(alpha: 0.5),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.6,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Chaos-themed confirmation dialog
Future<bool?> showChaosConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmText,
  Color? confirmColor,
}) {
  final chaosUIState = context.read<ChaosUIState>();
  final radius = chaosUIState.chaosRadius;
  final innerRadius = (radius - 2);

  return showDialog<bool>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AntiiQTheme.of(context).colorScheme.background,
          border: Border.all(
            color: confirmColor?.withValues(alpha: 0.5) ??
                AntiiQTheme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.3),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(chaosBasePadding * 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: confirmColor ??
                      AntiiQTheme.of(context).colorScheme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: chaosBasePadding * 2),
              Text(
                message,
                style: TextStyle(
                  color: AntiiQTheme.of(context).colorScheme.onBackground,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: chaosBasePadding * 3),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop(false);
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AntiiQTheme.of(context)
                                .colorScheme
                                .onBackground
                                .withValues(alpha: 0.3),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(innerRadius),
                        ),
                        child: Center(
                          child: Text(
                            'CANCEL',
                            style: TextStyle(
                              color: AntiiQTheme.of(context)
                                  .colorScheme
                                  .onBackground
                                  .withValues(alpha: 0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: chaosBasePadding),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.of(context).pop(true);
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: (confirmColor ??
                                    AntiiQTheme.of(context).colorScheme.primary)
                                .withValues(alpha: 0.6),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(innerRadius),
                        ),
                        child: Center(
                          child: Text(
                            confirmText,
                            style: TextStyle(
                              color: confirmColor ??
                                  AntiiQTheme.of(context).colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
