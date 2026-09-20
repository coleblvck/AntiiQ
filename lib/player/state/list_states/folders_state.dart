import 'dart:async';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';

class FoldersState {
  List<LibraryFolder> roots = [];
  final StreamController<List<LibraryFolder>> flow =
      StreamController.broadcast();
  void updateFlow() => flow.add(roots);
}
