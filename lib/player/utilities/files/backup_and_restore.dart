import 'dart:io';

import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/utilities/initialize.dart';
import 'package:antiiq/player/utilities/playlisting/playlisting.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:restart_app/restart_app.dart';

backup(String savePath) async {
  final dataPath = antiiqStore.path;
  final playListsPath = playlistStore.path;
  final playListsDataPath = playlistNameStore.path;
  await antiiqStore.close();
  await playlistStore.close();
  await playlistNameStore.close();

  try {
    File(dataPath!).copy("$savePath/data.antiiq");
    File(playListsPath!).copy("$savePath/playlists.antiiq");
    File(playListsDataPath!).copy("$savePath/playlistsdata.antiiq");
  } finally {
    antiiqStore = await Hive.openBox(Boxes().mainBox);
    playlistStore = await Hive.openBox(Boxes().playlistBox);
    playlistNameStore = await Hive.openBox(Boxes().playlistNameBox);
  }
}

restore(String savePath) async {
  final dataPath = antiiqStore.path;
  final playListsPath = playlistStore.path;
  final playListsDataPath = playlistNameStore.path;
  await antiiqStore.close();
  await playlistStore.close();
  await playlistNameStore.close();

  try {
    File("$savePath/data.antiiq").copy(dataPath!);
    File("$savePath/playlists.antiiq").copy(playListsPath!);
    File("$savePath/playlistsdata.antiiq").copy(playListsDataPath!);
  } finally {
    antiiqStore = await Hive.openBox(Boxes().mainBox);
    playlistStore = await Hive.openBox(Boxes().playlistBox);
    playlistNameStore = await Hive.openBox(Boxes().playlistNameBox);
  }

  await restorePlaylists();
  Restart.restartApp();
}

restorePlaylists() async {
  allPlaylists = [];
  List<int> playlistIds = playlistStore.keys.toList().cast();
  for (int playlistId in playlistIds) {
    await setPlaylistArt(playlistId);
  }
}
