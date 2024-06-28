import 'dart:io';

import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/state/list_states/tracks_state.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

class PlaylistsState {
  final PlaylistStore store = PlaylistStore();
  List<PlayList> list = [];

  create(String name, {List<Track> tracks = const [], art}) async {
    final int id = DateTime.now().millisecond;
    await PlayListArtUtils.setPlaylistArt(id, art: art);
    PlayList newPlaylist = PlayList(
      playlistId: id,
      playlistName: name,
      playlistTracks: tracks,
      playlistArt: PlayListArtUtils.getPlaylistArtPath(id),
    );
    list.add(newPlaylist);
    await save(id);
  }

  delete(PlayList playlist) async {
    final int id = playlist.playlistId!;
    await store.dataStore.delete(id);
    await store.nameStore.delete(id);
    list.remove(playlist);
    PlayListArtUtils.deletePlaylistArt(id);
  }

  update(int id, {name, art}) async {
    PlayList thisPlaylist =
        list.firstWhere((playlist) => playlist.playlistId == id);

    if (name != null && name != "") {
      thisPlaylist.playlistName = name;
    }

    if (art != null) {
      await PlayListArtUtils.setPlaylistArt(id, art: art);
    }
    await save(id);
  }

  addTracks(int id, List<Track> tracks) async {
    PlayList thisPlaylist =
        list.firstWhere((playlist) => playlist.playlistId == id);
    thisPlaylist.playlistTracks = thisPlaylist.playlistTracks! + tracks;
    await save(id);
  }

  removeTrack(int id, int index) async {
    PlayList thisPlaylist =
        list.firstWhere((playlist) => playlist.playlistId == id);
    thisPlaylist.playlistTracks!.removeAt(index);
    await save(id);
  }

  save(int id) async {
    PlayList thisPlaylist =
        list.firstWhere((playlist) => playlist.playlistId == id);
    List<int> playlistTracks = [];
    if (thisPlaylist.playlistTracks!.isNotEmpty) {
      playlistTracks = thisPlaylist.playlistTracks!
          .map((track) => track.trackData!.trackId!)
          .toList();
    }
    await store.dataStore.put(id, playlistTracks);
    await store.nameStore.put(id, thisPlaylist.playlistName!);
  }

  init(TracksState allTracks) async {
    list = [];
    List<int> playlistIds = store.dataStore.keys.toList().cast();
    for (int playlistId in playlistIds) {
      List<int> playlistTrackIds = store.dataStore.get(playlistId)!;
      final PlayList thisPlaylist = PlayList(
        playlistId: playlistId,
        playlistName: store.nameStore.get(playlistId),
        playlistArt: PlayListArtUtils.getPlaylistArtPath(playlistId),
        playlistTracks: await _initTracks(playlistTrackIds, allTracks),
      );
      list.add(thisPlaylist);
    }
  }

  Future<List<Track>> _initTracks(List<int> ids, TracksState allTracks) async {
    List<Track> playlistTracks = [];
    for (int id in ids) {
      for (Track track in allTracks.list) {
        if (track.trackData!.trackId == id) {
          playlistTracks.add(track);
        }
      }
    }
    return playlistTracks;
  }
}

//
//
//

class PlayList {
  int? playlistId;
  String? playlistName;
  Uri? playlistArt;
  List<Track>? playlistTracks;
  PlayList({
    this.playlistId,
    this.playlistName,
    this.playlistArt,
    this.playlistTracks,
  });
}

//
//
//

class PlayListArtUtils {
  static String pathKey = "/coverarts/playlists/";

  static Future<Uint8List> defaultPlaylistArt() async {
    final art = await rootBundle.load(placeholderAssetImage);
    Uint8List artWork = art.buffer.asUint8List();
    return artWork;
  }

  static setPlaylistArt(int id, {art}) async {
    final artFilePath = "${antiiqDirectory.path}$pathKey$id.jpeg";
    Uint8List? artWork = art ?? await defaultPlaylistArt();

    File artFile = await File(artFilePath).create(recursive: true);

    await artFile.writeAsBytes(
      artWork!,
      mode: FileMode.write,
    );

    return Uri.file(artFilePath);
  }

  static deletePlaylistArt(int id) async {
    await File("${antiiqDirectory.path}$pathKey$id.jpeg").delete();
  }

  static Uri getPlaylistArtPath(int id) {
    final artFilePath = "${antiiqDirectory.path}$pathKey$id.jpeg";
    return Uri.file(artFilePath);
  }
}

//
//
//

class PlaylistStore {
  late Box<List<int>> dataStore;
  late Box<String> nameStore;
}
