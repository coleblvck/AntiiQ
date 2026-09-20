import 'dart:io';

import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/state/list_states/playlists_state.dart';
import 'package:antiiq/player/utilities/file_handling/backup_storage_bridge.dart';
import 'package:antiiq/player/utilities/initialize.dart';
import 'package:hive_flutter/hive_flutter.dart';

class _StorePaths {
  const _StorePaths({
    required this.main,
    required this.playlists,
    required this.playlistNames,
  });

  final String main;
  final String playlists;
  final String playlistNames;
}

Future<void> backup(String savePath) async {
  final paths = await _closeStores();

  try {
    await BackupStorageBridge.exportBackup(
      directoryUri: savePath,
      files: {
        'data.antiiq': paths.main,
        'playlists.antiiq': paths.playlists,
        'playlistsdata.antiiq': paths.playlistNames,
      },
    );
  } finally {
    await _openStores();
  }
}

Future<void> restore(String savePath) async {
  final paths = await _closeStores();
  final temporaryPaths = {
    'data.antiiq': '${paths.main}.restore',
    'playlists.antiiq': '${paths.playlists}.restore',
    'playlistsdata.antiiq': '${paths.playlistNames}.restore',
  };
  try {
    await BackupStorageBridge.importBackup(
      directoryUri: savePath,
      files: temporaryPaths,
    );
    await _replaceFile(temporaryPaths['data.antiiq']!, paths.main);
    await _replaceFile(temporaryPaths['playlists.antiiq']!, paths.playlists);
    await _replaceFile(
      temporaryPaths['playlistsdata.antiiq']!,
      paths.playlistNames,
    );
  } finally {
    await Future.wait(temporaryPaths.values.map(_deleteIfExists));
    await _openStores();
  }

  await restorePlaylists();
}

Future<void> _replaceFile(String source, String destination) async {
  final destinationFile = File(destination);
  if (await destinationFile.exists()) {
    await destinationFile.delete();
  }
  await File(source).rename(destination);
}

Future<void> _deleteIfExists(String path) async {
  final file = File(path);
  if (await file.exists()) {
    await file.delete();
  }
}

Future<_StorePaths> _closeStores() async {
  final mainPath = antiiqState.store.path;
  final playlistsPath = antiiqState.music.playlists.store.dataStore.path;
  final playlistNamesPath = antiiqState.music.playlists.store.nameStore.path;
  if (mainPath == null || playlistsPath == null || playlistNamesPath == null) {
    throw const FileSystemException('AntiiQ data stores are unavailable.');
  }

  await Future.wait([
    antiiqState.store.flush(),
    antiiqState.music.playlists.store.dataStore.flush(),
    antiiqState.music.playlists.store.nameStore.flush(),
  ]);
  await Future.wait([
    antiiqState.store.close(),
    antiiqState.music.playlists.store.dataStore.close(),
    antiiqState.music.playlists.store.nameStore.close(),
  ]);

  return _StorePaths(
    main: mainPath,
    playlists: playlistsPath,
    playlistNames: playlistNamesPath,
  );
}

Future<void> _openStores() async {
  antiiqState.store = await Hive.openBox(Boxes().mainBox);
  antiiqState.music.playlists.store.dataStore =
      await Hive.openBox(Boxes().playlistBox);
  antiiqState.music.playlists.store.nameStore =
      await Hive.openBox(Boxes().playlistNameBox);
}

Future<void> restorePlaylists() async {
  antiiqState.music.playlists.list = [];
  final playlistIds =
      antiiqState.music.playlists.store.dataStore.keys.toList().cast<int>();
  for (final playlistId in playlistIds) {
    await PlayListArtUtils.setPlaylistArt(playlistId);
  }
}
