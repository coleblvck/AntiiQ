import 'package:antiiq/chaos/widgets/chaos/collection_headers.dart';
import 'package:antiiq/chaos/widgets/chaos/tracklist.dart';
import 'package:antiiq/chaos/page_manager.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/utilities/file_handling/sort.dart';
import 'package:flutter/material.dart';

void openGenre(Genre genre, ChaosPageManagerController? pageManagerController) {
  final ScrollController scrollController = ScrollController();
  return pageManagerController?.push(
    StreamBuilder<List<Genre>>(
        stream: antiiqState.music.genres.flow.stream,
        builder: (context, snapshot) {
          return TrackList(
            tracks: genre.genreTracks!,
            accentColor: AntiiQTheme.of(context).colorScheme.primary,
            header: GenreHeader(genre: genre),
            scrollController: scrollController,
          );
        }),
    title: genre.genreName!.toUpperCase(),
    scrollController: scrollController,
    listToShuffle: genre.genreTracks!,
    sortList: "allGenreTracks",
    availableSortTypes: genreTrackListSortTypes,
    onPop: () {
      scrollController.dispose();
    },
  );
}

void openAlbum(Album album, ChaosPageManagerController? pageManagerController) {
  final ScrollController scrollController = ScrollController();
  return pageManagerController?.push(
    StreamBuilder<List<Album>>(
        stream: antiiqState.music.albums.flow.stream,
        builder: (context, snapshot) {
          return TrackList(
            tracks: album.albumTracks!,
            accentColor: AntiiQTheme.of(context).colorScheme.primary,
            header: AlbumHeader(album: album),
            scrollController: scrollController,
          );
        }),
    title: album.albumName!.toUpperCase(),
    scrollController: scrollController,
    listToShuffle: album.albumTracks!,
    sortList: "allAlbumTracks",
    availableSortTypes: albumTrackListSortTypes,
    onPop: () {
      scrollController.dispose();
    },
  );
}

void openArtist(
    Artist artist, ChaosPageManagerController? pageManagerController) {
  final ScrollController scrollController = ScrollController();
  pageManagerController?.push(
    StreamBuilder<List<Artist>>(
        stream: antiiqState.music.artists.flow.stream,
        builder: (context, snapshot) {
          return TrackList(
            tracks: artist.artistTracks!,
            accentColor: AntiiQTheme.of(context).colorScheme.primary,
            header: ArtistHeader(artist: artist),
            scrollController: scrollController,
          );
        }),
    title: artist.artistName!.toUpperCase(),
    scrollController: scrollController,
    listToShuffle: artist.artistTracks!,
    sortList: "allArtistTracks",
    availableSortTypes: artistTrackListSortTypes,
    onPop: () {
      scrollController.dispose();
    },
  );
}
