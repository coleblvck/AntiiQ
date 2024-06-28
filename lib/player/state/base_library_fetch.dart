import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/state/list_states/albums_state.dart';
import 'package:antiiq/player/state/list_states/artists_state.dart';
import 'package:antiiq/player/state/list_states/genres_state.dart';
import 'package:antiiq/player/state/list_states/tracks_state.dart';
import 'package:antiiq/player/state/music_state.dart';
import 'package:antiiq/player/utilities/file_handling/art_queries.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:audio_service/audio_service.dart';
import 'package:on_audio_query/on_audio_query.dart';

class BaseLibraryFetch {
  run(MusicState music) async {
    await _getAndSortSongs(music.tracks);
    await _getAlbums(music);
    await _getArtists(music);
    await _getGenres(music);
  }

  final BaseLibrarySongUtil _songUtil = BaseLibrarySongUtil();

  _getAndSortSongs(TracksState allTracks) async {
    final List<SongModel> allSongs = await _getAllSongs();
    await BaseLibraryArtUtil.loadAll(allSongs);
    //Progress Count init
    loadingMessage = "Loading Songs";
    libraryLoadTotal = allSongs.length;
    List<Track> sortedSongs = [];
    for (SongModel song in allSongs) {
      //Progress Count iterate
      libraryLoadProgress = allSongs.indexOf(song);
      if (Duration(milliseconds: song.duration!) !=
              const Duration(milliseconds: 0) &&
          !(Duration(milliseconds: song.duration!) <
              Duration(seconds: minimumTrackLength))) {
        final Track track = await _songUtil.getTrack(song);

        sortedSongs.add(track);
      }
    }
    allTracks.list = sortedSongs;
  }

  _getAlbums(MusicState music) async {
    final TracksState allTracks = music.tracks;
    final AlbumsState allAlbums = music.albums;
    List<Album> sortedAlbums = [];
    List<AlbumModel> albumSortQuery = await audioQuery.queryAlbums();
    //Progress Count init
    loadingMessage = "Loading Albums";
    libraryLoadTotal = albumSortQuery.length;
    Map<int, List<Track>> albumSortAlbums = {};
    for (AlbumModel album in albumSortQuery) {
      albumSortAlbums[album.id] = [];
    }
    for (Track track in allTracks.list) {
      albumSortAlbums[track.trackData!.albumId]?.add(track);
    }
    for (List<Track> albumTracks in albumSortAlbums.values) {
      if (albumTracks.isNotEmpty) {
        albumTracks.sort(
          (a, b) =>
              a.trackData!.trackNumber!.compareTo(b.trackData!.trackNumber!),
        );
        final Album thisAlbum = Album(
          albumId: albumTracks[0].trackData!.albumId,
          albumName: albumTracks[0].trackData!.albumName,
          albumArtistName: albumTracks[0].trackData!.albumArtistName,
          albumArt: albumTracks[0].mediaItem!.artUri,
          numOfSongs: albumTracks.length,
          albumTracks: albumTracks,
          year: albumTracks[0].trackData!.year,
        );
        sortedAlbums.add(thisAlbum);
      }
    }
    allAlbums.list = sortedAlbums;
    //Progress reset
    loadingMessage = "Loading Library";
    libraryLoadTotal = 1;
    libraryLoadProgress = 0;
  }

  _getArtists(MusicState music) async {
    final TracksState allTracks = music.tracks;
    final ArtistsState allArtists = music.artists;
    List<Artist> sortedArtists = [];
    List<ArtistModel> artistSortQuery = await audioQuery.queryArtists();
    //Progress Count init
    loadingMessage = "Loading Artists";
    libraryLoadTotal = artistSortQuery.length;
    Map<int, List<Track>> artistSortTracks = {};
    for (ArtistModel artist in artistSortQuery) {
      artistSortTracks[artist.id] = [];
    }
    for (Track track in allTracks.list) {
      artistSortTracks[track.trackData!.artistId]?.add(track);
    }
    for (List<Track> artistTracks in artistSortTracks.values) {
      if (artistTracks.isNotEmpty) {
        artistTracks.sort(
          (a, b) => a.trackData!.trackName!.compareTo(b.trackData!.trackName!),
        );
        final Artist thisArtist = Artist(
          artistId: artistTracks[0].trackData!.artistId,
          artistName: artistTracks[0].trackData!.trackArtistNames,
          artistTracks: artistTracks,
          artistArt: artistTracks[0].mediaItem!.artUri,
        );
        sortedArtists.add(thisArtist);
      }
    }
    allArtists.list = sortedArtists;
    //Progress reset
    loadingMessage = "Loading Library";
    libraryLoadTotal = 1;
    libraryLoadProgress = 0;
  }

  _getGenres(MusicState music) async {
    final TracksState allTracks = music.tracks;
    final GenresState allGenres = music.genres;
    List<Genre> sortedGenres = [];
    List<GenreModel> genreSortQuery = await audioQuery.queryGenres();
    //Progress Count init
    loadingMessage = "Loading Genres";
    libraryLoadTotal = genreSortQuery.length;
    Map<String, List<Track>> genreSortTracks = {};
    for (GenreModel genre in genreSortQuery) {
      genreSortTracks[genre.genre] = [];
    }
    genreSortTracks["Unknown Genre"] = [];
    for (Track track in allTracks.list) {
      genreSortTracks[track.trackData!.genre]?.add(track);
    }
    for (List<Track> genreTracks in genreSortTracks.values) {
      if (genreTracks.isNotEmpty) {
        genreTracks.sort(
          (a, b) => a.trackData!.trackName!.compareTo(b.trackData!.trackName!),
        );
        final Genre thisGenre = Genre(
          genreName: genreTracks[0].trackData!.genre,
          genreTracks: genreTracks,
        );
        sortedGenres.add(thisGenre);
      }
    }
    allGenres.list = sortedGenres;
    //Progress reset
    loadingMessage = "Loading Library";
    libraryLoadTotal = 1;
    libraryLoadProgress = 0;
  }

  Future<List<SongModel>> _getAllSongs({
    SongSortType sortType = SongSortType.TITLE,
  }) async {
    List<SongModel> totalLibrary = [];
    if (specificPathsToQuery.isNotEmpty) {
      for (String path in specificPathsToQuery) {
        final List<SongModel> songsInPath = await audioQuery.querySongs(
          path: path,
          sortType: sortType,
          orderType: OrderType.ASC_OR_SMALLER,
          uriType: UriType.EXTERNAL,
          ignoreCase: true,
        );
        totalLibrary += songsInPath;
      }
    } else {
      final List<SongModel> songs = await audioQuery.querySongs(
        sortType: sortType,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );
      totalLibrary = songs;
    }
    return totalLibrary;
  }
}

//
//
//

class BaseLibraryArtUtil {
  static loadAll(List<SongModel> songs) async {
    loadingMessage = "Getting Artworks";
    libraryLoadTotal = songs.length;
    for (SongModel song in songs) {
      libraryLoadProgress = songs.indexOf(song);
      if (!albumArtsList.keys.contains(song.albumId)) {
        albumArtsList[song.albumId!] =
            await getAlbumArt(song.albumId, song.data);
      }
    }
  }
}

//
//
//

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
    final Track thisTrack = Track(
      path: songPath,
      trackData: songTrackData,
      mediaItem: await _getMediaItem(song),
    );
    return thisTrack;
  }

  Future<MediaItem> _getMediaItem(SongModel song) async {
    final MediaItem songMediaItem = MediaItem(
        id: song.data,
        title: song.title,
        artist: song.artist,
        album: song.album,
        artUri: albumArtsList[song.albumId],
        duration: Duration(milliseconds: song.duration!),
        extras: {
          "id": song.id,
        });

    return songMediaItem;
  }
}
