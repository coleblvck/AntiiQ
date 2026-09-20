import 'dart:async';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';

class AlbumArtistsState {
  List<AlbumArtist> list = [];
  final StreamController<List<AlbumArtist>> flow = StreamController.broadcast();
  void updateFlow() => flow.add(list);
}
