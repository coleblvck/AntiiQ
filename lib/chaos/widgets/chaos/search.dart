import 'dart:io';
import 'package:antiiq/chaos/chaos_global_constants.dart';
import 'package:antiiq/chaos/chaos_ui_state.dart';
import 'package:chaos_ui/chaos_rotation.dart';
import 'package:antiiq/chaos/utilities/open_collection.dart';
import 'package:antiiq/chaos/widgets/chaos/tracklist_item.dart';
import 'package:antiiq/chaos/widgets/track_details_sheet.dart';
import 'package:antiiq/chaos/page_manager.dart';
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/activity_handlers.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/widgets/image_widgets.dart';
import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';
import 'package:text_scroll/text_scroll.dart';

class ChaosSearch extends StatefulWidget {
  const ChaosSearch({super.key});

  @override
  State<ChaosSearch> createState() => _ChaosSearchState();
}

class _ChaosSearchState extends State<ChaosSearch> {
  List<Track> searchResults = [];
  List<Album> albumResults = [];
  List<Artist> artistResults = [];
  TextEditingController searchController = TextEditingController();
  FocusNode searchFocusNode = FocusNode();
  bool isSearching = false;

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  String _normalizeForSearch(String text) {
    // Remove diacritics, convert to lowercase, remove punctuation
    return removeDiacritics(text)
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Removes all punctuation
        .trim();
  }

  void search(String term) {
    if (term.isEmpty) {
      setState(() {
        searchResults = [];
        albumResults = [];
        artistResults = [];
        isSearching = false;
      });
      return;
    }

    final newTrackResults = <Track>[];
    final newAlbumResults = <Album>[];
    final newArtistResults = <Artist>[];
    final normalizedTerm = _normalizeForSearch(term);

    // Search tracks
    for (Track track in antiiqState.music.tracks.list) {
      final trackName = _normalizeForSearch(track.trackData?.trackName ?? '');
      final artistNames =
          _normalizeForSearch(track.trackData?.trackArtistNames ?? '');
      final albumName = _normalizeForSearch(track.trackData?.albumName ?? '');

      if (trackName.contains(normalizedTerm) ||
          artistNames.contains(normalizedTerm) ||
          albumName.contains(normalizedTerm)) {
        newTrackResults.add(track);
      }
    }

    // Search albums
    for (Album album in antiiqState.music.albums.list) {
      final albumName = _normalizeForSearch(album.albumName ?? '');

      if (albumName.contains(normalizedTerm)) {
        newAlbumResults.add(album);
      }
    }

    // Search artists
    for (Artist artist in antiiqState.music.artists.list) {
      final artistName = _normalizeForSearch(artist.artistName ?? '');

      if (artistName.contains(normalizedTerm)) {
        newArtistResults.add(artist);
      }
    }

    if (mounted) {
      setState(() {
        searchResults = newTrackResults;
        albumResults = newAlbumResults;
        artistResults = newArtistResults;
        isSearching = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chaosUIState = context.watch<ChaosUIState>();
    final radius = chaosUIState.chaosRadius;
    final innerRadius = chaosUIState.getAdjustedRadius(2);

    return Column(
      children: [
        // Search input
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
            child: Container(
              decoration: BoxDecoration(
                color: AntiiQTheme.of(context).colorScheme.background,
                border: Border.all(
                  color: AntiiQTheme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: searchFocusNode.hasFocus ? 0.6 : 0.3),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(radius),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      RemixIcon.search,
                      color: AntiiQTheme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      focusNode: searchFocusNode,
                      onTapOutside: (event) {
                        FocusScope.of(context).unfocus();
                      },
                      onChanged: search,
                      style: TextStyle(
                        color: AntiiQTheme.of(context).colorScheme.onBackground,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                      cursorColor: AntiiQTheme.of(context).colorScheme.primary,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'SEARCH TRACKS, ALBUMS, ARTISTS...',
                        hintStyle: TextStyle(
                          color: AntiiQTheme.of(context)
                              .colorScheme
                              .onBackground
                              .withValues(alpha: 0.4),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  if (searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        searchController.clear();
                        search("");
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AntiiQTheme.of(context)
                                .colorScheme
                                .error
                                .withValues(alpha: 0.4),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(innerRadius),
                        ),
                        child: Icon(
                          RemixIcon.close,
                          color: AntiiQTheme.of(context).colorScheme.error,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Results
        Expanded(
          child: !isSearching
              ? _buildEmptyState(radius)
              : _buildSearchResults(radius, innerRadius),
        ),
      ],
    );
  }

  Widget _buildEmptyState(double radius) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              border: Border.all(
                color: AntiiQTheme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.2),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(radius),
            ),
            child: Icon(
              RemixIcon.search_2,
              size: 40,
              color: AntiiQTheme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'START TYPING TO SEARCH',
            style: TextStyle(
              color: AntiiQTheme.of(context)
                  .colorScheme
                  .onBackground
                  .withValues(alpha: 0.4),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(double radius, double innerRadius) {
    final hasResults = searchResults.isNotEmpty ||
        albumResults.isNotEmpty ||
        artistResults.isNotEmpty;

    if (!hasResults) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AntiiQTheme.of(context)
                      .colorScheme
                      .error
                      .withValues(alpha: 0.3),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(radius),
              ),
              child: Icon(
                RemixIcon.file_forbid,
                size: 40,
                color: AntiiQTheme.of(context)
                    .colorScheme
                    .error
                    .withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'NO RESULTS FOUND',
              style: TextStyle(
                color: AntiiQTheme.of(context)
                    .colorScheme
                    .onBackground
                    .withValues(alpha: 0.4),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverPadding(padding: EdgeInsets.only(top: chaosBasePadding)),
        // Albums
        if (albumResults.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                chaosBasePadding,
                0,
                chaosBasePadding,
                chaosBasePadding,
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AntiiQTheme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ALBUMS',
                    style: TextStyle(
                      color: AntiiQTheme.of(context).colorScheme.secondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${albumResults.length}',
                    style: TextStyle(
                      color: AntiiQTheme.of(context)
                          .colorScheme
                          .onBackground
                          .withValues(alpha: 0.4),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: chaosBasePadding),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: chaosBasePadding,
                crossAxisSpacing: chaosBasePadding,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => Transform.rotate(
                    angle: ChaosRotation.calculate(
                      index: index + 1,
                      style: ChaosRotationStyle.fibonacci,
                      maxAngle: 0.05,
                    ),
                    child: _AlbumGridItem(album: albumResults[index])),
                childCount: albumResults.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: chaosBasePadding)),
        ],

        // Artists
        if (artistResults.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  chaosBasePadding, 0, chaosBasePadding, chaosBasePadding),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AntiiQTheme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ARTISTS',
                    style: TextStyle(
                      color: AntiiQTheme.of(context).colorScheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${artistResults.length}',
                    style: TextStyle(
                      color: AntiiQTheme.of(context)
                          .colorScheme
                          .onBackground
                          .withValues(alpha: 0.4),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: chaosBasePadding),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Transform.rotate(
                    angle: ChaosRotation.calculate(
                      index: index + 1,
                      style: ChaosRotationStyle.fibonacci,
                      maxAngle: 0.05,
                    ),
                    child: _ArtistListItem(artist: artistResults[index])),
                childCount: artistResults.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: chaosBasePadding)),
        ],

        // Tracks
        if (searchResults.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  chaosBasePadding, 0, chaosBasePadding, chaosBasePadding),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AntiiQTheme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'TRACKS',
                    style: TextStyle(
                      color: AntiiQTheme.of(context).colorScheme.secondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${searchResults.length}',
                    style: TextStyle(
                      color: AntiiQTheme.of(context)
                          .colorScheme
                          .onBackground
                          .withValues(alpha: 0.4),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                chaosBasePadding, 0, chaosBasePadding, chaosBasePadding),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final Track thisTrack = searchResults[index];
                  final rotation = ChaosRotation.calculate(
                    index: index + 1,
                    maxAngle: 0.5,
                    style: ChaosRotationStyle.random,
                  );
                  return TrackListItem(
                    key: ValueKey(thisTrack.mediaItem!.id),
                    leading: getChaosUriImage(thisTrack.mediaItem!.artUri!),
                    track: thisTrack,
                    index: index,
                    albumToPlay:
                        searchResults.map((e) => e.mediaItem!).toList(),
                    rotation: rotation,
                    accentColor: AntiiQTheme.of(context).colorScheme.secondary,
                    onTap: () {
                      playFromList(index,
                          searchResults.map((e) => e.mediaItem!).toList());
                    },
                  );
                },
                childCount: searchResults.length,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// Album Grid Item for Search
class _AlbumGridItem extends StatelessWidget {
  final Album album;

  const _AlbumGridItem({required this.album});

  @override
  Widget build(BuildContext context) {
    final pageManagerController = ChaosPageManagerNavigator.of(context);
    final chaosUIState = context.watch<ChaosUIState>();
    final outerRadius = chaosUIState.chaosRadius;
    final innerRadius = chaosUIState.getAdjustedRadius(2);

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        openAlbum(album, pageManagerController);
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: AntiiQTheme.of(context)
                .colorScheme
                .surface
                .withValues(alpha: 0.5),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(outerRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Album art
            Expanded(
              child: StreamBuilder<ArtFit>(
                stream: coverArtFitStream.stream,
                builder: (context, snapshot) {
                  final fit = snapshot.data ?? currentCoverArtFit;
                  return Container(
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
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(outerRadius),
                            topRight: Radius.circular(outerRadius),
                          ),
                          child: Image.file(
                            File.fromUri(album.albumArt!),
                            fit: fit == ArtFit.contain
                                ? BoxFit.contain
                                : BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),

                        // Menu button overlay
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              showTrackDetailsSheet(context, album.albumTracks!,
                                  pageManagerController: pageManagerController);
                            },
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AntiiQTheme.of(context)
                                    .colorScheme
                                    .background
                                    .withValues(alpha: 0.9),
                                border: Border.all(
                                  color: AntiiQTheme.of(context)
                                      .colorScheme
                                      .secondary
                                      .withValues(alpha: 0.3),
                                  width: 1,
                                ),
                                borderRadius:
                                    BorderRadius.circular(innerRadius),
                              ),
                              child: Icon(
                                RemixIcon.menu_4,
                                color: AntiiQTheme.of(context)
                                    .colorScheme
                                    .secondary,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Info section
            Container(
              padding: const EdgeInsets.all(chaosBasePadding),
              decoration: BoxDecoration(
                color: AntiiQTheme.of(context).colorScheme.background,
                border: Border(
                  top: BorderSide(
                    color: AntiiQTheme.of(context)
                        .colorScheme
                        .surface
                        .withValues(alpha: 0.5),
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
                  TextScroll(
                    album.albumName!,
                    style: TextStyle(
                      color: AntiiQTheme.of(context).colorScheme.onBackground,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                    velocity: defaultTextScrollvelocity,
                    delayBefore: delayBeforeScroll,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${album.numOfSongs} TRACK${album.numOfSongs != 1 ? 'S' : ''}',
                    style: TextStyle(
                      color: AntiiQTheme.of(context)
                          .colorScheme
                          .onBackground
                          .withValues(alpha: 0.5),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
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

// Artist List Item for Search
class _ArtistListItem extends StatelessWidget {
  final Artist artist;

  const _ArtistListItem({required this.artist});

  @override
  Widget build(BuildContext context) {
    final pageManagerController = ChaosPageManagerNavigator.of(context);
    final chaosUIState = context.watch<ChaosUIState>();
    final outerRadius = chaosUIState.chaosRadius;
    final innerRadius = chaosUIState.getAdjustedRadius(2);

    return Container(
      margin: const EdgeInsets.only(bottom: chaosBasePadding),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          openArtist(artist, pageManagerController);
        },
        child: Container(
          padding: const EdgeInsets.all(chaosBasePadding),
          decoration: BoxDecoration(
            color: AntiiQTheme.of(context).colorScheme.background,
            border: Border.all(
              color: AntiiQTheme.of(context)
                  .colorScheme
                  .surface
                  .withValues(alpha: 0.5),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(outerRadius),
          ),
          child: Row(
            children: [
              // Artist art
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AntiiQTheme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: 0.3),
                  border: Border.all(
                    color: AntiiQTheme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.4),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(innerRadius),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(innerRadius),
                  child: getUriImage(artist.artistArt),
                ),
              ),

              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextScroll(
                      artist.artistName!,
                      style: TextStyle(
                        color: AntiiQTheme.of(context).colorScheme.onBackground,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                      velocity: defaultTextScrollvelocity,
                      delayBefore: delayBeforeScroll,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${artist.artistTracks!.length} TRACK${artist.artistTracks!.length != 1 ? 'S' : ''}',
                      style: TextStyle(
                        color: AntiiQTheme.of(context)
                            .colorScheme
                            .onBackground
                            .withValues(alpha: 0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),

              // Menu button
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  showTrackDetailsSheet(context, artist.artistTracks!,
                      pageManagerController: pageManagerController);
                },
                child: Container(
                  width: 36,
                  height: 36,
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
                    RemixIcon.menu_4,
                    color: AntiiQTheme.of(context).colorScheme.primary,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
