//Dart Packages
import 'dart:io';

import 'package:flutter/services.dart';

import 'package:on_audio_query/on_audio_query.dart';

//Antiiq Packages
import 'package:antiiq/player/global_variables.dart';

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
  if (dataIsInitialized) {
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

Future<Uri> getAlbumArt(id) async {
  final artFilePath = "${antiiqDirectory.path}/coverarts/albums/$id.jpeg";
  if (!dataIsInitialized) {
    Uint8List? art = await getAlbumArtBytes(id);
    art ??= await defaultArt();

    File artFile = await File(artFilePath).create(recursive: true);

    await artFile.writeAsBytes(
      art,
      mode: FileMode.write,
    );
  }
  return Uri.file(artFilePath);
}

Uri directAlbumArtPath(id) {
  return Uri.file("${antiiqDirectory.path}/coverarts/albums/$id.jpeg");
}

Map<int, Uri> albumArtsList = {};
