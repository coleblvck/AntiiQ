import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/state/base_library_init.dart';
import 'package:antiiq/player/state/list_states/albums_state.dart';
import 'package:antiiq/player/state/list_states/artists_state.dart';
import 'package:antiiq/player/state/list_states/genres_state.dart';
import 'package:antiiq/player/state/list_states/tracks_state.dart';
import 'package:antiiq/player/state/music_state.dart';
import 'package:antiiq/player/utilities/file_handling/sort.dart';

class MusicInit {
  run(MusicState music) async {
    final TracksState tracks = music.tracks;
    await _baseLibraryInit.run(music);
    await music.playlists.init(tracks);
    await music.queue.init(tracks);
    await music.selection.init(tracks);
    await music.favourites.init(tracks);
    await music.history.init(tracks);
    await _initSort(music);
  }

  final BaseLibraryInit _baseLibraryInit = BaseLibraryInit();

  _initSort(MusicState music) async {
    final TracksState tracks = music.tracks;
    final AlbumsState albums = music.albums;
    final ArtistsState artists = music.artists;
    final GenresState genres = music.genres;
    List<String> savedTrackSort = await antiiqState.store.get(
      SortBoxKeys.trackSort,
      defaultValue: <String>[
        tracks.sort.currentSort,
        tracks.sort.currentDirection,
      ],
    );
    await beginSort(savedTrackSort[0], savedTrackSort[1], allTracks: true);

    List<String> savedAlbumSort = await antiiqState.store.get(
      SortBoxKeys.albumSort,
      defaultValue: <String>[
        albums.sort.currentSort,
        albums.sort.currentDirection,
      ],
    );
    await beginSort(savedAlbumSort[0], savedAlbumSort[1], allAlbums: true);

    List<String> savedArtistSort = await antiiqState.store.get(
      SortBoxKeys.artistSort,
      defaultValue: <String>[
        artists.sort.currentSort,
        artists.sort.currentDirection,
      ],
    );
    await beginSort(savedArtistSort[0], savedArtistSort[1], allArtists: true);

    List<String> savedGenreSort = await antiiqState.store.get(
      SortBoxKeys.genreSort,
      defaultValue: <String>[
        genres.sort.currentSort,
        genres.sort.currentDirection,
      ],
    );
    await beginSort(savedGenreSort[0], savedGenreSort[1], allGenres: true);

    List<String> savedAlbumTracksSort = await antiiqState.store.get(
      SortBoxKeys.albumTracksSort,
      defaultValue: <String>[
        albums.tracksSort.currentSort,
        albums.tracksSort.currentDirection,
      ],
    );
    await beginSort(savedAlbumTracksSort[0], savedAlbumTracksSort[1],
        allAlbumTracks: true);

    List<String> savedArtistTracksSort = await antiiqState.store.get(
      SortBoxKeys.artistTracksSort,
      defaultValue: <String>[
        artists.tracksSort.currentSort,
        artists.tracksSort.currentDirection,
      ],
    );
    await beginSort(savedArtistTracksSort[0], savedArtistTracksSort[1],
        allArtistTracks: true);

    List<String> savedGenreTracksSort = await antiiqState.store.get(
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
