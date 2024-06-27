import 'dart:async';

import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/utilities/file_handling/sort.dart';

class ArtistsState {
  List<Artist> list = [];
  StreamController<List<Artist>> flow = StreamController.broadcast();
  updateFlow() {
    flow.add(list);
  }
  SortArrangement sort = const SortArrangement(
    currentSort: "Artist Name",
    currentDirection: "Ascending",
  );
  SortArrangement tracksSort = const SortArrangement(
    currentSort: "Track Name",
    currentDirection: "Ascending",
  );
}
