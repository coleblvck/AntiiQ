import 'dart:async';

import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/utilities/file_handling/sort.dart';

class TracksState {
  List<Track> list = [];
  StreamController<List<Track>> flow = StreamController.broadcast();
  updateFlow() {
    flow.add(list);
  }
  SortArrangement sort = const SortArrangement(
    currentSort: "Track Name",
    currentDirection: "Ascending",
  );
}
