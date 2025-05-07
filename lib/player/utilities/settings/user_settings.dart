import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/ui/elements/ui_colours.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/settings/theme_settings.dart';
import 'package:flutter/services.dart';

class MainBoxKeys {
  static const String userTheme = "currentTheme";
  static const String includedPaths = "libraryPaths";
  static const String minimumTrackLength = "minimumTrackLength";
  static const String previousRestart = "previousRestart";
  static const String eqEnabledStorage = "equalizerEnabled";
  static const String bandFrequencyStorage = "bandFreqs";
  static const String loopModeStorage = "loopMode";
  static const String shuffleModeStorage = "shuffleMode";
  static const String swipeGestures = "swipeGestures";
  static const String runtimeAutoScanEnabled = "runtimeAutoScanEnabled";
  static const String runtimeAutoScanInterval = "runtimeAutoScanInterval";
  static const String interactiveSeekBar = "interactiveSeekBar";
  static const String queueState = "queueState";
  static const String globalSelection = "globalSelection";
  static const String history = "history";
  static const String favourites = "favourites";
  static const String showTrackDuration = "showTrackDuration";
  static const String generalRadius = "generalRadius";
  static const String quitType = "quitType";
  static const String statusBarMode = "statusBarMode";
  static const String colorSchemeType = "colorSchemeType";
  static const String customColorList = "customColorScheme";
  static const String dynamicThemeEnabled = "dynamicThemeEnabled";
  static const String dynamicColorBrightness = "dynamicColorBrightness";
  static const String dynamicAmoledEnabled = "dynamicAmoledEnabled";
  static const String coverArtFit = "coverArtFit";
  static const String additionalMiniPlayerControls = "additionalMiniPlayerControls";
}

updateDirectories() async {
  await antiiqState.store.put(MainBoxKeys.includedPaths, specificPathsToQuery);
}

setMinimumTrackLength(int length) async {
  minimumTrackLength = length;
  await antiiqState.store.put(MainBoxKeys.minimumTrackLength, length);
}

setGeneralRadius(double radius) async {
  generalRadius = radius;
  broadcastTheme();
  await antiiqState.store.put(MainBoxKeys.generalRadius, radius);
}

setPreviousButtonAction(bool restart) async {
  previousRestart = restart;
  await antiiqState.store.put(MainBoxKeys.previousRestart, restart);
}

setStatusBarMode(String mode) async {
  mode == "immersive"
      ? currentStatusBarMode = StatusBarMode.immersiveMode
      : currentStatusBarMode = StatusBarMode.defaultMode;
  updateStatusBarMode();
  await antiiqState.store.put(MainBoxKeys.statusBarMode, mode);
}

updateStatusBarMode() {
  currentStatusBarMode == StatusBarMode.immersiveMode
      ? SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky)
      : SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: SystemUiOverlay.values);
}

updateStatusBarColors() {
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: currentColorScheme.background,
      statusBarIconBrightness: currentColorScheme.brightness == Brightness.dark
          ? Brightness.light
          : Brightness.dark,
    ),
  );
}

//Initializations
initializeUserSettings() async {
  await themeInit();
  await getUserLibraryDirectories();
  await getMinimumTrackLength();
  await getGeneralRadius();
  await getPreviousButtonAction();
  await getSwipeGestures();
  await initInteractiveSeekBarSwitch();
  await initTrackDurationShowSwitch();
  await initQuitType();
  await getStatusBarMode();
  await getCoverArtFit();
  await getadditionalMiniPlayerControls();
}

getUserLibraryDirectories() async {
  specificPathsToQuery = await antiiqState.store
      .get(MainBoxKeys.includedPaths, defaultValue: <String>[]);
}

getMinimumTrackLength() async {
  minimumTrackLength = await antiiqState.store
      .get(MainBoxKeys.minimumTrackLength, defaultValue: 45);
}

getGeneralRadius() async {
  generalRadius = await antiiqState.store
      .get(MainBoxKeys.generalRadius, defaultValue: 10.0);
}

getPreviousButtonAction() async {
  previousRestart = await antiiqState.store
      .get(MainBoxKeys.previousRestart, defaultValue: false);
}

setSwipeGestures(bool enabled) async {
  swipeGestures = enabled;
  await antiiqState.store.put(MainBoxKeys.swipeGestures, enabled);
}

getSwipeGestures() async {
  swipeGestures = await antiiqState.store
      .get(MainBoxKeys.swipeGestures, defaultValue: true);
}

initInteractiveSeekBarSwitch() async {
  interactiveMiniPlayerSeekbar = await antiiqState.store
      .get(MainBoxKeys.interactiveSeekBar, defaultValue: true);
}

interactiveSeekBarSwitch(bool value) async {
  interactiveMiniPlayerSeekbar = value;
  interactiveSeekbarStream.add(value);
  await antiiqState.store.put(MainBoxKeys.interactiveSeekBar, value);
}

initTrackDurationShowSwitch() async {
  showTrackDuration = await antiiqState.store
      .get(MainBoxKeys.showTrackDuration, defaultValue: true);
}

trackDurationShowSwitch(bool value) async {
  showTrackDuration = value;
  trackDurationDisplayStream.add(value);
  await antiiqState.store.put(MainBoxKeys.showTrackDuration, value);
}

setQuitType(String quitTypeString) async {
  quitTypeString == "dialog"
      ? currentQuitType = QuitType.dialog
      : currentQuitType = QuitType.doubleTap;
  await antiiqState.store.put(MainBoxKeys.quitType, quitTypeString);
}

initQuitType() async {
  String quitTypeString =
      await antiiqState.store.get(MainBoxKeys.quitType, defaultValue: "dialog");
  quitTypeString == "dialog"
      ? currentQuitType = QuitType.dialog
      : currentQuitType = QuitType.doubleTap;
}

getStatusBarMode() async {
  String mode = await antiiqState.store
      .get(MainBoxKeys.statusBarMode, defaultValue: "default");
  mode == "immersive"
      ? currentStatusBarMode = StatusBarMode.immersiveMode
      : currentStatusBarMode = StatusBarMode.defaultMode;
  updateStatusBarMode();
}

getColorSchemeFromList(List<int> colorList) {
  AntiiQColorScheme schemeToLoad = AntiiQColorScheme(
    primary: Color(colorList[0]),
    onPrimary: Color(colorList[1]),
    secondary: Color(colorList[2]),
    onSecondary: Color(colorList[3]),
    surface: Color(colorList[4]),
    onSurface: Color(colorList[5]),
    background: Color(colorList[6]),
    onBackground: Color(colorList[7]),
    error: generalErrorColor,
    onError: generalOnErrorColor,
    brightness: colorList[8] == 0 ? Brightness.dark : Brightness.light,
    colorSchemeType: ColorSchemeType.custom,
  );
  customColorScheme = schemeToLoad;
}

getDynamicColorBrightness() async {
  String brightness = await antiiqState.store
      .get(MainBoxKeys.dynamicColorBrightness, defaultValue: "dark");
  if (brightness == "light") {
    dynamicColorBrightness = Brightness.light;
  } else {
    dynamicColorBrightness = Brightness.dark;
  }
}

changeDynamicColorBrightness(String brightness) async {
  if (brightness == "light") {
    dynamicColorBrightness = Brightness.light;
  } else {
    dynamicColorBrightness = Brightness.dark;
  }
  await antiiqState.store.put(MainBoxKeys.dynamicColorBrightness, brightness);
  if (dynamicThemeEnabled) {
    await updateDynamicTheme(dynamicColorBrightness);
    broadcastThemeSettings();
  }
}

getCoverArtFit() async {
  String coverArtFit = await antiiqState.store.get(MainBoxKeys.coverArtFit, defaultValue: "cover");
  if (coverArtFit == "contain") {
    currentCoverArtFit = ArtFit.contain;
  } else {
    currentCoverArtFit = ArtFit.cover;
  }
}

changeCoverArtFit(String coverArtFit) async {
  if (coverArtFit == "contain") {
    currentCoverArtFit = ArtFit.contain;
    coverArtFitStream.add(ArtFit.contain);
  } else {
    currentCoverArtFit = ArtFit.cover;
    coverArtFitStream.add(ArtFit.cover);
  }
  await antiiqState.store.put(MainBoxKeys.coverArtFit, coverArtFit);
}

getadditionalMiniPlayerControls() async {
  additionalMiniPlayerControls = await antiiqState.store.get(MainBoxKeys.coverArtFit, defaultValue: true);
}

changeAdditionalMiniPlayerControls(bool value) async {
  additionalMiniPlayerControls = value;
  additionalMiniPlayerControlsStream.add(value);
  await antiiqState.store.put(MainBoxKeys.additionalMiniPlayerControls, value);
}
