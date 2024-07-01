import 'package:antiiq/player/screens/albums/album.dart';
import 'package:antiiq/player/screens/artists/artist.dart';
import 'package:antiiq/player/screens/genres/genre.dart';
import 'package:antiiq/player/screens/playlists/add_to_playlist.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
//Antiiq Packages
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/activity_handlers.dart';
import 'package:antiiq/player/utilities/duration_getters.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/widgets/image_widgets.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';
import 'package:text_scroll/text_scroll.dart';

findTrackAndOpenSheet(context, MediaItem item) {
  final Track track =
      antiiqState.music.tracks.list.firstWhere((track) => track.mediaItem == item);
  openSheetFromTrack(context, track);
}

openSheetFromTrack(context, Track track) {
  doThingsWithAudioSheet(context, [track]);
}

doThingsWithAudioSheet(context, List<Track> tracks,
    {bool thisGlobalSelection = false}) {
  showModalBottomSheet(
    enableDrag: true,
    shape: AntiiQTheme.of(context).bottomSheetShape,
    context: context,
    backgroundColor: AntiiQTheme.of(context).colorScheme.surface,
    builder: (context) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              tracks.length == 1
                  ? Column(
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 100,
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: getUriImage(tracks[0].mediaItem!.artUri),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    TextScroll(
                                      tracks[0].trackData!.trackName!,
                                      style: TextStyle(
                                        fontSize: 17,
                                        color: AntiiQTheme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        if (antiiqState.music.artists.list
                                            .map((artist) => artist.artistId)
                                            .toList()
                                            .contains(tracks[0]
                                                .trackData!
                                                .artistId)) {
                                          goToArtist(context, tracks);
                                        }
                                      },
                                      child: TextScroll(
                                        tracks[0].trackData!.trackArtistNames!,
                                        style: TextStyle(
                                          fontSize: 17,
                                          color: AntiiQTheme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        if (antiiqState.music.albums.list
                                            .map((album) => album.albumId)
                                            .toList()
                                            .contains(
                                                tracks[0].trackData!.albumId)) {
                                          goToAlbum(context, tracks);
                                        }
                                      },
                                      child: TextScroll(
                                        tracks[0].trackData!.albumName!,
                                        style: TextStyle(
                                          fontSize: 17,
                                          color: AntiiQTheme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        if (antiiqState.music.genres.list
                                            .map((genre) => genre.genreName)
                                            .toList()
                                            .contains(
                                                tracks[0].trackData!.genre)) {
                                          goToGenre(context, tracks);
                                        }
                                      },
                                      child: TextScroll(
                                        tracks[0].trackData!.genre!,
                                        style: TextStyle(
                                          fontSize: 17,
                                          color: AntiiQTheme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        StreamBuilder<List<Track>>(
                          stream: antiiqState.music.favourites.flow.stream,
                          builder: (context, snapshot) {
                            final List<Track> favouritesSituation =
                                snapshot.data ?? antiiqState.music.favourites.list;
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Favourite:",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: AntiiQTheme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        antiiqState.music.favourites.addOrRemove(tracks[0]),
                                    icon: const Icon(RemixIcon.heart_pulse),
                                    color:
                                        favouritesSituation.contains(tracks[0])
                                            ? Colors.red
                                            : Colors.white,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        StreamBuilder<List<Track>>(
                          stream: antiiqState.music.selection.flow.stream,
                          builder: (context, snapshot) {
                            final List<Track> selectionSituation =
                                snapshot.data ?? antiiqState.music.selection.list;
                            return CustomCard(
                              theme:
                                  AntiiQTheme.of(context).cardThemes.background,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Select Track:",
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: AntiiQTheme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                    Checkbox(
                                      checkColor: AntiiQTheme.of(context).colorScheme.primary,
                                      fillColor: WidgetStatePropertyAll(AntiiQTheme.of(context).colorScheme.surface),
                                      value: selectionSituation
                                          .contains(tracks[0]),
                                      onChanged: (value) {
                                        // Check back. Better solution needed.
                                        thisGlobalSelection && value == false
                                            ? Navigator.of(context).pop()
                                            : null;
                                        antiiqState.music.selection.selectOrDeselect(tracks[0]);
                                      },
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    )
                  : Container(),
              thisGlobalSelection
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Selection",
                            style: TextStyle(
                              color:
                                  AntiiQTheme.of(context).colorScheme.primary,
                              fontSize: 20,
                              decoration: TextDecoration.underline,
                              decorationColor:
                                  AntiiQTheme.of(context).colorScheme.primary,
                            ),
                          ),
                          Text(
                            "Selected Tracks: ${antiiqState.music.selection.list.length}",
                            style: AntiiQTheme.of(context)
                                .textStyles
                                .onSurfaceText,
                          ),
                        ],
                      ),
                    )
                  : Container(),
              CustomCard(
                theme: AntiiQTheme.of(context).cardThemes.background,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    "Length: ${totalDuration(tracks)}",
                    style: TextStyle(
                      color: AntiiQTheme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: Text("Available Options:",
                    style: TextStyle(
                      fontSize: 18,
                      color: AntiiQTheme.of(context).colorScheme.onSurface,
                    )),
              ),
              thisGlobalSelection
                  ? CustomButton(
                      style: ButtonStyles().style2,
                      function: () {
                        antiiqState.music.selection.clear();
                        Navigator.of(context).pop();
                      },
                      child: const Text("Clear Selection"),
                    )
                  : Container(),
              CustomButton(
                style: ButtonStyles().style1,
                function: () {
                  addSelectionToPlaylistDialog(context, tracks);
                },
                child: const Text("Add to Playlist"),
              ),
              CustomButton(
                style: ButtonStyles().style3,
                function: () {
                  playTracks(tracks);
                },
                child: Text("Play Track${tracks.length > 1 ? "s" : ""}"),
              ),
              tracks.length > 1
                  ? CustomButton(
                      style: ButtonStyles().style2,
                      function: () {
                        shuffleTracks(tracks);
                      },
                      child: const Text("Shuffle Tracks"),
                    )
                  : Container(),
            ],
          ),
        ),
      );
    },
  );
}

goToGenre(BuildContext context, List<Track> tracks) {
  showGenre(
    context,
    antiiqState.music.genres.list.firstWhere(
      (genre) => genre.genreName == tracks[0].trackData!.genre,
    ),
  );
}

goToArtist(BuildContext context, List<Track> tracks) {
  showArtist(
    context,
    antiiqState.music.artists.list.firstWhere(
      (artist) => artist.artistId == tracks[0].trackData!.artistId,
    ),
  );
}

goToAlbum(BuildContext context, List<Track> tracks) {
  showAlbum(
    context,
    antiiqState.music.albums.list.firstWhere(
      (album) => album.albumId == tracks[0].trackData!.albumId,
    ),
  );
}
