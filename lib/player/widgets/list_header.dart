import 'package:antiiq/player/screens/selection_actions.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/activity_handlers.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/utilities/file_handling/sort.dart';
import 'package:flutter/material.dart';
//Icon Pack
import 'package:remix_icon_icons/remix_icon_icons.dart';

class ListHeader extends StatelessWidget {
  const ListHeader({
    super.key,
    required this.headerTitle,
    required this.listToCount,
    required this.listToShuffle,
    required this.sortList,
    required this.availableSortTypes,
    this.setState,
  });

  final String headerTitle;
  final dynamic listToCount;
  final List<Track> listToShuffle;
  final String sortList;
  final List<String> availableSortTypes;
  final Function? setState;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Column(
        children: [
          SizedBox(
            height: 45,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    "$headerTitle: ${listToCount.length}",
                    style: TextStyle(
                      color: AntiiQTheme.of(context).colorScheme.primary,
                      fontSize: 15,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Row(
                    children: [
                      StreamBuilder<List<Track>>(
                          stream: antiiqState.music.selection.flow.stream,
                          builder: (context, snapshot) {
                            final List<Track> selectionSituation =
                                snapshot.data ?? antiiqState.music.selection.list;
                            return selectionSituation.isNotEmpty
                                ? IconButton(
                                    padding: EdgeInsets.zero,
                                    color:
                                        AntiiQTheme.of(context).colorScheme.primary,
                                    iconSize: 15,
                                    onPressed: () {
                                      doThingsWithAudioSheet(
                                        context,
                                        selectionSituation,
                                        thisGlobalSelection: true,
                                      );
                                    },
                                    icon: const Icon(
                                      RemixIcon.list_check_3,
                                    ),
                                  )
                                : Container();
                          }),
                      listToShuffle.length > 1
                          ? IconButton(
                              padding: EdgeInsets.zero,
                              color: AntiiQTheme.of(context).colorScheme.primary,
                              iconSize: 15,
                              onPressed: () {
                                shuffleTracks(listToShuffle);
                              },
                              icon: const Icon(
                                RemixIcon.shuffle,
                              ),
                            )
                          : Container(),
                      availableSortTypes.isNotEmpty
                          ? IconButton(
                              padding: EdgeInsets.zero,
                              color: AntiiQTheme.of(context).colorScheme.primary,
                              iconSize: 15,
                              onPressed: () {
                                showSortModal(context, sortList, availableSortTypes,
                                    setState: setState);
                              },
                              icon: const Icon(RemixIcon.sort_asc),
                            )
                          : Container(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: AntiiQTheme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

showSortModal(context, String sortList, List<String> availableSortTypes,
    {setState}) {
  showModalBottomSheet(
    backgroundColor: AntiiQTheme.of(context).colorScheme.surface,
    shape: AntiiQTheme.of(context).bottomSheetShape,
    context: context,
    builder: (context) {
      commenceSort(sortType, sortDirection) {
        if (sortList == "allTracks") {
          beginSort(sortType, sortDirection, allTracks: true);
        } else if (sortList == "allAlbums") {
          beginSort(sortType, sortDirection, allAlbums: true);
        } else if (sortList == "allArtists") {
          beginSort(sortType, sortDirection, allArtists: true);
        } else if (sortList == "allGenres") {
          beginSort(sortType, sortDirection, allGenres: true);
        } else if (sortList == "allAlbumTracks") {
          beginSort(sortType, sortDirection, allAlbumTracks: true);
          setState(() {});
        } else if (sortList == "allArtistTracks") {
          beginSort(sortType, sortDirection, allArtistTracks: true);
          setState(() {});
        } else if (sortList == "allGenreTracks") {
          beginSort(sortType, sortDirection, allGenreTracks: true);
          setState(() {});
        }

        Navigator.of(context).pop();
      }

      late String currentDirection;
      late String currentSortType;
      if (sortList == "allTracks") {
        currentDirection = antiiqState.music.tracks.sort.currentDirection;
        currentSortType = antiiqState.music.tracks.sort.currentSort;
      } else if (sortList == "allAlbums") {
        currentDirection = antiiqState.music.albums.sort.currentDirection;
        currentSortType = antiiqState.music.albums.sort.currentSort;
      } else if (sortList == "allArtists") {
        currentDirection = antiiqState.music.artists.sort.currentDirection;
        currentSortType = antiiqState.music.artists.sort.currentSort;
      } else if (sortList == "allGenres") {
        currentDirection = antiiqState.music.genres.sort.currentDirection;
        currentSortType = antiiqState.music.genres.sort.currentSort;
      } else if (sortList == "allAlbumTracks") {
        currentDirection = antiiqState.music.albums.tracksSort.currentDirection;
        currentSortType = antiiqState.music.albums.tracksSort.currentSort;
      } else if (sortList == "allArtistTracks") {
        currentDirection = antiiqState.music.artists.tracksSort.currentDirection;
        currentSortType = antiiqState.music.artists.tracksSort.currentSort;
      } else if (sortList == "allGenreTracks") {
        currentDirection = antiiqState.music.genres.tracksSort.currentDirection;
        currentSortType = antiiqState.music.genres.tracksSort.currentSort;
      }

      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    "Sort by:",
                    style: TextStyle(
                      fontSize: 20,
                      color: AntiiQTheme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                for (String availableSortType in availableSortTypes)
                  GestureDetector(
                    onTap: () {
                      commenceSort(availableSortType, currentDirection);
                    },
                    child: Card(
                      color: AntiiQTheme.of(context).colorScheme.surface,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              availableSortType,
                              style: AntiiQTheme.of(context)
                                  .textStyles
                                  .onSurfaceText,
                            ),
                            sortList == "allTracks"
                                ? Checkbox(
                                    checkColor: AntiiQTheme.of(context)
                                        .colorScheme
                                        .primary,
                                    fillColor: WidgetStatePropertyAll(
                                        AntiiQTheme.of(context)
                                            .colorScheme
                                            .background),
                                    value: antiiqState.music.tracks.sort.currentSort ==
                                        availableSortType,
                                    onChanged: null,
                                  )
                                : sortList == "allAlbums"
                                    ? Checkbox(
                                        checkColor: AntiiQTheme.of(context)
                                            .colorScheme
                                            .primary,
                                        fillColor: WidgetStatePropertyAll(
                                            AntiiQTheme.of(context)
                                                .colorScheme
                                                .background),
                                        value: antiiqState.music.albums.sort.currentSort ==
                                            availableSortType,
                                        onChanged: null,
                                      )
                                    : sortList == "allArtists"
                                        ? Checkbox(
                                            checkColor: AntiiQTheme.of(context)
                                                .colorScheme
                                                .primary,
                                            fillColor: WidgetStatePropertyAll(
                                                AntiiQTheme.of(context)
                                                    .colorScheme
                                                    .background),
                                            value: antiiqState.music.artists.sort.currentSort ==
                                                availableSortType,
                                            onChanged: null,
                                          )
                                        : sortList == "allGenres"
                                            ? Checkbox(
                                                checkColor:
                                                    AntiiQTheme.of(context)
                                                        .colorScheme
                                                        .primary,
                                                fillColor:
                                                    WidgetStatePropertyAll(
                                                        AntiiQTheme.of(context)
                                                            .colorScheme
                                                            .background),
                                                value: antiiqState.music.genres.sort.currentSort ==
                                                    availableSortType,
                                                onChanged: null,
                                              )
                                            : sortList == "allAlbumTracks"
                                                ? Checkbox(
                                                    checkColor:
                                                        AntiiQTheme.of(context)
                                                            .colorScheme
                                                            .primary,
                                                    fillColor:
                                                        WidgetStatePropertyAll(
                                                            AntiiQTheme.of(
                                                                    context)
                                                                .colorScheme
                                                                .background),
                                                    value: antiiqState.music.albums.tracksSort
                                                            .currentSort ==
                                                        availableSortType,
                                                    onChanged: null,
                                                  )
                                                : sortList == "allArtistTracks"
                                                    ? Checkbox(
                                                        checkColor:
                                                            AntiiQTheme.of(
                                                                    context)
                                                                .colorScheme
                                                                .primary,
                                                        fillColor:
                                                            WidgetStatePropertyAll(
                                                                AntiiQTheme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .background),
                                                        value: antiiqState.music.artists.tracksSort
                                                                .currentSort ==
                                                            availableSortType,
                                                        onChanged: null,
                                                      )
                                                    : sortList ==
                                                            "allGenreTracks"
                                                        ? Checkbox(
                                                            checkColor:
                                                                AntiiQTheme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .primary,
                                                            fillColor: WidgetStatePropertyAll(
                                                                AntiiQTheme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .background),
                                                            value: antiiqState.music.genres.tracksSort
                                                                    .currentSort ==
                                                                availableSortType,
                                                            onChanged: null,
                                                          )
                                                        : Container(),
                          ],
                        ),
                      ),
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: AntiiQTheme.of(context).colorScheme.background,
                  ),
                  child: Row(
                    children: [
                      for (String key in sortDirections.keys)
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (currentDirection != key) {
                                commenceSort(currentSortType, key);
                              }
                            },
                            child: Card(
                              color: currentDirection == key
                                  ? AntiiQTheme.of(context).colorScheme.surface
                                  : Colors.transparent,
                              shadowColor: Colors.transparent,
                              surfaceTintColor: Colors.transparent,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    key,
                                    style: TextStyle(
                                      color: AntiiQTheme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              ]),
        ),
      );
    },
  );
}
