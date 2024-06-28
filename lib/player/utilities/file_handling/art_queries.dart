import 'dart:io';

import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'package:on_audio_query/on_audio_query.dart';

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
  if (state.dataIsInitialized) {
    defaultArtUri =
        Uri.file("${antiiqDirectory.path}/coverarts/defaultart.jpeg");
  } else {
    defaultArtUri = await getDefaultArt();
  }
}

Future<Uint8List?> getSongArtBytes(id) async {
  Uint8List? artwork = await audioQuery.queryArtwork(id, ArtworkType.AUDIO,
      format: ArtworkFormat.JPEG, size: 350);
  return artwork;
}

Future<Uri> getSongArt(id) async {
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

Uri directSongArtPath(id) {
  return Uri.file("${antiiqDirectory.path}/coverarts/songs/$id.jpeg");
}

Future<Uint8List?> getAlbumArtBytes(id) async {
  Uint8List? artwork = await audioQuery.queryArtwork(id, ArtworkType.ALBUM,
      format: ArtworkFormat.JPEG, size: 350);
  return artwork;
}

Future<Uri> getAlbumArt(id, pathOfSong) async {
  final artFilePath = "${antiiqDirectory.path}/coverarts/albums/$id.jpeg";
  if (!state.dataIsInitialized) {
    Uint8List? art = await getAlbumArtBytes(id);
    art ??= await getDirectoryArt(pathOfSong) ?? await defaultArt();

    File artFile = await File(artFilePath).create(recursive: true);

    await artFile.writeAsBytes(
      art,
      mode: FileMode.write,
    );
  } else {
    if (!await File(artFilePath).exists()) {
      Uint8List? art = await getAlbumArtBytes(id);
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

Uri directAlbumArtPath(id) {
  return Uri.file("${antiiqDirectory.path}/coverarts/albums/$id.jpeg");
}

Map<int, Uri> albumArtsList = {};

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
      if (lookupMimeType(dirFile.path) != null && lookupMimeType(dirFile.path)!.contains("image")) {
        artToReturn = await dirFile.readAsBytes();
        break;
      }
    }
  }
  return artToReturn;
}