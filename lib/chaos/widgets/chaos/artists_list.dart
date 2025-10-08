import 'package:antiiq/chaos/chaos_global_constants.dart';
import 'package:antiiq/chaos/chaos_ui_state.dart';
import 'package:antiiq/chaos/utilities/chaos_rotation.dart';
import 'package:antiiq/chaos/utilities/open_collection.dart';
import 'package:antiiq/chaos/widgets/track_details_sheet.dart';
import 'package:antiiq/chaos/page_manager.dart';
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/widgets/image_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';
import 'package:text_scroll/text_scroll.dart';

class ArtistsList extends StatelessWidget {
  const ArtistsList({required this.scrollController, super.key});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Artist>>(
      stream: antiiqState.music.artists.flow.stream,
      builder: (context, snapshot) {
        final artists = snapshot.data ?? antiiqState.music.artists.list;

        return MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: Scrollbar(
            controller: scrollController,
            scrollbarOrientation: ScrollbarOrientation.left,
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.only(
                  top: chaosBasePadding,
                  left: chaosBasePadding,
                  right: chaosBasePadding),
              itemExtent: 80,
              physics: const BouncingScrollPhysics(),
              itemCount: artists.length,
              itemBuilder: (context, index) {
                return Transform.rotate(
                    angle: ChaosRotation.calculate(
                      index: index + 20,
                      style: ChaosRotationStyle.fibonacci,
                      maxAngle: 0.05,
                    ),
                    child: _ArtistListItem(artist: artists[index]));
              },
            ),
          ),
        );
      },
    );
  }
}

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
                  .primary
                  .withValues(alpha: 0.4),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(outerRadius),
          ),
          child: Row(
            children: [
              // Artist art
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AntiiQTheme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: 0.3),
                  border: Border.all(
                    color: AntiiQTheme.of(context)
                        .colorScheme
                        .secondary
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
                        fontSize: 14,
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
                  width: 40,
                  height: 40,
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
                    size: 18,
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
