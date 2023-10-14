/*

This Renders the screen for Album songs

*/

import 'package:antiiq/player/utilities/files/metadata.dart';
import 'package:antiiq/player/utilities/files/lists.dart';
import 'package:flutter/material.dart';
import 'package:text_scroll/text_scroll.dart';

//Antiiq Packages
import 'package:antiiq/player/screens/genres/genre.dart';
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/widgets/list_header.dart';

class GenresGrid extends StatelessWidget {
  const GenresGrid({
    super.key,
  });

  final headerTitle = "Genres";

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Divider(
          color: Theme.of(context).colorScheme.secondary,
          height: 1,
        ),
        ListHeader(
          headerTitle: headerTitle,
          listToCount: currentGenreListSort,
          listToShuffle: const [],
        ),
        Divider(
          color: Theme.of(context).colorScheme.secondary,
          height: 1,
        ),
        Expanded(
          child: Scrollbar(
            interactive: true,
            thickness: 18,
            radius: const Radius.circular(5),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
              ),
              physics: const BouncingScrollPhysics(),
              primary: true,
              itemCount: currentGenreListSort.length,
              itemBuilder: (context, index) {
                final Genre thisGenre = currentGenreListSort[index];
                return GenreItem(
                  title: TextScroll(
                    thisGenre.genreName!,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                    velocity: defaultTextScrollvelocity,
                    delayBefore: delayBeforeScroll,
                  ),
                  subtitle: TextScroll(
                    "${thisGenre.genreTracks!.length} ${(thisGenre.genreTracks!.length > 1) ? "Songs" : "song"}",
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                    velocity: defaultTextScrollvelocity,
                    delayBefore: delayBeforeScroll,
                  ),
                  genre: thisGenre,
                  index: index,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
