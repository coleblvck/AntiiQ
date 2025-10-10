import 'package:flutter/services.dart';

class AudioMetadataBridge {
  static const MethodChannel _channel =
      MethodChannel('com.coleblvck.antiiq/audio_metadata');

  /// Gets all audio files with metadata from MediaStore in ONE call
  /// This is MUCH faster than getting file list then metadata separately
  static Future<List<AudioMetadata>> getAllAudioFilesWithMetadata() async {
    try {
      final List<dynamic> result =
          await _channel.invokeMethod('getAllAudioFilesWithMetadata');

      return result
          .map((item) => AudioMetadata.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } on PlatformException catch (e) {
      throw AudioMetadataException(
        'Failed to get audio files from MediaStore: ${e.message}',
        e.code,
      );
    }
  }

  /// Gets audio files with metadata from specific paths using MediaStore (FAST!)
  /// Much faster than scanDirectoryWithMetadata because it uses MediaStore
  static Future<List<AudioMetadata>> getAudioFilesWithMetadataFromPaths(
    List<String> paths,
  ) async {
    try {
      final List<dynamic> result = await _channel.invokeMethod(
        'getAudioFilesWithMetadataFromPaths',
        {'paths': paths},
      );

      return result
          .map((item) => AudioMetadata.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } on PlatformException catch (e) {
      throw AudioMetadataException(
        'Failed to get audio files from paths: ${e.message}',
        e.code,
      );
    }
  }

  /// Scans directory and returns metadata in ONE call (for custom paths)
  static Future<List<AudioMetadata>> scanDirectoryWithMetadata(
    String path, {
    bool recursive = true,
  }) async {
    try {
      final List<dynamic> result = await _channel.invokeMethod(
        'scanDirectoryWithMetadata',
        {
          'path': path,
          'recursive': recursive,
        },
      );

      return result
          .map((item) => AudioMetadata.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } on PlatformException catch (e) {
      throw AudioMetadataException(
        'Failed to scan directory: ${e.message}',
        e.code,
      );
    }
  }

  /// Legacy method - kept for compatibility but slower
  static Future<List<AudioFileInfo>> scanDirectory(
    String path, {
    bool recursive = true,
  }) async {
    try {
      final List<dynamic> result = await _channel.invokeMethod(
        'scanDirectory',
        {
          'path': path,
          'recursive': recursive,
        },
      );

      return result
          .map((item) => AudioFileInfo.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } on PlatformException catch (e) {
      throw AudioMetadataException(
        'Failed to scan directory: ${e.message}',
        e.code,
      );
    }
  }

  /// Legacy method - kept for compatibility but slower
  static Future<List<AudioFileInfo>> getAllAudioFiles() async {
    try {
      final List<dynamic> result =
          await _channel.invokeMethod('getAllAudioFiles');

      return result
          .map((item) => AudioFileInfo.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } on PlatformException catch (e) {
      throw AudioMetadataException(
        'Failed to get audio files from MediaStore: ${e.message}',
        e.code,
      );
    }
  }

  /// Gets metadata from a Content URI (for intent/shared files)
  static Future<AudioMetadata> getMetadataFromContentUri(
      String contentUri) async {
    try {
      final Map<dynamic, dynamic> result = await _channel.invokeMethod(
        'getMetadataFromContentUri',
        {'uri': contentUri},
      );

      return AudioMetadata.fromMap(Map<String, dynamic>.from(result));
    } on PlatformException catch (e) {
      throw AudioMetadataException(
        'Failed to get metadata from content URI: ${e.message}',
        e.code,
      );
    }
  }

  /// Extracts artwork from a Content URI
  static Future<Uint8List?> extractArtworkFromContentUri(
    String contentUri, {
    int quality = 90,
  }) async {
    try {
      final Uint8List? result = await _channel.invokeMethod(
        'extractArtworkFromContentUri',
        {
          'uri': contentUri,
          'quality': quality,
        },
      );

      return result;
    } on PlatformException catch (e) {
      throw AudioMetadataException(
        'Failed to extract artwork from content URI: ${e.message}',
        e.code,
      );
    }
  }

  /// Gets metadata for a single file - avoid using in loops!
  static Future<AudioMetadata> getMetadata(String path) async {
    try {
      final Map<dynamic, dynamic> result = await _channel.invokeMethod(
        'getMetadata',
        {'path': path},
      );

      return AudioMetadata.fromMap(Map<String, dynamic>.from(result));
    } on PlatformException catch (e) {
      throw AudioMetadataException(
        'Failed to get metadata for $path: ${e.message}',
        e.code,
      );
    }
  }

  /// Extracts embedded artwork from an audio file
  static Future<Uint8List?> extractArtwork(
    String path, {
    int quality = 90,
  }) async {
    try {
      final Uint8List? result = await _channel.invokeMethod(
        'extractArtwork',
        {
          'path': path,
          'quality': quality,
        },
      );

      return result;
    } on PlatformException catch (e) {
      throw AudioMetadataException(
        'Failed to extract artwork: ${e.message}',
        e.code,
      );
    }
  }

  /// Gets album artwork from Android MediaStore (FAST!)
  static Future<Uint8List?> getMediaStoreArtwork(
    int albumId, {
    int quality = 90,
  }) async {
    try {
      final Uint8List? result = await _channel.invokeMethod(
        'getMediaStoreArtwork',
        {
          'albumId': albumId,
          'quality': quality,
        },
      );

      return result;
    } on PlatformException catch (e) {
      throw AudioMetadataException(
        'Failed to get MediaStore artwork: ${e.message}',
        e.code,
      );
    }
  }
}

class AudioFileInfo {
  final String path;
  final int size;
  final int lastModified;

  AudioFileInfo({
    required this.path,
    required this.size,
    required this.lastModified,
  });

  factory AudioFileInfo.fromMap(Map<String, dynamic> map) {
    return AudioFileInfo(
      path: map['path'] as String,
      size: map['size'] as int,
      lastModified: map['lastModified'] as int,
    );
  }
}

class AudioMetadata {
  final String path;
  final String title;
  final String artist;
  final String album;
  final String albumArtist;
  final String genre;
  final int? year;
  final int trackNumber;
  final String? composer;
  final String? writer;
  final int duration;
  final int? bitrate;
  final String? mimeType;
  final String fileExtension;
  final int? mediaStoreAlbumId; // For faster album art lookup

  AudioMetadata({
    required this.path,
    required this.title,
    required this.artist,
    required this.album,
    required this.albumArtist,
    required this.genre,
    this.year,
    required this.trackNumber,
    this.composer,
    this.writer,
    required this.duration,
    this.bitrate,
    this.mimeType,
    required this.fileExtension,
    this.mediaStoreAlbumId,
  });

  factory AudioMetadata.fromMap(Map<String, dynamic> map) {
    return AudioMetadata(
      path: map['path'] as String,
      title: map['title'] as String,
      artist: map['artist'] as String,
      album: map['album'] as String,
      albumArtist: map['albumArtist'] as String,
      genre: map['genre'] as String,
      year: map['year'] as int?,
      trackNumber: map['trackNumber'] as int,
      composer: map['composer'] as String?,
      writer: map['writer'] as String?,
      duration: map['duration'] as int,
      bitrate: map['bitrate'] as int?,
      mimeType: map['mimeType'] as String?,
      fileExtension: map['fileExtension'] as String,
      mediaStoreAlbumId: map['mediaStoreAlbumId'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'path': path,
      'title': title,
      'artist': artist,
      'album': album,
      'albumArtist': albumArtist,
      'genre': genre,
      'year': year,
      'trackNumber': trackNumber,
      'composer': composer,
      'writer': writer,
      'duration': duration,
      'bitrate': bitrate,
      'mimeType': mimeType,
      'fileExtension': fileExtension,
      'mediaStoreAlbumId': mediaStoreAlbumId,
    };
  }
}

class AudioMetadataException implements Exception {
  final String message;
  final String? code;

  AudioMetadataException(this.message, [this.code]);

  @override
  String toString() =>
      'AudioMetadataException: $message${code != null ? ' (Code: $code)' : ''}';
}
