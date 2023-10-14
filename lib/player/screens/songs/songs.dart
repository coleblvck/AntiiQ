/*

This Renders the screen for all songs

*/

import 'package:antiiq/player/utilities/files/metadata.dart';
import 'package:flutter/material.dart';
import 'package:text_scroll/text_scroll.dart';

//Antiiq Packages
import 'package:antiiq/player/screens/songs/song.dart';
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/widgets/list_header.dart';
import 'package:antiiq/player/widgets/image_widgets.dart';
import 'package:antiiq/player/utilities/files/lists.dart';

class SongsList extends StatelessWidget {
  const SongsList({
    super.key,
  });

  final headerTitle = "Songs";

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
          listToCount: currentTrackListSort,
          listToShuffle: currentTrackListSort,
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
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              primary: true,
              itemExtent: 120,
              itemCount: currentTrackListSort.length,
              itemBuilder: (context, index) {
                final Track thisTrack = currentTrackListSort[index];
                return SongItem(
                  title: TextScroll(
                    thisTrack.trackData!.trackName!,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                    velocity: defaultTextScrollvelocity,
                    delayBefore: delayBeforeScroll,
                  ),
                  subtitle: TextScroll(
                    thisTrack.trackData!.trackArtistNames ?? "No Artist",
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                    velocity: defaultTextScrollvelocity,
                    delayBefore: delayBeforeScroll,
                  ),
                  leading: getUriImage(thisTrack.mediaItem!.artUri!),
                  track: thisTrack,
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
