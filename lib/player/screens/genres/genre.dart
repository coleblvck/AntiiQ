import 'dart:io';

import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/screens/genres/genre_song.dart';
import 'package:antiiq/player/screens/selection_actions.dart';
//Antiiq Packages
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/utilities/file_handling/sort.dart';
import 'package:antiiq/player/widgets/collection_widgets/collection_heading.dart';
import 'package:antiiq/player/widgets/image_widgets.dart';
import 'package:antiiq/player/widgets/list_header.dart';
import 'package:flutter/material.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';
import 'package:text_scroll/text_scroll.dart';

class GenreItem extends StatelessWidget {
  final Widget title;
  final Widget subtitle;
  final Genre genre;
  final int index;
  const GenreItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.genre,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: GestureDetector(
        onTap: () {
          showGenre(context, genre);
        },
        child: StreamBuilder<ArtFit>(
            stream: coverArtFitStream.stream,
            builder: (context, snapshot) {
              final coverArtFit = snapshot.data ?? currentCoverArtFit;
              return Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: FileImage(
                      File.fromUri(genre.genreTracks![0].mediaItem!.artUri!),
                    ),
                    fit: coverArtFit == ArtFit.contain
                        ? BoxFit.contain
                        : BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(generalRadius),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        CustomCard(
                          theme: AntiiQTheme.of(context).cardThemes.background,
                          child: IconButton(
                            onPressed: () {
                              doThingsWithAudioSheet(
                                  context, genre.genreTracks!);
                            },
                            icon: Icon(
                              RemixIcon.menu_4,
                              color:
                                  AntiiQTheme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    CustomCard(
                      theme: AntiiQTheme.of(context).cardThemes.background,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 5.0, horizontal: 15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            title,
                            subtitle,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
      ),
    );
  }
}

showGenre(context, Genre genre) {
  showModalBottomSheet(
    useSafeArea: true,
    isDismissible: true,
    enableDrag: true,
    elevation: 10,
    isScrollControlled: true,
    backgroundColor: AntiiQTheme.of(context).colorScheme.background,
    showDragHandle: true,
    barrierColor: AntiiQTheme.of(context).colorScheme.background.withAlpha(200),
    shape: AntiiQTheme.of(context).bottomSheetShape,
    context: context,
    builder: (context) => Padding(
      padding: const EdgeInsets.all(10.0),
      child: SizedBox(
        height: MediaQuery.of(context).size.height - 200,
        child: Column(
          children: [
            StatefulBuilder(builder: (context, setState) {
              return Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: CollectionHeading(
                              headings: ["Genre: ${genre.genreName}"],
                              tracks: genre.genreTracks!)),
                    ),
                    SliverToBoxAdapter(
                      child: ListHeader(
                        headerTitle: "Tracks",
                        listToCount: genre.genreTracks,
                        listToShuffle: genre.genreTracks!,
                        sortList: "allGenreTracks",
                        availableSortTypes: genreTrackListSortTypes,
                        setState: setState,
                      ),
                    ),
                    SliverFixedExtentList.builder(
                      itemExtent: 100,
                      itemCount: genre.genreTracks!.length,
                      itemBuilder: (context, index) {
                        final thisTrack = genre.genreTracks![index];
                        return GenreSong(
                          title: TextScroll(
                            thisTrack.trackData!.trackName!,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: AntiiQTheme.of(context)
                                  .colorScheme
                                  .onBackground,
                            ),
                            velocity: defaultTextScrollvelocity,
                            delayBefore: delayBeforeScroll,
                          ),
                          subtitle: TextScroll(
                            thisTrack.mediaItem!.artist!,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: AntiiQTheme.of(context)
                                  .colorScheme
                                  .onBackground,
                            ),
                            velocity: defaultTextScrollvelocity,
                            delayBefore: delayBeforeScroll,
                          ),
                          leading: getUriImage(thisTrack.mediaItem!.artUri),
                          track: thisTrack,
                          genre: genre,
                          index: index,
                        );
                      },
                    )
                  ],
                ),
              );
            }),
            CustomCard(
              theme: AntiiQTheme.of(context).cardThemes.background,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: TextScroll(
                        genre.genreName!,
                        textAlign: TextAlign.left,
                        style:
                            AntiiQTheme.of(context).textStyles.onBackgroundText,
                        velocity: defaultTextScrollvelocity,
                        delayBefore: delayBeforeScroll,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: Icon(
                      RemixIcon.arrow_down_double,
                      color: AntiiQTheme.of(context).colorScheme.onBackground,
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
}
