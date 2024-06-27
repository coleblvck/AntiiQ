import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/state/list_states/albums_state.dart';
import 'package:antiiq/player/state/list_states/artists_state.dart';
import 'package:antiiq/player/state/list_states/favourites_state.dart';
import 'package:antiiq/player/state/list_states/genres_state.dart';
import 'package:antiiq/player/state/list_states/tracks_state.dart';
import 'package:antiiq/player/state/music_state.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/utilities/file_handling/sort.dart';
import 'package:antiiq/player/utilities/user_settings.dart';

class MusicInit {
  run(MusicState music) async {
    await _initGlobalSelection(music);
    await _initFavourites(music);
    await _initSort(music);
  }


  _initGlobalSelection(MusicState music) async {
    final List<int> selectionIds =
    await antiiqStore.get(BoxKeys().globalSelection, defaultValue: <int>[]);
    music.selection.list = [];
    for (int id in selectionIds) {
      for (Track track in music.tracks.list) {
        if (track.trackData!.trackId == id) {
          music.selection.list.add(track);
        }
      }
    }
    music.selection.updateFlow();
  }

  _initFavourites(MusicState music) async {
    final FavouritesState favourites = music.favourites;
    final TracksState tracks = music.tracks;
    final List<int> favouriteIds =
        await antiiqStore.get(BoxKeys().favourites, defaultValue: <int>[]);
    favourites.list = [];
    for (int id in favouriteIds) {
      for (Track track in tracks.list) {
        if (track.trackData!.trackId == id) {
          favourites.list.add(track);
        }
      }
    }
    favourites.updateFlow();
  }

  _initSort(MusicState music) async {
    final TracksState tracks = music.tracks;
    final AlbumsState albums = music.albums;
    final ArtistsState artists = music.artists;
    final GenresState genres = music.genres;
    List<String> savedTrackSort = await antiiqStore.get(
      SortBoxKeys.trackSort,
      defaultValue: <String>[
        tracks.sort.currentSort,
        tracks.sort.currentDirection,
      ],
    );
    await beginSort(savedTrackSort[0], savedTrackSort[1], allTracks: true);

    List<String> savedAlbumSort = await antiiqStore.get(
      SortBoxKeys.albumSort,
      defaultValue: <String>[
        albums.sort.currentSort,
        albums.sort.currentDirection,
      ],
    );
    await beginSort(savedAlbumSort[0], savedAlbumSort[1], allAlbums: true);

    List<String> savedArtistSort = await antiiqStore.get(
      SortBoxKeys.artistSort,
      defaultValue: <String>[
        artists.sort.currentSort,
        artists.sort.currentDirection,
      ],
    );
    await beginSort(savedArtistSort[0], savedArtistSort[1], allArtists: true);

    List<String> savedGenreSort = await antiiqStore.get(
      SortBoxKeys.genreSort,
      defaultValue: <String>[
        genres.sort.currentSort,
        genres.sort.currentDirection,
      ],
    );
    await beginSort(savedGenreSort[0], savedGenreSort[1], allGenres: true);

    List<String> savedAlbumTracksSort = await antiiqStore.get(
      SortBoxKeys.albumTracksSort,
      defaultValue: <String>[
        albums.tracksSort.currentSort,
        albums.tracksSort.currentDirection,
      ],
    );
    await beginSort(savedAlbumTracksSort[0], savedAlbumTracksSort[1],
        allAlbumTracks: true);

    List<String> savedArtistTracksSort = await antiiqStore.get(
      SortBoxKeys.artistTracksSort,
      defaultValue: <String>[
        artists.tracksSort.currentSort,
        artists.tracksSort.currentDirection,
      ],
    );
    await beginSort(savedArtistTracksSort[0], savedArtistTracksSort[1],
        allArtistTracks: true);

    List<String> savedGenreTracksSort = await antiiqStore.get(
      SortBoxKeys.genreTracksSort,
      defaultValue: <String>[
        genres.tracksSort.currentSort,
        genres.tracksSort.currentDirection,
      ],
    );
    await beginSort(savedGenreTracksSort[0], savedGenreTracksSort[1],
        allGenreTracks: true);
  }
}
