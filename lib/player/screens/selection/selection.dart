/*

This Renders the screen for all songs

*/

import 'package:antiiq/player/global_variables.dart';
//Antiiq Packages
import 'package:antiiq/player/screens/selection/selection_song.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/widgets/image_widgets.dart';
import 'package:antiiq/player/widgets/list_header.dart';
import 'package:flutter/material.dart';
import 'package:text_scroll/text_scroll.dart';

class SelectionList extends StatelessWidget {
  const SelectionList({
    super.key,
  });

  final headerTitle = "Selection";

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Track>>(
        stream: antiiqState.music.selection.flow.stream,
        builder: (context, snapshot) {
          final List<Track> selectionSituation = snapshot.data ?? antiiqState.music.selection.list;
          return Column(
            children: [
              ListHeader(
                headerTitle: headerTitle,
                listToCount: selectionSituation,
                listToShuffle: selectionSituation,
                sortList: "none",
                availableSortTypes: const [],
              ),
              Expanded(
                child: CustomCard(
                  theme: AntiiQTheme.of(context).cardThemes.background,
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
                              color: AntiiQTheme.of(context).colorScheme.onBackground,
                            ),
                            velocity: defaultTextScrollvelocity,
                            delayBefore: delayBeforeScroll,
                          ),
                          subtitle: TextScroll(
                            thisTrack.trackData!.trackArtistNames ?? "No Artist",
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: AntiiQTheme.of(context).colorScheme.onBackground,
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
              ),
            ],
          );
        });
  }
}
