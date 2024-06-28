import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/utilities/file_handling/art_queries.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/state/list_states/playlists_state.dart';
import 'package:audio_service/audio_service.dart';
import 'package:on_audio_query/on_audio_query.dart';

String tracksStorage = "Tracks";

queryAndSort() async {
  await getAndSortSongs();
  await getAlbums();
  await getArtists();
  await getGenres();
  await state.music.init();

  dataIsInitialized = true;
  await antiiqStore.put("dataInit", true);
}

getAndSortSongs() async {
  final List<SongModel> allSongs = await getAllSongs();
  await getAllAlbumArts(allSongs);
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
      final Track track = await getTrackFromSong(song);

      sortedSongs.add(track);
    }
  }
  state.music.tracks.list = sortedSongs;
}

getAlbums() async {
  List<Album> sortedAlbums = [];
  List<AlbumModel> albumSortQuery = await audioQuery.queryAlbums();
  //Progress Count init
  loadingMessage = "Loading Albums";
  libraryLoadTotal = albumSortQuery.length;
  Map<int, List<Track>> albumSortAlbums = {};
  for (AlbumModel album in albumSortQuery) {
    albumSortAlbums[album.id] = [];
  }
  for (Track track in state.music.tracks.list) {
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
  state.music.albums.list = sortedAlbums;
  //Progress reset
  loadingMessage = "Loading Library";
  libraryLoadTotal = 1;
  libraryLoadProgress = 0;
}

getArtists() async {
  List<Artist> sortedArtists = [];
  List<ArtistModel> artistSortQuery = await audioQuery.queryArtists();
  //Progress Count init
  loadingMessage = "Loading Artists";
  libraryLoadTotal = artistSortQuery.length;
  Map<int, List<Track>> artistSortTracks = {};
  for (ArtistModel artist in artistSortQuery) {
    artistSortTracks[artist.id] = [];
  }
  for (Track track in state.music.tracks.list) {
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
  state.music.artists.list = sortedArtists;
  //Progress reset
  loadingMessage = "Loading Library";
  libraryLoadTotal = 1;
  libraryLoadProgress = 0;
}

getGenres() async {
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
  for (Track track in state.music.tracks.list) {
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
  state.music.genres.list = sortedGenres;
  //Progress reset
  loadingMessage = "Loading Library";
  libraryLoadTotal = 1;
  libraryLoadProgress = 0;
}

Future<List<SongModel>> getAllSongs({
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

Future<Track> getTrackFromSong(SongModel song) async {
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
    mediaItem: await getMediaItemFromSong(song),
  );
  return thisTrack;
}

Future<MediaItem> getMediaItemFromSong(SongModel song) async {
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

getAllAlbumArts(List<SongModel> songs) async {
  loadingMessage = "Getting Artworks";
  libraryLoadTotal = songs.length;
  for (SongModel song in songs) {
    libraryLoadProgress = songs.indexOf(song);
    if (!albumArtsList.keys.contains(song.albumId)) {
      albumArtsList[song.albumId!] = await getAlbumArt(song.albumId, song.data);
    }
  }
}
