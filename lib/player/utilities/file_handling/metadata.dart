import 'dart:typed_data';

import 'package:audio_service/audio_service.dart';

class TrackData {
  int? trackId;
  String? trackName;
  String? trackArtistNames;
  int? albumId;
  String? albumName;
  int? artistId;
  String? albumArtistName;
  int? trackNumber;
  int? albumLength;
  int? year;
  String? genre;
  String? authorName;
  String? writerName;
  int? discNumber;
  String? mimeType;
  int? trackDuration;
  int? bitrate;
  Uint8List? albumArt;
  //MemoryImage() or Image.memory()
  TrackData({
    this.trackId,
    this.trackName,
    this.trackArtistNames,
    this.albumId,
    this.albumName,
    this.artistId,
    this.albumArtistName,
    this.trackNumber,
    this.albumLength,
    this.year,
    this.genre,
    this.authorName,
    this.writerName,
    this.discNumber,
    this.mimeType,
    this.trackDuration,
    this.bitrate,
    this.albumArt,
  });
}

class Track {
  String? path;
  TrackData? trackData;
  MediaItem? mediaItem;
  Track({
    this.path,
    this.trackData,
    this.mediaItem,
  });
}

class Album {
  int? albumId;
  String? albumName;
  String? albumArtistName;
  int? numOfSongs;
  int? year;
  Uri? albumArt;
  List<Track>? albumTracks;
  Album({
    this.albumId,
    this.albumName,
    this.albumArtistName,
    this.numOfSongs,
    this.year,
    this.albumArt,
    this.albumTracks,
  });
}

class Artist {
  int? artistId;
  String? artistName;
  Uri? artistArt;
  List<Track>? artistTracks;
  Artist({
    this.artistId,
    this.artistName,
    this.artistArt,
    this.artistTracks,
  });
}

class Genre {
  String? genreName;
  List<Track>? genreTracks;
  Genre({
    this.genreName,
    this.genreTracks,
  });
}
