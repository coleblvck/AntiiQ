import 'package:antiiq/chaos/chaos_ui_state.dart';
import 'package:chaos_ui/chaos_rotation.dart';
import 'package:antiiq/chaos/utilities/open_collection.dart';
import 'package:antiiq/chaos/widgets/chaos/playlist.dart';
import 'package:antiiq/chaos/page_manager.dart';
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/activity_handlers.dart';
import 'package:antiiq/player/utilities/duration_getters.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/utilities/playlist_generator/playlist_generator.dart';
import 'package:antiiq/player/widgets/image_widgets.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';
import 'package:text_scroll/text_scroll.dart';

void findTrackAndOpenSheet(
  BuildContext context,
  MediaItem item, {
  ChaosPageManagerController? pageManagerController,
}) {
  final Track? track = findTrackFromMediaItem(item);
  if (track != null) {
    openTrackDetailsSheet(context, track,
        pageManagerController: pageManagerController);
  }
}

void openTrackDetailsSheet(
  BuildContext context,
  Track track, {
  ChaosPageManagerController? pageManagerController,
}) {
  showTrackDetailsSheet(context, [track],
      pageManagerController: pageManagerController);
}

void showTrackDetailsSheet(
  BuildContext context,
  List<Track> tracks, {
  bool thisGlobalSelection = false,
  ChaosPageManagerController? pageManagerController,
}) {
  final chaosUIState = context.read<ChaosUIState>();
  final innerRadius = chaosUIState.getAdjustedRadius(2);

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => Container(
      margin: const EdgeInsets.all(4),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: AntiiQTheme.of(context).colorScheme.background,
        border: Border.all(
          color: AntiiQTheme.of(context)
              .colorScheme
              .primary
              .withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(chaosUIState.chaosRadius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
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
                Text(
                  thisGlobalSelection
                      ? 'SELECTION'
                      : '${tracks.length == 1 ? "TRACK " : ""}DETAILS',
                  style: TextStyle(
                    color: AntiiQTheme.of(context).colorScheme.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: 32,
                    height: 32,
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
                      Icons.close,
                      color: AntiiQTheme.of(context).colorScheme.primary,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Single track info
                  if (tracks.length == 1) ...[
                    _TrackInfoSection(track: tracks[0], radius: innerRadius),
                    const SizedBox(height: 12),
                    _TrackMetadataLinks(
                      track: tracks[0],
                      radius: innerRadius,
                      pageManagerController: pageManagerController,
                    ),
                    const SizedBox(height: 12),
                    _FavouriteToggle(track: tracks[0], radius: innerRadius),
                    const SizedBox(height: 12),
                    _SelectionToggle(
                      track: tracks[0],
                      radius: innerRadius,
                      thisGlobalSelection: thisGlobalSelection,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Selection summary
                  if (thisGlobalSelection) ...[
                    _SelectionSummary(tracks: tracks, radius: innerRadius),
                    const SizedBox(height: 12),
                  ],

                  // Duration info
                  _DurationInfo(tracks: tracks, radius: innerRadius),

                  const SizedBox(height: 16),

                  // Actions
                  Text(
                    'ACTIONS',
                    style: TextStyle(
                      color: AntiiQTheme.of(context)
                          .colorScheme
                          .onBackground
                          .withValues(alpha: 0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Similar tracks (single track only)
                  if (tracks.length == 1)
                    _ActionButton(
                      label: 'SIMILAR TRACKS',
                      icon: RemixIcon.shuffle,
                      color: AntiiQTheme.of(context).colorScheme.secondary,
                      radius: innerRadius,
                      onTap: () async {
                        HapticFeedback.mediumImpact();
                        await playlistGenerator.generatePlaylist(
                          type: PlaylistType.similarToTrack,
                          seedTrack: tracks[0],
                          similarityThreshold: 0.3,
                          maxTracks: 50,
                        );
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    ),

                  // Clear selection
                  if (thisGlobalSelection)
                    _ActionButton(
                      label: 'CLEAR SELECTION',
                      icon: RemixIcon.close_circle,
                      color: AntiiQTheme.of(context).colorScheme.error,
                      radius: innerRadius,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        antiiqState.music.selection.clear();
                        Navigator.of(context).pop();
                      },
                    ),

                  // Add to playlist
                  _ActionButton(
                    label: 'ADD TO PLAYLIST',
                    icon: RemixIcon.play_list_add,
                    color: AntiiQTheme.of(context).colorScheme.primary,
                    radius: innerRadius,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      showChaosAddToPlaylist(context, tracks);
                    },
                  ),

                  // Play
                  _ActionButton(
                    label:
                        'PLAY ${tracks.length > 1 ? '${tracks.length} TRACKS' : 'TRACK'}',
                    icon: RemixIcon.play_circle,
                    color: AntiiQTheme.of(context).colorScheme.primary,
                    radius: innerRadius,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      playTracks(tracks);
                      Navigator.of(context).pop();
                    },
                  ),

                  // Shuffle (multiple tracks)
                  if (tracks.length > 1)
                    _ActionButton(
                      label: 'SHUFFLE TRACKS',
                      icon: RemixIcon.shuffle,
                      color: AntiiQTheme.of(context).colorScheme.secondary,
                      radius: innerRadius,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        shuffleTracks(tracks);
                        Navigator.of(context).pop();
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// Single track info with artwork
class _TrackInfoSection extends StatelessWidget {
  final Track track;
  final double radius;

  const _TrackInfoSection({required this.track, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            AntiiQTheme.of(context).colorScheme.surface.withValues(alpha: 0.2),
        border: Border.all(
          color: AntiiQTheme.of(context)
              .colorScheme
              .surface
              .withValues(alpha: 0.5),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              border: Border.all(
                color: AntiiQTheme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(radius),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: getUriImage(track.mediaItem!.artUri),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextScroll(
                  track.trackData!.trackName!,
                  style: TextStyle(
                    color: AntiiQTheme.of(context).colorScheme.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                  velocity: defaultTextScrollvelocity,
                  delayBefore: delayBeforeScroll,
                ),
                const SizedBox(height: 4),
                TextScroll(
                  track.trackData!.trackArtistNames ?? 'Unknown Artist',
                  style: TextStyle(
                    color: AntiiQTheme.of(context).colorScheme.onBackground,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  velocity: defaultTextScrollvelocity,
                  delayBefore: delayBeforeScroll,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Metadata links (album, artist, genre)
class _TrackMetadataLinks extends StatelessWidget {
  final Track track;
  final double radius;

  final ChaosPageManagerController? pageManagerController;

  const _TrackMetadataLinks(
      {required this.track, required this.radius, this.pageManagerController});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            AntiiQTheme.of(context).colorScheme.surface.withValues(alpha: 0.2),
        border: Border.all(
          color: AntiiQTheme.of(context)
              .colorScheme
              .surface
              .withValues(alpha: 0.5),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GO TO',
            style: TextStyle(
              color: AntiiQTheme.of(context)
                  .colorScheme
                  .onBackground
                  .withValues(alpha: 0.6),
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),

          // Album
          if (antiiqState.music.albums.list
              .any((album) => album.albumId == track.trackData!.albumId))
            _MetadataLink(
              label: track.trackData!.albumName!,
              icon: RemixIcon.album,
              radius: radius,
              onTap: () {
                HapticFeedback.lightImpact();
                final album = antiiqState.music.albums.list.firstWhere(
                  (album) => album.albumId == track.trackData!.albumId,
                );
                openAlbum(album, pageManagerController);
                Navigator.of(context).pop();
              },
            ),

          // Artist
          if (antiiqState.music.artists.list
              .any((artist) => artist.artistId == track.trackData!.artistId))
            _MetadataLink(
              label: track.trackData!.trackArtistNames!,
              icon: RemixIcon.user,
              radius: radius,
              onTap: () {
                HapticFeedback.lightImpact();
                final artist = antiiqState.music.artists.list.firstWhere(
                  (artist) => artist.artistId == track.trackData!.artistId,
                );
                openArtist(artist, pageManagerController);
                Navigator.of(context).pop();
              },
            ),

          // Genre
          if (track.trackData!.genre != null &&
              antiiqState.music.genres.list
                  .any((genre) => genre.genreName == track.trackData!.genre))
            _MetadataLink(
              label: track.trackData!.genre!,
              icon: RemixIcon.music_2,
              radius: radius,
              onTap: () {
                HapticFeedback.lightImpact();
                final genre = antiiqState.music.genres.list.firstWhere(
                  (genre) => genre.genreName == track.trackData!.genre,
                );
                openGenre(genre, pageManagerController);
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }
}

class _MetadataLink extends StatelessWidget {
  final String label;
  final IconData icon;
  final double radius;
  final VoidCallback onTap;

  const _MetadataLink({
    required this.label,
    required this.icon,
    required this.radius,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChaosRotatedStatefulWidget(
      maxAngle: 0.08,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: AntiiQTheme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(radius),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: AntiiQTheme.of(context).colorScheme.primary,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: AntiiQTheme.of(context).colorScheme.onBackground,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.arrow_forward,
                  color: AntiiQTheme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.5),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Favourite toggle
class _FavouriteToggle extends StatelessWidget {
  final Track track;
  final double radius;

  const _FavouriteToggle({required this.track, required this.radius});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Track>>(
      stream: antiiqState.music.favourites.flow.stream,
      builder: (context, snapshot) {
        final favourites = snapshot.data ?? antiiqState.music.favourites.list;
        final isFavourite = favourites.contains(track);

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            antiiqState.music.favourites.addOrRemove(track);
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isFavourite
                  ? AntiiQTheme.of(context)
                      .colorScheme
                      .error
                      .withValues(alpha: 0.1)
                  : Colors.transparent,
              border: Border.all(
                color: isFavourite
                    ? AntiiQTheme.of(context).colorScheme.error
                    : AntiiQTheme.of(context)
                        .colorScheme
                        .surface
                        .withValues(alpha: 0.5),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(radius),
            ),
            child: Row(
              children: [
                Icon(
                  RemixIcon.heart_pulse,
                  color: isFavourite
                      ? AntiiQTheme.of(context).colorScheme.error
                      : AntiiQTheme.of(context)
                          .colorScheme
                          .onBackground
                          .withValues(alpha: 0.6),
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(
                  isFavourite ? 'REMOVE FROM FAVOURITES' : 'ADD TO FAVOURITES',
                  style: TextStyle(
                    color: isFavourite
                        ? AntiiQTheme.of(context).colorScheme.error
                        : AntiiQTheme.of(context).colorScheme.onBackground,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Selection toggle
class _SelectionToggle extends StatelessWidget {
  final Track track;
  final double radius;
  final bool thisGlobalSelection;

  const _SelectionToggle({
    required this.track,
    required this.radius,
    required this.thisGlobalSelection,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Track>>(
      stream: antiiqState.music.selection.flow.stream,
      builder: (context, snapshot) {
        final selection = snapshot.data ?? antiiqState.music.selection.list;
        final isSelected = selection.contains(track);

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            if (thisGlobalSelection && isSelected) {
              Navigator.of(context).pop();
            }
            antiiqState.music.selection.selectOrDeselect(track);
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AntiiQTheme.of(context)
                      .colorScheme
                      .secondary
                      .withValues(alpha: 0.1)
                  : Colors.transparent,
              border: Border.all(
                color: isSelected
                    ? AntiiQTheme.of(context).colorScheme.secondary
                    : AntiiQTheme.of(context)
                        .colorScheme
                        .surface
                        .withValues(alpha: 0.5),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(radius),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      RemixIcon.checkbox_circle,
                      color: isSelected
                          ? AntiiQTheme.of(context).colorScheme.secondary
                          : AntiiQTheme.of(context)
                              .colorScheme
                              .onBackground
                              .withValues(alpha: 0.6),
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isSelected ? 'SELECTED' : 'SELECT TRACK',
                      style: TextStyle(
                        color: isSelected
                            ? AntiiQTheme.of(context).colorScheme.secondary
                            : AntiiQTheme.of(context).colorScheme.onBackground,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                if (isSelected)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AntiiQTheme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Icon(
                      Icons.check,
                      color: AntiiQTheme.of(context).colorScheme.onSecondary,
                      size: 14,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Selection summary
class _SelectionSummary extends StatelessWidget {
  final List<Track> tracks;
  final double radius;

  const _SelectionSummary({required this.tracks, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AntiiQTheme.of(context)
            .colorScheme
            .secondary
            .withValues(alpha: 0.1),
        border: Border.all(
          color: AntiiQTheme.of(context)
              .colorScheme
              .secondary
              .withValues(alpha: 0.5),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Row(
        children: [
          Icon(
            RemixIcon.list_check_3,
            color: AntiiQTheme.of(context).colorScheme.secondary,
            size: 18,
          ),
          const SizedBox(width: 12),
          Text(
            '${antiiqState.music.selection.list.length} TRACK${antiiqState.music.selection.list.length != 1 ? 'S' : ''} SELECTED',
            style: TextStyle(
              color: AntiiQTheme.of(context).colorScheme.secondary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// Duration info
class _DurationInfo extends StatelessWidget {
  final List<Track> tracks;
  final double radius;

  const _DurationInfo({required this.tracks, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            AntiiQTheme.of(context).colorScheme.surface.withValues(alpha: 0.2),
        border: Border.all(
          color: AntiiQTheme.of(context)
              .colorScheme
              .surface
              .withValues(alpha: 0.5),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Row(
        children: [
          Icon(
            RemixIcon.time,
            color: AntiiQTheme.of(context)
                .colorScheme
                .onBackground
                .withValues(alpha: 0.6),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            totalDuration(tracks),
            style: TextStyle(
              color: AntiiQTheme.of(context).colorScheme.onBackground,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

// Action button
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final double radius;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.radius,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChaosRotatedStatefulWidget(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              border: Border.all(
                color: color.withValues(alpha: 0.5),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(radius),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
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
    );
  }
}
