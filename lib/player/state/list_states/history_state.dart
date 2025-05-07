import 'dart:async';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/state/list_states/tracks_state.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/utilities/settings/user_settings.dart';

class HistoryState {
  List<Track> list = [];
  StreamController<List<Track>> flow = StreamController.broadcast();

  updateFlow() {
    flow.add(list);
  }

  add(Track track) async {
    await _add(track);
  }

  _add(Track track) async {
    list.add(track);
    updateFlow();
    await _save();
  }

  clear() async {
    list = [];
    updateFlow();
    await _save();
  }

  init(TracksState tracks) async {
    final List<int> historyIds =
    await antiiqState.store.get(MainBoxKeys.history, defaultValue: <int>[]);
    list = [];
    for (int id in historyIds) {
      for (Track track in tracks.list) {
        if (track.trackData!.trackId == id) {
          list.add(track);
        }
      }
    }
    updateFlow();
  }

  _save() async {
    final List<int> historyIds =
        list.map((track) => track.trackData!.trackId!).toList();
    await antiiqState.store.put(MainBoxKeys.history, historyIds);
  }
}
