import 'dart:io';
import 'package:antiiq/chaos/chaos_global_constants.dart';
import 'package:antiiq/chaos/chaos_ui_state.dart';
import 'package:antiiq/chaos/widgets/track_details_sheet.dart';
import 'package:antiiq/chaos/page_manager.dart';
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/widgets/image_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';
import 'package:text_scroll/text_scroll.dart';

/// Header for Album view (used in TrackList.header)
class AlbumHeader extends StatelessWidget {
  final Album album;
  final Function()? onMenuPress;

  const AlbumHeader({
    super.key,
    required this.album,
    this.onMenuPress,
  });

  @override
  Widget build(BuildContext context) {
    final pageManagerController = ChaosPageManagerNavigator.of(context);
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
            // Album art
            StreamBuilder<ArtFit>(
              stream: coverArtFitStream.stream,
              builder: (context, snapshot) {
                final fit = snapshot.data ?? currentCoverArtFit;
                return Container(
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
                    child: Image.file(
                      File.fromUri(album.albumArt!),
                      fit:
                          fit == ArtFit.contain ? BoxFit.contain : BoxFit.cover,
                    ),
                  ),
                );
              },
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
                              album.albumName!,
                              style: TextStyle(
                                color:
                                    AntiiQTheme.of(context).colorScheme.primary,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                              velocity: defaultTextScrollvelocity,
                              delayBefore: delayBeforeScroll,
                            ),
                            const SizedBox(height: 4),
                            TextScroll(
                              album.albumArtistName!,
                              style: TextStyle(
                                color: AntiiQTheme.of(context)
                                    .colorScheme
                                    .onBackground,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                              velocity: defaultTextScrollvelocity,
                              delayBefore: delayBeforeScroll,
                            ),
                            if (album.year != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${album.year}',
                                style: TextStyle(
                                  color: AntiiQTheme.of(context)
                                      .colorScheme
                                      .onBackground
                                      .withValues(alpha: 0.6),
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onMenuPress?.call() ??
                              showTrackDetailsSheet(context, album.albumTracks!,
                                  pageManagerController: pageManagerController);
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
                            RemixIcon.menu_4,
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
                      '${album.albumTracks!.length} TRACK${album.albumTracks!.length != 1 ? 'S' : ''}',
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

/// Header for Artist view
class ArtistHeader extends StatelessWidget {
  final Artist artist;
  final Function()? onMenuPress;

  const ArtistHeader({
    super.key,
    required this.artist,
    this.onMenuPress,
  });

  @override
  Widget build(BuildContext context) {
    final pageManagerController = ChaosPageManagerNavigator.of(context);
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
            // Artist art
            Container(
              height: 200,
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
                child: getUriImage(artist.artistArt),
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
                        child: TextScroll(
                          artist.artistName!,
                          style: TextStyle(
                            color: AntiiQTheme.of(context).colorScheme.primary,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                          velocity: defaultTextScrollvelocity,
                          delayBefore: delayBeforeScroll,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onMenuPress?.call() ??
                              showTrackDetailsSheet(
                                  context, artist.artistTracks!,
                                  pageManagerController: pageManagerController);
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
                            RemixIcon.menu_4,
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
                      '${artist.artistTracks!.length} TRACK${artist.artistTracks!.length != 1 ? 'S' : ''}',
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

/// Header for Genre view
class GenreHeader extends StatelessWidget {
  final Genre genre;
  final Function()? onMenuPress;

  const GenreHeader({
    super.key,
    required this.genre,
    this.onMenuPress,
  });

  @override
  Widget build(BuildContext context) {
    final pageManagerController = ChaosPageManagerNavigator.of(context);
    final outerRadius = context.watch<ChaosUIState>().chaosRadius;
    final innerRadius = (outerRadius - 2);

    return Padding(
      padding: const EdgeInsets.all(chaosBasePadding),
      child: Container(
        padding: const EdgeInsets.all(chaosBasePadding * 2),
        decoration: BoxDecoration(
          color: AntiiQTheme.of(context).colorScheme.background,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: chaosBasePadding,
                      vertical: chaosBasePadding / 2),
                  decoration: BoxDecoration(
                    color: AntiiQTheme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(innerRadius),
                  ),
                  child: Text(
                    'GENRE',
                    style: TextStyle(
                      color: AntiiQTheme.of(context).colorScheme.onPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onMenuPress?.call() ??
                        showTrackDetailsSheet(context, genre.genreTracks!,
                            pageManagerController: pageManagerController);
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
                      RemixIcon.menu_4,
                      color: AntiiQTheme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextScroll(
              genre.genreName!,
              style: TextStyle(
                color: AntiiQTheme.of(context).colorScheme.primary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
              velocity: defaultTextScrollvelocity,
              delayBefore: delayBeforeScroll,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: chaosBasePadding, vertical: chaosBasePadding / 2),
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
                '${genre.genreTracks!.length} TRACK${genre.genreTracks!.length != 1 ? 'S' : ''}',
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
    );
  }
}
