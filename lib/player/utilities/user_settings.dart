import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/utilities/audio_preferences.dart';
import 'package:antiiq/player/ui/elements/ui_colours.dart';

class Boxes {
  String userTheme = "currentTheme";
  String includedPaths = "libraryPaths";
  String minimumTrackLength = "minimumTrackLength";
  String previousRestart = "previousRestart";
  String eqEnabledStorage = "equalizerEnabled";
  String bandFrequencyStorage = "bandFreqs";
  String loopModeStorage = "loopMode";
  String shuffleModeStorage = "shuffleMode";
  String swipeGestures = "swipeGestures";
}

changeTheme(String theme) async {
  currentTheme = theme;
  await antiiqStore.put(Boxes().userTheme, theme);
  themeStream.add(getColorScheme());
}

updateDirectories() async {
  await antiiqStore.put(Boxes().includedPaths, specificPathsToQuery);
}

setMinimumTrackLength(int length) async {
  minimumTrackLength = length;
  await antiiqStore.put(Boxes().minimumTrackLength, length);
}

setPreviousButtonAction(bool restart) async {
  previousRestart = restart;
  await antiiqStore.put(Boxes().previousRestart, restart);
}

//Initializations
initializeUserSettings() async {
  await themeInit();
  await getUserLibraryDirectories();
  await getMinimumTrackLength();
  await getPreviousButtonAction();
  await getSwipeGestures();
}

initializeAudioPreferences() async {
  await getEqualizerEnabled();
  await getBandFreqs();
  await getAndSetLoopMode();
  await getAndSetShuffleMode();
}

themeInit() async {
  currentTheme =
      await antiiqStore.get(Boxes().userTheme, defaultValue: "AntiiQ");
  themeStream.add(getColorScheme());
}

getUserLibraryDirectories() async {
  specificPathsToQuery =
      await antiiqStore.get(Boxes().includedPaths, defaultValue: <String>[]);
}

getMinimumTrackLength() async {
  minimumTrackLength =
      await antiiqStore.get(Boxes().minimumTrackLength, defaultValue: 45);
}

getPreviousButtonAction() async {
  previousRestart =
      await antiiqStore.get(Boxes().previousRestart, defaultValue: false);
}

setSwipeGestures(bool enabled) async {
  swipeGestures = enabled;
  await antiiqStore.put(Boxes().swipeGestures, enabled);
}

getSwipeGestures() async {
  swipeGestures =
      await antiiqStore.get(Boxes().swipeGestures, defaultValue: true);
}
