import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/utilities/file_handling/lists.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/utilities/user_settings.dart';

globalSelectOrDeselect(Track track) async {
  if (globalSelection.contains(track)) {
    await removeFromGlobalSelection(track);
  } else {
    await addToGlobalSelection(track);
  }
}

addToGlobalSelection(Track track) async {
  globalSelection.add(track);
  globalSelectionStream.add(globalSelection);
  await saveGlobalSelection();
}

removeFromGlobalSelection(Track track) async {
  globalSelection.remove(track);
  globalSelectionStream.add(globalSelection);
  await saveGlobalSelection();
}

clearGlobalSelection() async {
  globalSelection = [];
  globalSelectionStream.add(globalSelection);
  await saveGlobalSelection();
}

saveGlobalSelection() async {
  final List<int> selectionIds =
      globalSelection.map((track) => track.trackData!.trackId!).toList();
  await antiiqStore.put(BoxKeys().globalSelection, selectionIds);
}

initGlobalSelection() async {
  final List<int> selectionIds =
      await antiiqStore.get(BoxKeys().globalSelection, defaultValue: <int>[]);
  globalSelection = [];
  for (int id in selectionIds) {
    for (Track track in currentTrackListSort) {
      if (track.trackData!.trackId == id) {
        globalSelection.add(track);
      }
    }
  }
  globalSelectionStream.add(globalSelection);
}
