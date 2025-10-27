import 'dart:io';
import 'package:antiiq/chaos/chaos_global_constants.dart';
import 'package:antiiq/chaos/chaos_ui_state.dart';
import 'package:antiiq/chaos/utilities/angle.dart';
import 'package:chaos_ui/chaos_rotation.dart';
import 'package:antiiq/chaos/utilities/open_collection.dart';
import 'package:antiiq/chaos/widgets/track_details_sheet.dart';
import 'package:antiiq/chaos/page_manager.dart';
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';
import 'package:text_scroll/text_scroll.dart';

class GenresGrid extends StatelessWidget {
  const GenresGrid({
    required this.scrollController,
    super.key,
  });

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final chaosUIState = context.watch<ChaosUIState>();
    final chaosLevel = chaosUIState.chaosLevel;
    return StreamBuilder<List<Genre>>(
      stream: antiiqState.music.genres.flow.stream,
      builder: (context, snapshot) {
        final genres = snapshot.data ?? antiiqState.music.genres.list;

        return MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: Scrollbar(
            controller: scrollController,
            scrollbarOrientation: ScrollbarOrientation.left,
            child: GridView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(chaosBasePadding),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: chaosBasePadding,
                mainAxisSpacing: chaosBasePadding,
                childAspectRatio: 0.75,
              ),
              physics: const BouncingScrollPhysics(),
              itemCount: genres.length,
              itemBuilder: (context, index) {
                return ChaosRotatedStatefulWidget(
                    angle: ChaosRotation.calculate(
                      index: index + 10,
                      style: ChaosRotationStyle.fibonacci,
                      maxAngle: getAnglePercentage(0.05, chaosLevel),
                    ),
                    child: _GenreGridItem(genre: genres[index]));
              },
            ),
          ),
        );
      },
    );
  }
}

class _GenreGridItem extends StatelessWidget {
  final Genre genre;

  const _GenreGridItem({required this.genre});

  @override
  Widget build(BuildContext context) {
    final pageManagerController = ChaosPageManagerNavigator.of(context);
    final chaosUIState = context.watch<ChaosUIState>();
    final outerRadius = chaosUIState.chaosRadius;
    final innerRadius = chaosUIState.getAdjustedRadius(2);

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        openGenre(genre, pageManagerController);
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: AntiiQTheme.of(context)
                .colorScheme
                .primary
                .withValues(alpha: 0.4),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(outerRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Genre art (from first track)
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
                            File.fromUri(
                                genre.genreTracks![0].mediaItem!.artUri!),
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
                              showTrackDetailsSheet(context, genre.genreTracks!,
                                  pageManagerController: pageManagerController);
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AntiiQTheme.of(context)
                                    .colorScheme
                                    .background
                                    .withValues(alpha: 0.9),
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
                              child: Icon(
                                RemixIcon.menu_4,
                                color:
                                    AntiiQTheme.of(context).colorScheme.primary,
                                size: 16,
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
                    genre.genreName!,
                    style: TextStyle(
                      color: AntiiQTheme.of(context).colorScheme.onBackground,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                    velocity: defaultTextScrollvelocity,
                    delayBefore: delayBeforeScroll,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${genre.genreTracks!.length} TRACK${genre.genreTracks!.length != 1 ? 'S' : ''}',
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
          ],
        ),
      ),
    );
  }
}
