/*

This Renders the screen for all songs

*/

import 'package:antiiq/player/global_variables.dart';
//Antiiq Packages
import 'package:antiiq/player/screens/songs/song.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/utilities/file_handling/sort.dart';
import 'package:antiiq/player/widgets/image_widgets.dart';
import 'package:antiiq/player/widgets/list_header.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:text_scroll/text_scroll.dart';

class SongsList extends StatelessWidget {
  const SongsList({
    super.key,
  });

  final headerTitle = "Songs";

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListHeader(
          headerTitle: headerTitle,
          listToCount: antiiqState.music.tracks.list,
          listToShuffle: antiiqState.music.tracks.list,
          sortList: "allTracks",
          availableSortTypes: trackListSortTypes,
        ),
        Expanded(
          child: CustomCard(
            theme: AntiiQTheme.of(context).cardThemes.background,
            child: Scrollbar(
              interactive: true,
              thickness: 18,
              radius: const Radius.circular(5),
              child: StreamBuilder<List<Track>>(
                stream: antiiqState.music.tracks.flow.stream,
                builder: (context, snapshot) {
                  final List<Track> allStreamTracks = snapshot.data ?? antiiqState.music.tracks.list;
                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    primary: true,
                    itemExtent: 100,
                    itemCount: allStreamTracks.length,
                    itemBuilder: (context, index) {
                      final Track thisTrack = allStreamTracks[index];
                      final List<MediaItem> allSongItems = allStreamTracks.map((e) => e.mediaItem!).toList();
                      return SongItem(
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
                        index: index,
                        allSongItems: allSongItems,
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
