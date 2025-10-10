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
import 'package:flutter/foundation.dart';
import 'dart:collection';
import 'dart:io';

import 'audio_metadata_bridge.dart';

class AntiiQLibraryFetcher {
  run(MusicState music) async {
    await _loadAllContent(music);
  }

  Future<void> _loadAllContent(MusicState music) async {
    loadingMessage = "Loading Library";
    final List<AudioMetadata> allSongs = await _getAllSongs();

    loadingMessage = "Getting Artworks";
    libraryLoadTotal = allSongs.length;
    await _preloadAlbumArt(allSongs);

    loadingMessage = "Loading Songs";
    final List<Track> tracks = await _processSongs(allSongs);
    music.tracks.list = tracks;

    loadingMessage = "Building Metadata";
    final Map<String, List<Track>> albumTracksMap = _mapTracksByAlbum(tracks);
    final Map<String, List<Track>> artistTracksMap = _mapTracksByArtist(tracks);
    final Map<String, List<Track>> genreTracksMap = _mapTracksByGenre(tracks);

    music.albums.list = _buildAlbums(albumTracksMap);
    music.artists.list = _buildArtists(artistTracksMap);
    music.genres.list = _buildGenres(genreTracksMap);

    loadingMessage = "Loading Library";
    libraryLoadTotal = 1;
    libraryLoadProgress = 0;
  }

  Future<void> _preloadAlbumArt(List<AudioMetadata> songs) async {
    final Set<String> processedAlbumKeys = {};

    for (int i = 0; i < songs.length; i++) {
      final AudioMetadata song = songs[i];
      libraryLoadProgress = i;

      final String albumKey = _generateAlbumKey(song.album, song.albumArtist);

      if (!processedAlbumKeys.contains(albumKey)) {
        final artFilePath =
            "${antiiqDirectory.path}/coverarts/albums/$albumKey.jpeg";

        if (!antiiqState.dataIsInitialized) {
          try {
            Uint8List? artBytes;

            if (song.mediaStoreAlbumId != null) {
              artBytes = await AudioMetadataBridge.getMediaStoreArtwork(
                song.mediaStoreAlbumId!,
                quality: 90,
              );
            }

            artBytes ??= await AudioMetadataBridge.extractArtwork(
                  song.path,
                  quality: 90,
                ) ??
                await getDirectoryArt(song.path);

            if (artBytes != null) {
              final Uri artUri = await _saveAlbumArt(albumKey, artBytes);
              setAlbumArtByKey(albumKey, artUri);
            } else {
              setAlbumArtByKey(albumKey, defaultArtUri);
            }
          } catch (e) {
            debugPrint('Error loading art for album $albumKey: $e');
            setAlbumArtByKey(albumKey, defaultArtUri);
          }
        } else {
          if (await File(artFilePath).exists()) {
            final Uri artUri = Uri.file(artFilePath);
            setAlbumArtByKey(albumKey, artUri);
          } else {
            try {
              Uint8List? artBytes;

              if (song.mediaStoreAlbumId != null) {
                artBytes = await AudioMetadataBridge.getMediaStoreArtwork(
                  song.mediaStoreAlbumId!,
                  quality: 90,
                );
              }

              artBytes ??= await AudioMetadataBridge.extractArtwork(
                    song.path,
                    quality: 90,
                  ) ??
                  await getDirectoryArt(song.path);

              if (artBytes != null) {
                final Uri artUri = await _saveAlbumArt(albumKey, artBytes);
                setAlbumArtByKey(albumKey, artUri);
              } else {
                setAlbumArtByKey(albumKey, defaultArtUri);
              }
            } catch (e) {
              debugPrint('Error loading art for album $albumKey: $e');
              setAlbumArtByKey(albumKey, defaultArtUri);
            }
          }
        }

        processedAlbumKeys.add(albumKey);
      }
    }
  }

  String _generateAlbumKey(String album, String albumArtist) {
    final String safeAlbum = album.replaceAll(RegExp(r'[^\w\s-]'), '');
    final String safeArtist = albumArtist.replaceAll(RegExp(r'[^\w\s-]'), '');
    return '${safeAlbum}_$safeArtist';
  }

  Future<Uri> _saveAlbumArt(String albumKey, Uint8List artBytes) async {
    final artFilePath =
        "${antiiqDirectory.path}/coverarts/albums/$albumKey.jpeg";

    File artFile = await File(artFilePath).create(recursive: true);
    await artFile.writeAsBytes(artBytes, mode: FileMode.write);

    return Uri.file(artFilePath);
  }

  Future<List<Track>> _processSongs(List<AudioMetadata> allSongs) async {
    libraryLoadTotal = allSongs.length;
    final List<Track> validSongs = [];
    final CustomLibrarySongUtil songUtil = CustomLibrarySongUtil();

    for (int i = 0; i < allSongs.length; i++) {
      final AudioMetadata song = allSongs[i];
      libraryLoadProgress = i;

      if (_isValidSong(song)) {
        final Track track = await songUtil.getTrack(song);
        validSongs.add(track);
      }
    }

    return validSongs;
  }

  bool _isValidSong(AudioMetadata song) {
    final Duration duration = Duration(milliseconds: song.duration);
    return duration != Duration.zero &&
        duration >= Duration(seconds: minimumTrackLength);
  }

  Map<String, List<Track>> _mapTracksByAlbum(List<Track> tracks) {
    final Map<String, List<Track>> albumTracksMap =
        HashMap<String, List<Track>>();

    for (final track in tracks) {
      final String albumKey = _generateAlbumKey(
        track.trackData!.albumName ?? 'Unknown Album',
        track.trackData!.albumArtistName ?? 'Unknown Artist',
      );
      (albumTracksMap[albumKey] ??= []).add(track);
    }

    return albumTracksMap;
  }

  Map<String, List<Track>> _mapTracksByArtist(List<Track> tracks) {
    final Map<String, List<Track>> artistTracksMap =
        HashMap<String, List<Track>>();

    for (final track in tracks) {
      final String artistKey =
          track.trackData!.trackArtistNames ?? 'Unknown Artist';
      (artistTracksMap[artistKey] ??= []).add(track);
    }

    return artistTracksMap;
  }

  Map<String, List<Track>> _mapTracksByGenre(List<Track> tracks) {
    final Map<String, List<Track>> genreTracksMap =
        HashMap<String, List<Track>>();

    for (final track in tracks) {
      final String genre = track.trackData!.genre ?? 'Unknown Genre';
      (genreTracksMap[genre] ??= []).add(track);
    }

    return genreTracksMap;
  }

  List<Album> _buildAlbums(Map<String, List<Track>> albumTracksMap) {
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

  List<Artist> _buildArtists(Map<String, List<Track>> artistTracksMap) {
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

  Future<List<AudioMetadata>> _getAllSongs() async {
    final List<AudioMetadata> totalLibrary = [];

    if (specificPathsToQuery.isNotEmpty) {
      debugPrint(
          'Scanning ${specificPathsToQuery.length} specific paths using MediaStore');
      try {
        final List<AudioMetadata> songsInPaths =
            await AudioMetadataBridge.getAudioFilesWithMetadataFromPaths(
          specificPathsToQuery,
        );
        debugPrint(
            'MediaStore found ${songsInPaths.length} files in specific paths');
        totalLibrary.addAll(songsInPaths);
      } catch (e) {
        debugPrint('MediaStore path query failed: $e');
        debugPrint('Falling back to directory scanning...');

        for (String path in specificPathsToQuery) {
          debugPrint('Scanning specific path: $path');
          try {
            final List<AudioMetadata> songsInPath =
                await AudioMetadataBridge.scanDirectoryWithMetadata(
              path,
              recursive: true,
            );
            debugPrint('Found ${songsInPath.length} files in $path');
            totalLibrary.addAll(songsInPath);
          } catch (e) {
            debugPrint('Error scanning directory $path: $e');
          }
        }
      }
    } else {
      debugPrint('Using MediaStore to get all audio files with metadata...');
      try {
        final List<AudioMetadata> allAudio =
            await AudioMetadataBridge.getAllAudioFilesWithMetadata();
        debugPrint('MediaStore found ${allAudio.length} audio files');
        totalLibrary.addAll(allAudio);
      } catch (e) {
        debugPrint('MediaStore query failed: $e');
        debugPrint('Falling back to directory scanning...');

        final List<String> allPaths = await _getAllStoragePaths();
        debugPrint('Scanning ${allPaths.length} storage locations');

        for (String path in allPaths) {
          debugPrint('Scanning: $path');
          try {
            final List<AudioMetadata> songsInPath =
                await AudioMetadataBridge.scanDirectoryWithMetadata(
              path,
              recursive: true,
            );
            debugPrint('Found ${songsInPath.length} audio files in $path');
            totalLibrary.addAll(songsInPath);
          } catch (e) {
            debugPrint('Error scanning directory $path: $e');
          }
        }
      }
    }

    debugPrint('Total songs found: ${totalLibrary.length}');
    return totalLibrary;
  }

  Future<List<String>> _getAllStoragePaths() async {
    final List<String> paths = [];

    final List<String> potentialPaths = [
      '/storage/emulated/0',
      '/storage/emulated/0/Music',
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Downloads',
      '/sdcard',
      '/sdcard/Music',
      '/sdcard/Download',
      '/sdcard/Downloads',
    ];

    final externalDir = Directory('/storage');
    if (await externalDir.exists()) {
      try {
        final storageList = await externalDir.list().toList();
        for (var entity in storageList) {
          if (entity is Directory) {
            final dirName = entity.path.split('/').last;
            if (dirName.contains('-') &&
                dirName != 'emulated' &&
                dirName != 'self') {
              potentialPaths.add(entity.path);
              potentialPaths.add('${entity.path}/Music');
              potentialPaths.add('${entity.path}/Download');
              potentialPaths.add('${entity.path}/Downloads');
            }
          }
        }
      } catch (e) {
        debugPrint('Error listing /storage: $e');
      }
    }

    for (String path in potentialPaths) {
      final dir = Directory(path);
      if (await dir.exists()) {
        try {
          await dir.list().isEmpty;
          if (!paths.contains(path)) {
            paths.add(path);
          }
        } catch (e) {
          debugPrint('Cannot access $path: $e');
        }
      }
    }

    debugPrint('Accessible storage paths: $paths');
    return paths;
  }
}

class CustomLibrarySongUtil {
  Future<Track> getTrack(AudioMetadata metadata) async {
    final int trackId = _generateTrackId(metadata);
    final int albumId = _generateAlbumId(metadata);
    final int artistId = _generateArtistId(metadata);

    TrackData songTrackData = TrackData(
      trackId: trackId,
      trackName: metadata.title,
      trackArtistNames: metadata.artist,
      albumId: albumId,
      albumName: metadata.album,
      artistId: artistId,
      albumArtistName: metadata.albumArtist,
      trackNumber: metadata.trackNumber,
      genre: metadata.genre,
      writerName: metadata.writer ?? metadata.composer,
      mimeType: metadata.mimeType ?? metadata.fileExtension,
      trackDuration: metadata.duration,
      year: metadata.year,
    );

    final String albumKey =
        _generateAlbumKey(metadata.album, metadata.albumArtist);
    final Uri artUri = getAlbumArtByKey(albumKey) ?? defaultArtUri;

    return Track(
      path: metadata.path,
      trackData: songTrackData,
      mediaItem: _createMediaItem(metadata, artUri, trackId),
    );
  }

  String _generateAlbumKey(String album, String albumArtist) {
    final String safeAlbum = album.replaceAll(RegExp(r'[^\w\s-]'), '');
    final String safeArtist = albumArtist.replaceAll(RegExp(r'[^\w\s-]'), '');
    return '${safeAlbum}_$safeArtist';
  }

  int _generateTrackId(AudioMetadata metadata) {
    return metadata.path.hashCode.abs();
  }

  int _generateAlbumId(AudioMetadata metadata) {
    final String albumKey = '${metadata.album}_${metadata.albumArtist}';
    return albumKey.hashCode.abs();
  }

  int _generateArtistId(AudioMetadata metadata) {
    return metadata.artist.hashCode.abs();
  }

  MediaItem _createMediaItem(AudioMetadata metadata, Uri? artUri, int trackId) {
    return MediaItem(
      id: metadata.path,
      title: metadata.title,
      artist: metadata.artist,
      album: metadata.album,
      artUri: artUri,
      duration: Duration(milliseconds: metadata.duration),
      extras: {
        "id": trackId,
      },
    );
  }
}

class CustomLibraryInit {
  run(MusicState music) async {
    await _fetch.run(music);
  }

  final AntiiQLibraryFetcher _fetch = AntiiQLibraryFetcher();
}

class CustomMusicInit {
  run(MusicState music) async {
    await _customLibraryInit.run(music);

    await Future.wait([
      music.playlists.init(music.tracks),
      music.queue.init(music.tracks),
      music.selection.init(music.tracks),
      music.favourites.init(music.tracks),
      music.history.init(music.tracks),
    ]);

    await _initSort(music);
  }

  final CustomLibraryInit _customLibraryInit = CustomLibraryInit();

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
