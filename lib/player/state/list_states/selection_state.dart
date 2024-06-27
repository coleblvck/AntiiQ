import 'dart:async';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/utilities/user_settings.dart';

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

  _save() async {
    final List<int> selectionIds =
        list.map((track) => track.trackData!.trackId!).toList();
    await antiiqStore.put(BoxKeys().globalSelection, selectionIds);
  }
}
