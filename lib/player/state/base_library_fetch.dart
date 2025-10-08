import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/state/list_states/albums_state.dart';
import 'package:antiiq/player/state/list_states/artists_state.dart';
import 'package:antiiq/player/state/list_states/genres_state.dart';
import 'package:antiiq/player/state/list_states/tracks_state.dart';
import 'package:antiiq/player/state/music_state.dart';
import 'package:antiiq/player/utilities/file_handling/art_queries.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/utilities/file_handling/sort.dart';
import 'package:audio_service/audio_service.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'dart:collection';

class BaseLibraryFetch {
  run(MusicState music) async {
    await _loadAllContent(music);
  }

  Future<void> _loadAllContent(MusicState music) async {
    loadingMessage = "Loading Library";
    final List<SongModel> allSongs = await _getAllSongs();

    loadingMessage = "Getting Artworks";
    libraryLoadTotal = allSongs.length;
    await _preloadAlbumArt(allSongs);

    loadingMessage = "Loading Songs";
    final List<Track> tracks = await _processSongs(allSongs);
    music.tracks.list = tracks;

    loadingMessage = "Building Metadata";
    final Map<int, List<Track>> albumTracksMap = _mapTracksByAlbum(tracks);
    final Map<int, List<Track>> artistTracksMap = _mapTracksByArtist(tracks);
    final Map<String, List<Track>> genreTracksMap = _mapTracksByGenre(tracks);

    music.albums.list = _buildAlbums(albumTracksMap);
    music.artists.list = _buildArtists(artistTracksMap);
    music.genres.list = _buildGenres(genreTracksMap);

    loadingMessage = "Loading Library";
    libraryLoadTotal = 1;
    libraryLoadProgress = 0;
  }

  Future<void> _preloadAlbumArt(List<SongModel> songs) async {
    final Set<int> processedAlbumIds = {};

    for (int i = 0; i < songs.length; i++) {
      final SongModel song = songs[i];
      libraryLoadProgress = i;

      if (song.albumId != null && !processedAlbumIds.contains(song.albumId)) {
        albumArtsList[song.albumId!] =
            await getAlbumArt(song.albumId, song.data);
        processedAlbumIds.add(song.albumId!);
      }
    }
  }

  Future<List<Track>> _processSongs(List<SongModel> allSongs) async {
    libraryLoadTotal = allSongs.length;
    final List<Track> validSongs = [];
    final BaseLibrarySongUtil songUtil = BaseLibrarySongUtil();

    for (int i = 0; i < allSongs.length; i++) {
      final SongModel song = allSongs[i];
      libraryLoadProgress = i;

      if (_isValidSong(song)) {
        final Track track = await songUtil.getTrack(song);
        validSongs.add(track);
      }
    }

    return validSongs;
  }

  bool _isValidSong(SongModel song) {
    final Duration duration = Duration(milliseconds: song.duration ?? 0);
    return duration != Duration.zero &&
        duration >= Duration(seconds: minimumTrackLength);
  }

  Map<int, List<Track>> _mapTracksByAlbum(List<Track> tracks) {
    final Map<int, List<Track>> albumTracksMap = HashMap<int, List<Track>>();

    for (final track in tracks) {
      final int albumId = track.trackData!.albumId!;
      (albumTracksMap[albumId] ??= []).add(track);
    }

    return albumTracksMap;
  }

  Map<int, List<Track>> _mapTracksByArtist(List<Track> tracks) {
    final Map<int, List<Track>> artistTracksMap = HashMap<int, List<Track>>();

    for (final track in tracks) {
      final int artistId = track.trackData!.artistId!;
      (artistTracksMap[artistId] ??= []).add(track);
    }

    return artistTracksMap;
  }

  Map<String, List<Track>> _mapTracksByGenre(List<Track> tracks) {
    final Map<String, List<Track>> genreTracksMap =
        HashMap<String, List<Track>>();

    for (final track in tracks) {
      final String genre = track.trackData!.genre!;
      (genreTracksMap[genre] ??= []).add(track);
    }

    return genreTracksMap;
  }

  List<Album> _buildAlbums(Map<int, List<Track>> albumTracksMap) {
    final List<Album> albums = [];

    for (final tracks in albumTracksMap.values) {
      if (tracks.isNotEmpty) {
        tracks.sort((a, b) =>
            a.trackData!.trackNumber!.compareTo(b.trackData!.trackNumber!));

        final Album album = Album(
          albumId: tracks[0].trackData!.albumId,
          albumName: tracks[0].trackData!.albumName,
          albumArtistName: tracks[0].trackData!.albumArtistName,
          albumArt: tracks[0].mediaItem!.artUri,
          numOfSongs: tracks.length,
          albumTracks: tracks,
          year: tracks[0].trackData!.year,
        );

        albums.add(album);
      }
    }

    return albums;
  }

  List<Artist> _buildArtists(Map<int, List<Track>> artistTracksMap) {
    final List<Artist> artists = [];

    for (final tracks in artistTracksMap.values) {
      if (tracks.isNotEmpty) {
        tracks.sort((a, b) =>
            a.trackData!.trackName!.compareTo(b.trackData!.trackName!));

        final Artist artist = Artist(
          artistId: tracks[0].trackData!.artistId,
          artistName: tracks[0].trackData!.trackArtistNames,
          artistTracks: tracks,
          artistArt: tracks[0].mediaItem!.artUri,
        );

        artists.add(artist);
      }
    }

    return artists;
  }

  List<Genre> _buildGenres(Map<String, List<Track>> genreTracksMap) {
    final List<Genre> genres = [];

    for (final tracks in genreTracksMap.values) {
      if (tracks.isNotEmpty) {
        tracks.sort((a, b) =>
            a.trackData!.trackName!.compareTo(b.trackData!.trackName!));

        final Genre genre = Genre(
          genreName: tracks[0].trackData!.genre,
          genreTracks: tracks,
        );

        genres.add(genre);
      }
    }

    return genres;
  }

  Future<List<SongModel>> _getAllSongs({
    SongSortType sortType = SongSortType.TITLE,
  }) async {
    final List<SongModel> totalLibrary = [];

    if (specificPathsToQuery.isNotEmpty) {
      await Future.wait(specificPathsToQuery.map((path) async {
        final List<SongModel> songsInPath = await audioQuery.querySongs(
          path: path,
          sortType: sortType,
          orderType: OrderType.ASC_OR_SMALLER,
          uriType: UriType.EXTERNAL,
          ignoreCase: true,
        );
        totalLibrary.addAll(songsInPath);
      }));
    } else {
      final List<SongModel> songs = await audioQuery.querySongs(
        sortType: sortType,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );
      totalLibrary.addAll(songs);
    }

    return totalLibrary;
  }
}

class BaseLibrarySongUtil {
  Future<Track> getTrack(SongModel song) async {
    String songPath = song.data;
    TrackData songTrackData = TrackData(
      trackId: song.id,
      trackName: song.title,
      trackArtistNames: song.artist,
      albumId: song.albumId,
      albumName: song.album ?? "Unknown Album",
      artistId: song.artistId,
      albumArtistName: song.artist!.split("/")[0],
      trackNumber: song.track ?? 0,
      genre: song.genre ?? "Unknown Genre",
      writerName: song.composer,
      mimeType: song.fileExtension,
      trackDuration: song.duration ?? 0,
    );

    return Track(
      path: songPath,
      trackData: songTrackData,
      mediaItem: _createMediaItem(song),
    );
  }

  MediaItem _createMediaItem(SongModel song) {
    return MediaItem(
        id: song.data,
        title: song.title,
        artist: song.artist,
        album: song.album,
        artUri: albumArtsList[song.albumId],
        duration: Duration(milliseconds: song.duration!),
        extras: {
          "id": song.id,
        });
  }
}

class BaseLibraryInit {
  run(MusicState music) async {
    await _fetch.run(music);
  }

  final BaseLibraryFetch _fetch = BaseLibraryFetch();
}

class MusicInit {
  run(MusicState music) async {
    await _baseLibraryInit.run(music);

    await Future.wait([
      music.playlists.init(music.tracks),
      music.queue.init(music.tracks),
      music.selection.init(music.tracks),
      music.favourites.init(music.tracks),
      music.history.init(music.tracks),
    ]);

    await _initSort(music);
  }

  final BaseLibraryInit _baseLibraryInit = BaseLibraryInit();

  Future<void> _initSort(MusicState music) async {
    final sortOperations = [
      _initTrackSort(music),
      _initAlbumSort(music),
      _initArtistSort(music),
      _initGenreSort(music),
      _initAlbumTracksSort(music),
      _initArtistTracksSort(music),
      _initGenreTracksSort(music),
    ];

    await Future.wait(sortOperations);
  }

  Future<void> _initTrackSort(MusicState music) async {
    final TracksState tracks = music.tracks;
    final List<String> savedTrackSort = await antiiqState.store.get(
      SortBoxKeys.trackSort,
      defaultValue: <String>[
        tracks.sort.currentSort,
        tracks.sort.currentDirection,
      ],
    );
    await beginSort(savedTrackSort[0], savedTrackSort[1], allTracks: true);
  }

  Future<void> _initAlbumSort(MusicState music) async {
    final AlbumsState albums = music.albums;
    final List<String> savedAlbumSort = await antiiqState.store.get(
      SortBoxKeys.albumSort,
      defaultValue: <String>[
        albums.sort.currentSort,
        albums.sort.currentDirection,
      ],
    );
    await beginSort(savedAlbumSort[0], savedAlbumSort[1], allAlbums: true);
  }

  Future<void> _initArtistSort(MusicState music) async {
    final ArtistsState artists = music.artists;
    final List<String> savedArtistSort = await antiiqState.store.get(
      SortBoxKeys.artistSort,
      defaultValue: <String>[
        artists.sort.currentSort,
        artists.sort.currentDirection,
      ],
    );
    await beginSort(savedArtistSort[0], savedArtistSort[1], allArtists: true);
  }

  Future<void> _initGenreSort(MusicState music) async {
    final GenresState genres = music.genres;
    final List<String> savedGenreSort = await antiiqState.store.get(
      SortBoxKeys.genreSort,
      defaultValue: <String>[
        genres.sort.currentSort,
        genres.sort.currentDirection,
      ],
    );
    await beginSort(savedGenreSort[0], savedGenreSort[1], allGenres: true);
  }

  Future<void> _initAlbumTracksSort(MusicState music) async {
    final AlbumsState albums = music.albums;
    final List<String> savedAlbumTracksSort = await antiiqState.store.get(
      SortBoxKeys.albumTracksSort,
      defaultValue: <String>[
        albums.tracksSort.currentSort,
        albums.tracksSort.currentDirection,
      ],
    );
    await beginSort(savedAlbumTracksSort[0], savedAlbumTracksSort[1],
        allAlbumTracks: true);
  }

  Future<void> _initArtistTracksSort(MusicState music) async {
    final ArtistsState artists = music.artists;
    final List<String> savedArtistTracksSort = await antiiqState.store.get(
      SortBoxKeys.artistTracksSort,
      defaultValue: <String>[
        artists.tracksSort.currentSort,
        artists.tracksSort.currentDirection,
      ],
    );
    await beginSort(savedArtistTracksSort[0], savedArtistTracksSort[1],
        allArtistTracks: true);
  }

  Future<void> _initGenreTracksSort(MusicState music) async {
    final GenresState genres = music.genres;
    final List<String> savedGenreTracksSort = await antiiqState.store.get(
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
