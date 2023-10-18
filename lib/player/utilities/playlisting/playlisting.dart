import 'package:antiiq/player/utilities/file_handling/lists.dart';
import 'package:flutter/services.dart';
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'dart:io';

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

List<PlayList> allPlaylists = [];

createPlaylist(String name, {List<Track> tracks = const [], art}) async {
  final int id = DateTime.now().millisecond;
  await setPlaylistArt(id, art: art);
  PlayList newPlaylist = PlayList(
    playlistId: id,
    playlistName: name,
    playlistTracks: tracks,
    playlistArt: getPlaylistArtPath(id),
  );
  allPlaylists.add(newPlaylist);
  await savePlaylistToStore(id);
}

deletePlaylist(PlayList playlist) async {
  final int id = playlist.playlistId!;
  await playlistStore.delete(id);
  await playlistNameStore.delete(id);
  allPlaylists.remove(playlist);
  deletePlaylistArt(id);
}

updatePlaylist(int id, {name, art}) async {
  PlayList thisPlaylist =
      allPlaylists.firstWhere((playlist) => playlist.playlistId == id);

  if (name != null && name != "") {
    thisPlaylist.playlistName = name;
  }

  if (art != null) {
    await setPlaylistArt(id, art: art);
  }
  await savePlaylistToStore(id);
}

addToPlaylist(int id, List<Track> tracks) async {
  PlayList thisPlaylist =
      allPlaylists.firstWhere((playlist) => playlist.playlistId == id);
  thisPlaylist.playlistTracks = thisPlaylist.playlistTracks! + tracks;
  await savePlaylistToStore(id);
}

removeFromPlaylist(int id, int index) async {
  PlayList thisPlaylist =
      allPlaylists.firstWhere((playlist) => playlist.playlistId == id);
  thisPlaylist.playlistTracks!.removeAt(index);
  await savePlaylistToStore(id);
}

savePlaylistToStore(int id) async {
  PlayList thisPlaylist =
      allPlaylists.firstWhere((playlist) => playlist.playlistId == id);
  List<int> playlistTracks = [];
  if (thisPlaylist.playlistTracks!.isNotEmpty) {
    playlistTracks = thisPlaylist.playlistTracks!
        .map((track) => track.trackData!.trackId!)
        .toList();
  }
  await playlistStore.put(id, playlistTracks);
  await playlistNameStore.put(id, thisPlaylist.playlistName!);
}

getPlaylistsfromStore() async {
  allPlaylists = [];
  List<int> playlistIds = playlistStore.keys.toList().cast();
  for (int playlistId in playlistIds) {
    List<int> playlistTrackIds = playlistStore.get(playlistId)!;
    final PlayList thisPlaylist = PlayList(
      playlistId: playlistId,
      playlistName: playlistNameStore.get(playlistId),
      playlistArt: getPlaylistArtPath(playlistId),
      playlistTracks: await getPlaylistTracks(playlistTrackIds),
    );
    allPlaylists.add(thisPlaylist);
  }
}

Future<List<Track>> getPlaylistTracks(List<int> ids) async {
  List<Track> playlistTracks = [];
  for (int id in ids) {
    for (Track track in currentTrackListSort) {
      if (track.trackData!.trackId == id) {
        playlistTracks.add(track);
      }
    }
  }
  return playlistTracks;
}

Future<Uint8List> defaultPlaylistArt() async {
  final art = await rootBundle.load(placeholderAssetImage);
  Uint8List artWork = art.buffer.asUint8List();
  return artWork;
}

setPlaylistArt(int id, {art}) async {
  final artFilePath = "${antiiqDirectory.path}/coverarts/playlists/$id.jpeg";
  Uint8List? artWork = art ?? await defaultPlaylistArt();

  File artFile = await File(artFilePath).create(recursive: true);

  await artFile.writeAsBytes(
    artWork!,
    mode: FileMode.write,
  );

  return Uri.file(artFilePath);
}

deletePlaylistArt(int id) async {
  await File("${antiiqDirectory.path}/coverarts/playlists/$id.jpeg").delete();
}

Uri getPlaylistArtPath(int id) {
  final artFilePath = "${antiiqDirectory.path}/coverarts/playlists/$id.jpeg";
  return Uri.file(artFilePath);
}
