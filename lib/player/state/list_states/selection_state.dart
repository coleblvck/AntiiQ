import 'dart:async';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/state/list_states/tracks_state.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/utilities/settings/user_settings.dart';

class SelectionState {
  List<Track> list = [];
  StreamController<List<Track>> flow = StreamController.broadcast();

  updateFlow() {
    flow.add(list);
  }

  selectOrDeselect(Track track) async {
    if (list.contains(track)) {
      await _remove(track);
    } else {
      await _add(track);
    }
  }

  _add(Track track) async {
    list.add(track);
    updateFlow();
    await _save();
  }

  _remove(Track track) async {
    list.remove(track);
    updateFlow();
    await _save();
  }

  clear() async {
    list = [];
    updateFlow();
    await _save();
  }
  init(TracksState tracks) async {
    final List<int> selectionIds =
    await antiiqState.store.get(MainBoxKeys.globalSelection, defaultValue: <int>[]);
    list = [];
    for (int id in selectionIds) {
      for (Track track in tracks.list) {
        if (track.trackData!.trackId == id) {
          list.add(track);
        }
      }
    }
    updateFlow();
  }

  _save() async {
    final List<int> selectionIds =
        list.map((track) => track.trackData!.trackId!).toList();
    await antiiqState.store.put(MainBoxKeys.globalSelection, selectionIds);
  }
}
