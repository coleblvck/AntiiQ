import 'dart:io';
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';

//Cover Art setup
Future<Uint8List> defaultArt() async {
  final art = await rootBundle.load(placeholderAssetImage);
  Uint8List artWork = art.buffer.asUint8List();
  return artWork;
}

getDefaultArt() async {
  Uint8List art = await defaultArt();
  final artFilePath = "${antiiqDirectory.path}/coverarts/defaultart.jpeg";
  File artFile = await File(artFilePath).create(recursive: true);
  await artFile.writeAsBytes(
    art,
    mode: FileMode.write,
  );
  final result = Uri.file(artFilePath);
  return result;
}

setDefaultArt() async {
  if (antiiqState.dataIsInitialized) {
    defaultArtUri = Uri.file("${antiiqDirectory.path}/coverarts/defaultart.jpeg");
  } else {
    defaultArtUri = await getDefaultArt();
  }
}

// UPDATED: Changed from Map<int, Uri> to Map<String, Uri>
// Now supports both int keys (legacy) and String keys (new album-based keys)
Map<String, Uri> albumArtsList = {};

// Helper function to get album art by key (int or String)
Uri? getAlbumArtByKey(dynamic key) {
  if (key is int) {
    return albumArtsList[key.toString()];
  } else if (key is String) {
    return albumArtsList[key];
  }
  return null;
}

// Helper function to set album art by key (int or String)
void setAlbumArtByKey(dynamic key, Uri uri) {
  if (key is int) {
    albumArtsList[key.toString()] = uri;
  } else if (key is String) {
    albumArtsList[key] = uri;
  }
}

// Legacy functions for backward compatibility with on_audio_query
Future<Uint8List?> getSongArtBytes(int id) async {
  // This would need on_audio_query - kept for reference only
  // You can remove this if not needed
  return null;
}

Future<Uri> getSongArt(int id) async {
  Uint8List? art = await getSongArtBytes(id);
  art ??= await defaultArt();
  final artFilePath = "${antiiqDirectory.path}/coverarts/songs/$id.jpeg";
  File artFile = await File(artFilePath).create(recursive: true);
  await artFile.writeAsBytes(
    art,
    mode: FileMode.write,
  );
  return Uri.file(artFilePath);
}

Uri directSongArtPath(int id) {
  return Uri.file("${antiiqDirectory.path}/coverarts/songs/$id.jpeg");
}

Future<Uint8List?> getAlbumArtBytes(int id) async {
  // This would need on_audio_query - kept for reference only
  // You can remove this if not needed
  return null;
}

Future<Uri> getAlbumArt(dynamic id, String pathOfSong) async {
  // Support both int (legacy) and String (new) keys
  final String idString = id is int ? id.toString() : id as String;
  final artFilePath = "${antiiqDirectory.path}/coverarts/albums/$idString.jpeg";
  
  if (!antiiqState.dataIsInitialized) {
    Uint8List? art = await getAlbumArtBytes(id is int ? id : 0);
    art ??= await getDirectoryArt(pathOfSong) ?? await defaultArt();
    File artFile = await File(artFilePath).create(recursive: true);
    await artFile.writeAsBytes(
      art,
      mode: FileMode.write,
    );
  } else {
    if (!await File(artFilePath).exists()) {
      Uint8List? art = await getAlbumArtBytes(id is int ? id : 0);
      art ??= await defaultArt();
      File artFile = await File(artFilePath).create(recursive: true);
      await artFile.writeAsBytes(
        art,
        mode: FileMode.write,
      );
    }
  }
  return Uri.file(artFilePath);
}

Uri directAlbumArtPath(dynamic id) {
  final String idString = id is int ? id.toString() : id as String;
  return Uri.file("${antiiqDirectory.path}/coverarts/albums/$idString.jpeg");
}

//ToDo
setTempArt(Uint8List picture) {}

List<FileSystemEntity> getAllDirectoryFiles(Directory dir) {
  return dir.listSync(recursive: false, followLinks: false);
}

Future<Uint8List?> getDirectoryArt(String pathOfSong) async {
  Directory dir = File(pathOfSong).parent;
  Uint8List? artToReturn;
  List<FileSystemEntity> allDirFiles = getAllDirectoryFiles(dir);
  
  for (FileSystemEntity dirFile in allDirFiles) {
    if (dirFile is File) {
      if (lookupMimeType(dirFile.path) != null && 
          lookupMimeType(dirFile.path)!.contains("image")) {
        artToReturn = await dirFile.readAsBytes();
        break;
      }
    }
  }
  return artToReturn;
}