import 'dart:async';

import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/utilities/file_handling/sort.dart';

class AlbumsState {
  List<Album> list = [];
  StreamController<List<Album>> flow = StreamController.broadcast();
  updateFlow() {
    flow.add(list);
  }
  SortArrangement sort = const SortArrangement(
    currentSort: "Album Name",
    currentDirection: "Ascending",
  );
  SortArrangement tracksSort = const SortArrangement(
    currentSort: "Track Number",
    currentDirection: "Ascending",
  );
}
