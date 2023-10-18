/*

This Renders the screen for Album songs

*/

import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/utilities/file_handling/lists.dart';
import 'package:flutter/material.dart';
import 'package:text_scroll/text_scroll.dart';

//Antiiq Packages
import 'package:antiiq/player/screens/albums/album.dart';
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/widgets/list_header.dart';
import 'package:antiiq/player/widgets/image_widgets.dart';

class AlbumsGrid extends StatelessWidget {
  const AlbumsGrid({
    super.key,
  });

  final headerTitle = "Albums";

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
          listToCount: currentAlbumListSort,
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
                  crossAxisCount: 2),
              physics: const BouncingScrollPhysics(),
              primary: true,
              itemCount: currentAlbumListSort.length,
              itemBuilder: (context, index) {
                final Album thisAlbum = currentAlbumListSort[index];
                return AlbumItem(
                  title: TextScroll(
                    thisAlbum.albumName!,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                    velocity: defaultTextScrollvelocity,
                    delayBefore: delayBeforeScroll,
                  ),
                  subtitle: TextScroll(
                    thisAlbum.albumArtistName!,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                    velocity: defaultTextScrollvelocity,
                    delayBefore: delayBeforeScroll,
                  ),
                  leading: getUriImage(thisAlbum.albumArt),
                  album: thisAlbum,
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
