import 'dart:async';

import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/utilities/audio_preferences.dart';
import 'package:antiiq/player/ui/elements/ui_colours.dart';
import 'package:antiiq/player/utilities/initialize.dart';

class BoxKeys {
  String userTheme = "currentTheme";
  String includedPaths = "libraryPaths";
  String minimumTrackLength = "minimumTrackLength";
  String previousRestart = "previousRestart";
  String eqEnabledStorage = "equalizerEnabled";
  String bandFrequencyStorage = "bandFreqs";
  String loopModeStorage = "loopMode";
  String shuffleModeStorage = "shuffleMode";
  String swipeGestures = "swipeGestures";
  String runtimeAutoScanEnabled = "runtimeAutoScanEnabled";
  String runtimeAutoScanInterval = "runtimeAutoScanInterval";
  String interactiveSeekBar = "interactiveSeekBar";
  String queueState = "queueState";
  String globalSelection = "globalSelection";
}

changeTheme(String theme) async {
  currentTheme = theme;
  await antiiqStore.put(BoxKeys().userTheme, theme);
  themeStream.add(getColorScheme());
}

updateDirectories() async {
  await antiiqStore.put(BoxKeys().includedPaths, specificPathsToQuery);
}

setMinimumTrackLength(int length) async {
  minimumTrackLength = length;
  await antiiqStore.put(BoxKeys().minimumTrackLength, length);
}

setPreviousButtonAction(bool restart) async {
  previousRestart = restart;
  await antiiqStore.put(BoxKeys().previousRestart, restart);
}

//Initializations
initializeUserSettings() async {
  await themeInit();
  await getUserLibraryDirectories();
  await getMinimumTrackLength();
  await getPreviousButtonAction();
  await getSwipeGestures();
  await initInteractiveSeekBarSwitch();
}

initializeAudioPreferences() async {
  await getEqualizerEnabled();
  await getBandFreqs();
  await getAndSetLoopMode();
  await getAndSetShuffleMode();
}

themeInit() async {
  currentTheme =
      await antiiqStore.get(BoxKeys().userTheme, defaultValue: "AntiiQ");
  themeStream.add(getColorScheme());
}

getUserLibraryDirectories() async {
  specificPathsToQuery =
      await antiiqStore.get(BoxKeys().includedPaths, defaultValue: <String>[]);
}

getMinimumTrackLength() async {
  minimumTrackLength =
      await antiiqStore.get(BoxKeys().minimumTrackLength, defaultValue: 45);
}

getPreviousButtonAction() async {
  previousRestart =
      await antiiqStore.get(BoxKeys().previousRestart, defaultValue: false);
}

setSwipeGestures(bool enabled) async {
  swipeGestures = enabled;
  await antiiqStore.put(BoxKeys().swipeGestures, enabled);
}

getSwipeGestures() async {
  swipeGestures =
      await antiiqStore.get(BoxKeys().swipeGestures, defaultValue: true);
}

/*
switchRuntimeAutoScanEnabled(bool value) async {
  runtimeAutoScanTimer.isActive ? runtimeAutoScanTimer.cancel() : null;
  runtimeAutoScanEnabled = value;
  if (value) {
    runtimeAutoScanTimer =
        Timer.periodic(runtimeAutoScanInterval, (timer) => autoReloadLibrary());
  } else {
    runtimeAutoScanTimer.isActive ? runtimeAutoScanTimer.cancel() : null;
  }
  await antiiqStore.put(BoxKeys().runtimeAutoScanEnabled, value);
}

changeRuntimeAutoScanInterval(int minutes) async {
  runtimeAutoScanInterval = Duration(minutes: minutes);
  runtimeAutoScanEnabled
      ? await switchRuntimeAutoScanEnabled(runtimeAutoScanEnabled)
      : null;
  await antiiqStore.put(BoxKeys().runtimeAutoScanInterval, minutes);
}

initRuntimeAutoScan() async {
  final bool value = await antiiqStore.get(BoxKeys().runtimeAutoScanEnabled,
      defaultValue: true);

  final int autoScanInterval =
      await antiiqStore.get(BoxKeys().runtimeAutoScanInterval, defaultValue: 3);

  runtimeAutoScanInterval = Duration(minutes: autoScanInterval);

  runtimeAutoScanTimer =
      Timer.periodic(runtimeAutoScanInterval, (timer) => autoReloadLibrary());
  runtimeAutoScanEnabled = value;
  if (value) {
    runtimeAutoScanTimer.cancel();
    runtimeAutoScanTimer =
        Timer.periodic(runtimeAutoScanInterval, (timer) => autoReloadLibrary());
  } else {
    runtimeAutoScanTimer.isActive ? runtimeAutoScanTimer.cancel() : null;
  }
}
*/

initInteractiveSeekBarSwitch() async {
  interactiveMiniPlayerSeekbar =
      await antiiqStore.get(BoxKeys().interactiveSeekBar, defaultValue: true);
}

interactiveSeekBarSwitch(bool value) async {
  interactiveMiniPlayerSeekbar = value;
  interactiveSeekbarStream.add(value);
  await antiiqStore.put(BoxKeys().interactiveSeekBar, value);
}
