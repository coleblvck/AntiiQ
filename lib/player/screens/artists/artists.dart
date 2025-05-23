/*

This Renders the screen for Album songs

*/

import 'package:antiiq/player/global_variables.dart';
//Antiiq Packages
import 'package:antiiq/player/screens/artists/artist.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/utilities/file_handling/sort.dart';
import 'package:antiiq/player/widgets/image_widgets.dart';
import 'package:antiiq/player/widgets/list_header.dart';
import 'package:flutter/material.dart';
import 'package:text_scroll/text_scroll.dart';

class ArtistsList extends StatelessWidget {
  const ArtistsList({
    super.key,
  });

  final headerTitle = "Artists";

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListHeader(
          headerTitle: headerTitle,
          listToCount: antiiqState.music.artists.list,
          listToShuffle: const [],
          sortList: "allArtists",
          availableSortTypes: artistListSortTypes,
        ),
        Expanded(
          child: CustomCard(
            theme: AntiiQTheme.of(context).cardThemes.background,
            child: Scrollbar(
              interactive: true,
              thickness: 18,
              radius: const Radius.circular(5),
              child: StreamBuilder<List<Artist>>(
                stream: antiiqState.music.artists.flow.stream,
                builder: (context, snapshot) {
                  final List<Artist> currentArtistStream = snapshot.data ?? antiiqState.music.artists.list;
                  return ListView.builder(
                    itemExtent: 100,
                    physics: const BouncingScrollPhysics(),
                    primary: true,
                    itemCount: currentArtistStream.length,
                    itemBuilder: (context, index) {
                      final Artist thisArtist = currentArtistStream[index];
                      return ArtistItem(
                        title: TextScroll(
                          thisArtist.artistName!,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: AntiiQTheme.of(context).colorScheme.onBackground,
                          ),
                          velocity: defaultTextScrollvelocity,
                          delayBefore: delayBeforeScroll,
                        ),
                        subtitle: TextScroll(
                          "${thisArtist.artistTracks!.length} ${(thisArtist.artistTracks!.length > 1) ? "Songs" : "song"}",
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: AntiiQTheme.of(context).colorScheme.onBackground,
                          ),
                          velocity: defaultTextScrollvelocity,
                          delayBefore: delayBeforeScroll,
                        ),
                        leading: getUriImage(thisArtist.artistArt),
                        artist: thisArtist,
                        index: index,
                      );
                    },
                  );
                }
              ),
            ),
          ),
        ),
      ],
    );
  }
}
