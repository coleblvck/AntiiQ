import 'dart:io';

import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/screens/genres/genre_song.dart';
import 'package:antiiq/player/screens/selection_actions.dart';
import 'package:antiiq/player/utilities/files/metadata.dart';
import 'package:antiiq/player/widgets/list_header.dart';
import 'package:flutter/material.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';
import 'package:text_scroll/text_scroll.dart';

//Antiiq Packages
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/widgets/image_widgets.dart';

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
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: FileImage(
                File.fromUri(genre.genreTracks![0].mediaItem!.artUri!),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CustomCard(
                    theme: CardThemes().smallCardOnArtTheme,
                    child: IconButton(
                      onPressed: () {
                        doThingsWithAudioSheet(context, genre.genreTracks!);
                      },
                      icon: const Icon(RemixIcon.menu_4),
                    ),
                  ),
                ],
              ),
              CustomCard(
                theme: CardThemes().smallCardOnArtTheme,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
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
        ),
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
    backgroundColor: Theme.of(context).colorScheme.background,
    showDragHandle: true,
    barrierColor: Theme.of(context).colorScheme.background.withAlpha(200),
    shape: bottomSheetShape,
    context: context,
    builder: (context) => Padding(
      padding: const EdgeInsets.all(10.0),
      child: SizedBox(
        height: MediaQuery.of(context).size.height - 200,
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: TextScroll(
                        genre.genreName!,
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        velocity: defaultTextScrollvelocity,
                        delayBefore: delayBeforeScroll,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: ListHeader(
                      headerTitle: "Tracks",
                      listToCount: genre.genreTracks,
                      listToShuffle: genre.genreTracks!,
                    ),
                  ),
                  SliverList.builder(
                    itemCount: genre.genreTracks!.length,
                    itemBuilder: (context, index) {
                      final thisTrack = genre.genreTracks![index];
                      return GenreSong(
                        title: TextScroll(
                          thisTrack.trackData!.trackName!,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          velocity: defaultTextScrollvelocity,
                          delayBefore: delayBeforeScroll,
                        ),
                        subtitle: TextScroll(
                          thisTrack.mediaItem!.artist!,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
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
            ),
            CustomCard(
              theme: CardThemes().bottomSheetListHeaderTheme,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: TextScroll(
                        genre.genreName!,
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                        velocity: defaultTextScrollvelocity,
                        delayBefore: delayBeforeScroll,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(RemixIcon.arrow_down_double),
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
