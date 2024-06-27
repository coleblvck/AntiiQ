import 'dart:async';

import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/utilities/file_handling/sort.dart';

class GenresState {
  List<Genre> list = [];
  StreamController<List<Genre>> flow = StreamController.broadcast();
  updateFlow() {
    flow.add(list);
  }
  SortArrangement sort = const SortArrangement(
    currentSort: "Genre Name",
    currentDirection: "Ascending",
  );
  SortArrangement tracksSort = const SortArrangement(
    currentSort: "Track Name",
    currentDirection: "Ascending",
  );
}
