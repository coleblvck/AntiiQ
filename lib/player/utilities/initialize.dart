/*

Setup Song Library:
- Get all Songs, Albums, Artists and Genres and;
- Perform necessary conversions

*/

//Antiiq Packages
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:hive_flutter/hive_flutter.dart';

class Boxes {
  String mainBox = "antiiqBox";
  String playlistBox = "playlists";
  String playlistNameBox = "playlistNames";

  open() async {
    antiiqStore = await Hive.openBox(mainBox);
    state.music.playlists.store.dataStore = await Hive.openBox(playlistBox);
    state.music.playlists.store.nameStore = await Hive.openBox(playlistNameBox);
  }
}




