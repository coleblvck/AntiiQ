import 'package:antiiq/chaos/chaos_global_constants.dart';
import 'package:antiiq/chaos/chaos_ui_state.dart';
import 'package:antiiq/chaos/utilities/angle.dart';
import 'package:chaos_ui/chaos_rotation.dart';
import 'package:antiiq/chaos/widgets/chaos/tracklist_item.dart';
import 'package:antiiq/player/utilities/activity_handlers.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/widgets/image_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Reusable track list that can optionally include collection headers
/// Use for all songs, albums, artists, genres, playlists, etc.
class TrackList extends StatelessWidget {
  const TrackList({
    super.key,
    required this.scrollController,
    required this.tracks,
    this.accentColor,
    this.header, // Optional header widget (album art, artist info, etc.)
    this.rotationStyle = ChaosRotationStyle.random,
    this.maxRotationAngle = 0.50,
    this.padding = const EdgeInsets.only(
        top: chaosBasePadding, left: chaosBasePadding, right: chaosBasePadding),
    this.playbackContext,
  });

  final ScrollController scrollController;
  final List<Track> tracks;
  final Color? accentColor;
  final Widget? header;
  final ChaosRotationStyle rotationStyle;
  final double maxRotationAngle;
  final EdgeInsets padding;
  final List<Track>? playbackContext;

  @override
  Widget build(BuildContext context) {
    final chaosUIState = context.watch<ChaosUIState>();
    final chaosLevel = chaosUIState.chaosLevel;
    final resolvedAccentColor =
        accentColor ?? AntiiQTheme.of(context).colorScheme.primary;
    final playbackTracks = playbackContext ?? tracks;
    final allSongItems = playbackTracks.map((e) => e.mediaItem!).toList();
    final rotations = ChaosRotation.generateList(
      count: tracks.length,
      style: rotationStyle,
      maxAngle: getAnglePercentage(maxRotationAngle, chaosLevel),
    );

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
            // Optional header (album art, artist info, genre details, etc.)
            if (header != null)
              SliverToBoxAdapter(
                child: header!,
              ),

            // Track list
            SliverPadding(
              padding: padding,
              sliver: SliverFixedExtentList.builder(
                itemCount: tracks.length,
                itemExtent: 80,
                itemBuilder: (context, index) {
                  final Track thisTrack = tracks[index];

                  return TrackListItem(
                    key: ValueKey(thisTrack.mediaItem!.id),
                    leading: getChaosUriImage(thisTrack.mediaItem!.artUri!),
                    track: thisTrack,
                    index: index,
                    albumToPlay: allSongItems,
                    rotation: rotations[index],
                    accentColor: resolvedAccentColor,
                    onTap: () {
                      final playbackIndex = playbackTracks.indexOf(thisTrack);
                      playFromList(
                          playbackIndex < 0 ? 0 : playbackIndex, allSongItems);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
