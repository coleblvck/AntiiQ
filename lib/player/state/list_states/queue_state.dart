import 'dart:async';

import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/state/list_states/tracks_state.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/utilities/user_settings.dart';
import 'package:audio_service/audio_service.dart';

class QueueState {
  List<MediaItem> initialState = [];
  List<MediaItem> _state = [];
  final StreamController<List<MediaItem>> _flow = StreamController.broadcast();

  List<MediaItem> get state => _state;
  StreamController<List<MediaItem>> get flow => _flow;

  init(TracksState tracks) async {
    await _getInitialState(tracks);
    _initListen();
  }

  _initListen() {
    audioHandler.queue.asBroadcastStream().distinct().listen(_onQueueChange);
  }

  void _onQueueChange(List<MediaItem> itemList) async {
    _state = itemList;
    _flow.add(itemList);
    await _save();
  }

  _getInitialState(TracksState tracks) async {
    initialState = [];
    List<int> stateToInit =
    await antiiqState.store.get(MainBoxKeys.queueState, defaultValue: <int>[]);
    for (int id in stateToInit) {
      for (Track track in tracks.list) {
        if (track.trackData!.trackId == id) {
          initialState.add(track.mediaItem!);
        }
      }
    }
  }

  _save() async {
    List<int> stateToSave =
    _state.map((item) => item.extras!["id"]).toList().cast();
    await antiiqState.store.put(MainBoxKeys.queueState, stateToSave);
  }
}
