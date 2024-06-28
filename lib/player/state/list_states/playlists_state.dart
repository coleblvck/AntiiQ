import 'dart:io';

import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/state/list_states/tracks_state.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:flutter/services.dart';


class PlaylistsState {
  List<PlayList> all = [];

  createPlaylist(String name, {List<Track> tracks = const [], art}) async {
    final int id = DateTime.now().millisecond;
    await PlayListArtUtils.setPlaylistArt(id, art: art);
    PlayList newPlaylist = PlayList(
      playlistId: id,
      playlistName: name,
      playlistTracks: tracks,
      playlistArt: PlayListArtUtils.getPlaylistArtPath(id),
    );
    all.add(newPlaylist);
    await savePlaylist(id);
  }

  deletePlaylist(PlayList playlist) async {
    final int id = playlist.playlistId!;
    await playlistStore.delete(id);
    await playlistNameStore.delete(id);
    all.remove(playlist);
    PlayListArtUtils.deletePlaylistArt(id);
  }

  updatePlaylist(int id, {name, art}) async {
    PlayList thisPlaylist =
    all.firstWhere((playlist) => playlist.playlistId == id);

    if (name != null && name != "") {
      thisPlaylist.playlistName = name;
    }

    if (art != null) {
      await PlayListArtUtils.setPlaylistArt(id, art: art);
    }
    await savePlaylist(id);
  }

  addToPlaylist(int id, List<Track> tracks) async {
    PlayList thisPlaylist =
    all.firstWhere((playlist) => playlist.playlistId == id);
    thisPlaylist.playlistTracks = thisPlaylist.playlistTracks! + tracks;
    await savePlaylist(id);
  }

  removeFromPlaylist(int id, int index) async {
    PlayList thisPlaylist =
    all.firstWhere((playlist) => playlist.playlistId == id);
    thisPlaylist.playlistTracks!.removeAt(index);
    await savePlaylist(id);
  }

  savePlaylist(int id) async {
    PlayList thisPlaylist =
    all.firstWhere((playlist) => playlist.playlistId == id);
    List<int> playlistTracks = [];
    if (thisPlaylist.playlistTracks!.isNotEmpty) {
      playlistTracks = thisPlaylist.playlistTracks!
          .map((track) => track.trackData!.trackId!)
          .toList();
    }
    await playlistStore.put(id, playlistTracks);
    await playlistNameStore.put(id, thisPlaylist.playlistName!);
  }

  init(TracksState tracks) async {
    all = [];
    List<int> playlistIds = playlistStore.keys.toList().cast();
    for (int playlistId in playlistIds) {
      List<int> playlistTrackIds = playlistStore.get(playlistId)!;
      final PlayList thisPlaylist = PlayList(
        playlistId: playlistId,
        playlistName: playlistNameStore.get(playlistId),
        playlistArt: PlayListArtUtils.getPlaylistArtPath(playlistId),
        playlistTracks: await _initPlaylistTracks(playlistTrackIds, tracks),
      );
      all.add(thisPlaylist);
    }
  }

  Future<List<Track>> _initPlaylistTracks(List<int> ids, TracksState allTracks) async {
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

class PlayListArtUtils {
  static Future<Uint8List> defaultPlaylistArt() async {
    final art = await rootBundle.load(placeholderAssetImage);
    Uint8List artWork = art.buffer.asUint8List();
    return artWork;
  }

  static setPlaylistArt(int id, {art}) async {
    final artFilePath = "${antiiqDirectory.path}/coverarts/playlists/$id.jpeg";
    Uint8List? artWork = art ?? await defaultPlaylistArt();

    File artFile = await File(artFilePath).create(recursive: true);

    await artFile.writeAsBytes(
      artWork!,
      mode: FileMode.write,
    );

    return Uri.file(artFilePath);
  }

  static deletePlaylistArt(int id) async {
    await File("${antiiqDirectory.path}/coverarts/playlists/$id.jpeg").delete();
  }

  static Uri getPlaylistArtPath(int id) {
    final artFilePath = "${antiiqDirectory.path}/coverarts/playlists/$id.jpeg";
    return Uri.file(artFilePath);
  }
}