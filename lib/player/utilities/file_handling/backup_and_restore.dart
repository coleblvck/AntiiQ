import 'dart:io';

import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/state/list_states/playlists_state.dart';
import 'package:antiiq/player/utilities/initialize.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:restart_app/restart_app.dart';

backup(String savePath) async {
  final dataPath = antiiqStore.path;
  final playListsPath = state.music.playlists.store.dataStore.path;
  final playListsDataPath = state.music.playlists.store.nameStore.path;
  await antiiqStore.close();
  await state.music.playlists.store.dataStore.close();
  await state.music.playlists.store.nameStore.close();

  try {
    File(dataPath!).copy("$savePath/data.antiiq");
    File(playListsPath!).copy("$savePath/playlists.antiiq");
    File(playListsDataPath!).copy("$savePath/playlistsdata.antiiq");
  } finally {
    antiiqStore = await Hive.openBox(Boxes().mainBox);
    state.music.playlists.store.dataStore = await Hive.openBox(Boxes().playlistBox);
    state.music.playlists.store.nameStore = await Hive.openBox(Boxes().playlistNameBox);
  }
}

restore(String savePath) async {
  final dataPath = antiiqStore.path;
  final playListsPath = state.music.playlists.store.dataStore.path;
  final playListsDataPath = state.music.playlists.store.nameStore.path;
  await antiiqStore.close();
  await state.music.playlists.store.dataStore.close();
  await state.music.playlists.store.nameStore.close();

  try {
    File("$savePath/data.antiiq").copy(dataPath!);
    File("$savePath/playlists.antiiq").copy(playListsPath!);
    File("$savePath/playlistsdata.antiiq").copy(playListsDataPath!);
  } finally {
    antiiqStore = await Hive.openBox(Boxes().mainBox);
    state.music.playlists.store.dataStore = await Hive.openBox(Boxes().playlistBox);
    state.music.playlists.store.nameStore = await Hive.openBox(Boxes().playlistNameBox);
  }

  await restorePlaylists();
  Restart.restartApp();
}

restorePlaylists() async {
  state.music.playlists.list = [];
  List<int> playlistIds = state.music.playlists.store.dataStore.keys.toList().cast();
  for (int playlistId in playlistIds) {
    await PlayListArtUtils.setPlaylistArt(playlistId);
  }
}
