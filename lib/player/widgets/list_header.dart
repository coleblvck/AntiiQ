//Flutter Packages
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/screens/selection_actions.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/utilities/file_handling/sort.dart';
import 'package:flutter/material.dart';

//Icon Pack
import 'package:remix_icon_icons/remix_icon_icons.dart';
import 'package:antiiq/player/utilities/activity_handlers.dart';

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
    return SizedBox(
      height: 45,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Text(
              "$headerTitle: ${listToCount.length}",
              style: TextStyle(
                color: AntiiQTheme.of(context).colorScheme.secondary,
                fontSize: 15,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              children: [
                StreamBuilder<List<Track>>(
                    stream: globalSelectionStream.stream,
                    builder: (context, snapshot) {
                      final List<Track> selectionSituation =
                          snapshot.data ?? globalSelection;
                      return selectionSituation.isNotEmpty
                          ? IconButton(
                              padding: EdgeInsets.zero,
                              color:
                                  AntiiQTheme.of(context).colorScheme.secondary,
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
                        color: AntiiQTheme.of(context).colorScheme.secondary,
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
                        color: AntiiQTheme.of(context).colorScheme.secondary,
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
    );
  }
}

showSortModal(context, String sortList, List<String> availableSortTypes,
    {setState}) {
  showModalBottomSheet(
    backgroundColor: AntiiQTheme.of(context).colorScheme.surface,
    shape: bottomSheetShape,
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
        currentDirection = trackSort.currentDirection;
        currentSortType = trackSort.currentSort;
      } else if (sortList == "allAlbums") {
        currentDirection = albumSort.currentDirection;
        currentSortType = albumSort.currentSort;
      } else if (sortList == "allArtists") {
        currentDirection = artistSort.currentDirection;
        currentSortType = artistSort.currentSort;
      } else if (sortList == "allGenres") {
        currentDirection = genreSort.currentDirection;
        currentSortType = genreSort.currentSort;
      } else if (sortList == "allAlbumTracks") {
        currentDirection = albumTracksSort.currentDirection;
        currentSortType = albumTracksSort.currentSort;
      } else if (sortList == "allArtistTracks") {
        currentDirection = artistTracksSort.currentDirection;
        currentSortType = artistTracksSort.currentSort;
      } else if (sortList == "allGenreTracks") {
        currentDirection = genreTracksSort.currentDirection;
        currentSortType = genreTracksSort.currentSort;
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
                                    value: trackSort.currentSort ==
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
                                        value: albumSort.currentSort ==
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
                                            value: artistSort.currentSort ==
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
                                                value: genreSort.currentSort ==
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
                                                    value: albumTracksSort
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
                                                        value: artistTracksSort
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
                                                            value: genreTracksSort
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
