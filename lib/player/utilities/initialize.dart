import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:hive_flutter/hive_flutter.dart';

class Boxes {
  String mainBox = "antiiqBox";
  String playlistBox = "playlists";
  String playlistNameBox = "playlistNames";

  open(AntiiqState state) async {
    state.store = await Hive.openBox(mainBox);
    state.music.playlists.store.dataStore = await Hive.openBox(playlistBox);
    state.music.playlists.store.nameStore = await Hive.openBox(playlistNameBox);
  }
}




