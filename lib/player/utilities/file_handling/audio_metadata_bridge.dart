import 'package:flutter/services.dart';

class AudioMetadataBridge {
  static const MethodChannel _channel =
      MethodChannel('com.coleblvck.antiiq/audio_metadata');
  static void Function(AudioScanProgress progress)? _progressListener;
  static void Function(List<AudioMetadata> metadata)? _metadataBatchListener;

  static void setProgressListener(
    void Function(AudioScanProgress progress)? listener,
  ) {
    _progressListener = listener;
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  static void setMetadataBatchListener(
    void Function(List<AudioMetadata> metadata)? listener,
  ) {
    _metadataBatchListener = listener;
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  static Future<dynamic> _handleNativeCall(MethodCall call) async {
    final arguments = call.arguments;
    if (call.method == 'scanProgress') {
      if (arguments is! Map) return null;
      _progressListener?.call(
        AudioScanProgress.fromMap(Map<String, dynamic>.from(arguments)),
      );
    } else if (call.method == 'scanMetadataBatch') {
      if (arguments is! List) return null;
      _metadataBatchListener?.call(
        arguments
            .map((item) => AudioMetadata.fromMap(
                  Map<String, dynamic>.from(item as Map),
                ))
            .toList(),
      );
    }
    return null;
  }

  static Future<List<AudioMetadata>> scanAllStorageWithMetadata({
    List<String> knownPaths = const [],
  }) async {
    try {
      final List<dynamic> result = await _channel.invokeMethod(
        'scanAllStorageWithMetadata',
        {'knownPaths': knownPaths},
      );

      return result
          .map((item) => AudioMetadata.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } on PlatformException catch (e) {
      throw AudioMetadataException(
        'Failed to scan storage: ${e.message}',
        e.code,
      );
    }
  }

  /// Scans directory and returns metadata in ONE call (for custom paths)
  static Future<List<AudioMetadata>> scanDirectoryWithMetadata(
    String path, {
    bool recursive = true,
    List<String> knownPaths = const [],
  }) async {
    try {
      final List<dynamic> result = await _channel.invokeMethod(
        'scanDirectoryWithMetadata',
        {
          'path': path,
          'recursive': recursive,
          'knownPaths': knownPaths,
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

  static Future<PreparedIntentAudio> prepareIntentAudio(String uri) async {
    try {
      final Map<dynamic, dynamic> result = await _channel.invokeMethod(
        'prepareIntentAudio',
        {'uri': uri},
      );

      return PreparedIntentAudio.fromMap(Map<String, dynamic>.from(result));
    } on PlatformException catch (e) {
      throw AudioMetadataException(
        'Failed to prepare intent audio: ${e.message}',
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
}

class PreparedIntentAudio {
  const PreparedIntentAudio({
    required this.path,
    this.displayName,
    this.mimeType,
  });

  final String path;
  final String? displayName;
  final String? mimeType;

  factory PreparedIntentAudio.fromMap(Map<String, dynamic> map) {
    return PreparedIntentAudio(
      path: map['path'] as String,
      displayName: map['displayName'] as String?,
      mimeType: map['mimeType'] as String?,
    );
  }
}

class AudioScanProgress {
  final String stage;
  final String message;
  final int progress;
  final int total;

  const AudioScanProgress({
    required this.stage,
    required this.message,
    required this.progress,
    required this.total,
  });

  factory AudioScanProgress.fromMap(Map<String, dynamic> map) {
    return AudioScanProgress(
      stage: map['stage'] as String? ?? 'scanning',
      message: map['message'] as String? ?? 'Scanning Library',
      progress: map['progress'] as int? ?? 0,
      total: map['total'] as int? ?? 0,
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
