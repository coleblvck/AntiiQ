/*

This Renders the screen for all songs

*/

import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:flutter/material.dart';
import 'package:text_scroll/text_scroll.dart';

//Antiiq Packages
import 'package:antiiq/player/screens/selection/selection_song.dart';
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/widgets/list_header.dart';
import 'package:antiiq/player/widgets/image_widgets.dart';

class SelectionList extends StatelessWidget {
  const SelectionList({
    super.key,
  });

  final headerTitle = "Selection";

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Track>>(
        stream: globalSelectionStream.stream,
        builder: (context, snapshot) {
          final List<Track> selectionSituation = snapshot.data ?? globalSelection;
          return Column(
            children: [
              Divider(
                color: Theme.of(context).colorScheme.secondary,
                height: 1,
              ),
              ListHeader(
                headerTitle: headerTitle,
                listToCount: selectionSituation,
                listToShuffle: selectionSituation,
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
                    itemExtent: 100,
                    itemCount: selectionSituation.length,
                    itemBuilder: (context, index) {
                      final Track thisTrack = selectionSituation[index];
                      return SelectionSong(
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
                        album: selectionSituation,
                        index: index,
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        });
  }
}
