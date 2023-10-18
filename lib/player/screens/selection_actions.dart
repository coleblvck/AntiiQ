import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/screens/albums/album.dart';
import 'package:antiiq/player/screens/artists/artist.dart';
import 'package:antiiq/player/screens/genres/genre.dart';
import 'package:antiiq/player/screens/playlists/add_to_playlist.dart';
import 'package:antiiq/player/utilities/activity_handlers.dart';
import 'package:antiiq/player/utilities/file_handling/lists.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';

//Antiiq Packages
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:text_scroll/text_scroll.dart';

findTrackAndOpenSheet(context, MediaItem item) {
  final Track track =
      currentTrackListSort.firstWhere((track) => track.mediaItem == item);
  openSheetFromTrack(context, track);
}

openSheetFromTrack(context, Track track) {
  doThingsWithAudioSheet(context, [track]);
}

doThingsWithAudioSheet(context, List<Track> tracks) {
  showModalBottomSheet(
    enableDrag: true,
    shape: bottomSheetShape,
    context: context,
    builder: (context) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Available Options:",
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.primary,
                    )),
              ),
              CustomButton(
                style: ButtonStyles().style1,
                function: () {
                  addSelectionToPlaylistDialog(context, tracks);
                },
                child: const Text("Add to Playlist"),
              ),
              tracks.length > 1
                  ? CustomButton(
                      style: ButtonStyles().style3,
                      function: () {
                        shuffleTracks(tracks);
                      },
                      child: const Text("Shuffle Tracks"),
                    )
                  : Container(),
              tracks.length == 1
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        currentAlbumListSort
                                .map((album) => album.albumId)
                                .toList()
                                .contains(tracks[0].trackData!.albumId)
                            ? CustomButton(
                                style: ButtonStyles().style2,
                                function: () {
                                  goToAlbum(context, tracks);
                                },
                                child: const Text("Go to Album"),
                              )
                            : Container(),
                        currentArtistListSort
                                .map((artist) => artist.artistId)
                                .toList()
                                .contains(tracks[0].trackData!.artistId)
                            ? CustomButton(
                                style: ButtonStyles().style3,
                                function: () {
                                  goToArtist(context, tracks);
                                },
                                child: const Text("Go to Artist"),
                              )
                            : Container(),
                        currentGenreListSort
                                .map((genre) => genre.genreName)
                                .toList()
                                .contains(tracks[0].trackData!.genre)
                            ? CustomButton(
                                style: ButtonStyles().style1,
                                function: () {
                                  goToGenre(context, tracks);
                                },
                                child: const Text("Go to Genre"),
                              )
                            : Container(),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            children: [
                              TextScroll(
                                tracks[0].trackData!.trackName!,
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              TextScroll(
                                tracks[0].trackData!.trackArtistNames!,
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              TextScroll(
                                tracks[0].trackData!.albumName!,
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
    currentGenreListSort.firstWhere(
      (genre) => genre.genreName == tracks[0].trackData!.genre,
    ),
  );
}

goToArtist(BuildContext context, List<Track> tracks) {
  showArtist(
    context,
    currentArtistListSort.firstWhere(
      (artist) => artist.artistId == tracks[0].trackData!.artistId,
    ),
  );
}

goToAlbum(BuildContext context, List<Track> tracks) {
  showAlbum(
    context,
    currentAlbumListSort.firstWhere(
      (album) => album.albumId == tracks[0].trackData!.albumId,
    ),
  );
}
