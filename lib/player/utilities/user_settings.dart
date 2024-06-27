import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/ui/elements/ui_colours.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/audio_preferences.dart';
import 'package:antiiq/player/utilities/platform.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  String favourites = "favourites";
  String showTrackDuration = "showTrackDuration";
  String generalRadius = "generalRadius";
  String quitType = "quitType";
  String statusBarMode = "statusBarMode";
  String colorSchemeType = "colorSchemeType";
  String customColorList = "customColorScheme";
  String dynamicThemeEnabled = "dynamicThemeEnabled";
  String dynamicColorBrightness = "dynamicColorBrightness";
}

changeTheme(String theme) async {
  if (dynamicThemeEnabled) {
    dynamicThemeEnabled = false;
  }
  currentTheme = theme;
  currentColorSchemeType = ColorSchemeType.antiiq;
  await antiiqStore.put(BoxKeys().userTheme, theme);
  await antiiqStore.put(BoxKeys().colorSchemeType, "antiiq");
  updateThemeStream();
}

setCustomTheme(AntiiQColorScheme themeToSet) async {
  if (dynamicThemeEnabled) {
    dynamicThemeEnabled = false;
  }
  customColorScheme = themeToSet;
  currentColorSchemeType = ColorSchemeType.custom;
  updateThemeStream();
  int brightnessInt = themeToSet.brightness == Brightness.dark ? 0 : 1;
  List<int> colorIntegers = [
    themeToSet.primary.value,
    themeToSet.onPrimary.value,
    themeToSet.secondary.value,
    themeToSet.onSecondary.value,
    themeToSet.surface.value,
    themeToSet.onSurface.value,
    themeToSet.background.value,
    themeToSet.onBackground.value,
    brightnessInt,
  ];
  await antiiqStore.put(BoxKeys().customColorList, colorIntegers);
  await antiiqStore.put(BoxKeys().colorSchemeType, "custom");
}

switchDynamicTheme(bool value) async {
  dynamicThemeEnabled = value;
  await antiiqStore.put(BoxKeys().dynamicThemeEnabled, value);
  if (value) {
    await updateDynamicTheme(dynamicColorBrightness);
  }
  updateThemeStream();
}

updateDirectories() async {
  await antiiqStore.put(BoxKeys().includedPaths, specificPathsToQuery);
}

setMinimumTrackLength(int length) async {
  minimumTrackLength = length;
  await antiiqStore.put(BoxKeys().minimumTrackLength, length);
}

setGeneralRadius(double radius) async {
  generalRadius = radius;
  await antiiqStore.put(BoxKeys().generalRadius, radius);
}

setPreviousButtonAction(bool restart) async {
  previousRestart = restart;
  await antiiqStore.put(BoxKeys().previousRestart, restart);
}

setStatusBarMode(String mode) async {
  mode == "immersive"
      ? currentStatusBarMode = StatusBarMode.immersiveMode
      : currentStatusBarMode = StatusBarMode.defaultMode;
  updateStatusBarMode();
  await antiiqStore.put(BoxKeys().statusBarMode, mode);
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
}

initializeAudioPreferences() async {
  await getEqualizerEnabled();
  await getBandFreqs();
  await getAndSetLoopMode();
  await getAndSetShuffleMode();
}

themeInit() async {
  String schemeType =
      await antiiqStore.get(BoxKeys().colorSchemeType, defaultValue: "antiiq");
  currentTheme =
      await antiiqStore.get(BoxKeys().userTheme, defaultValue: "AntiiQ");
  List<int> customColorList =
      await antiiqStore.get(BoxKeys().customColorList, defaultValue: <int>[]);
  if (customColorList.isNotEmpty) {
    getColorSchemeFromList(customColorList);
  }

  await getDynamicColorBrightness();

  if (droidVersion >= 12) {
    await updateDynamicTheme(dynamicColorBrightness);
  }

  dynamicThemeEnabled =
      await antiiqStore.get(BoxKeys().dynamicThemeEnabled, defaultValue: false);

  if (droidVersion < 12) {
    dynamicThemeEnabled = false;
  }
  if (schemeType == "antiiq") {
    currentColorSchemeType = ColorSchemeType.antiiq;
  } else if (schemeType == "custom") {
    currentColorSchemeType = ColorSchemeType.custom;
  }
  updateThemeStream();
}

getUserLibraryDirectories() async {
  specificPathsToQuery =
      await antiiqStore.get(BoxKeys().includedPaths, defaultValue: <String>[]);
}

getMinimumTrackLength() async {
  minimumTrackLength =
      await antiiqStore.get(BoxKeys().minimumTrackLength, defaultValue: 45);
}

getGeneralRadius() async {
  generalRadius =
      await antiiqStore.get(BoxKeys().generalRadius, defaultValue: 10.0);
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

initInteractiveSeekBarSwitch() async {
  interactiveMiniPlayerSeekbar =
      await antiiqStore.get(BoxKeys().interactiveSeekBar, defaultValue: true);
}

interactiveSeekBarSwitch(bool value) async {
  interactiveMiniPlayerSeekbar = value;
  interactiveSeekbarStream.add(value);
  await antiiqStore.put(BoxKeys().interactiveSeekBar, value);
}

initTrackDurationShowSwitch() async {
  showTrackDuration =
      await antiiqStore.get(BoxKeys().showTrackDuration, defaultValue: true);
}

trackDurationShowSwitch(bool value) async {
  showTrackDuration = value;
  trackDurationDisplayStream.add(value);
  await antiiqStore.put(BoxKeys().showTrackDuration, value);
}

setQuitType(String quitTypeString) async {
  quitTypeString == "dialog"
      ? currentQuitType = QuitType.dialog
      : currentQuitType = QuitType.doubleTap;
  await antiiqStore.put(BoxKeys().quitType, quitTypeString);
}

initQuitType() async {
  String quitTypeString =
      await antiiqStore.get(BoxKeys().quitType, defaultValue: "dialog");
  quitTypeString == "dialog"
      ? currentQuitType = QuitType.dialog
      : currentQuitType = QuitType.doubleTap;
}

getStatusBarMode() async {
  String mode =
      await antiiqStore.get(BoxKeys().statusBarMode, defaultValue: "default");
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

updateDynamicTheme(Brightness brightness) async {
  final corePalette = await DynamicColorPlugin.getCorePalette();
  if (corePalette != null) {
    ColorScheme dynamicColors =
        corePalette.toColorScheme(brightness: brightness);
    brightness == Brightness.dark
        ? dynamicColorScheme = AntiiQColorScheme(
            primary: dynamicColors.primary,
            onPrimary: dynamicColors.onPrimary,
            secondary: dynamicColors.tertiary,
            onSecondary: dynamicColors.onTertiary,
            surface: dynamicColors.secondaryContainer,
            onSurface: dynamicColors.onSecondaryContainer,
            background: dynamicColors.surface,
            onBackground: dynamicColors.onSurface,
            error: generalErrorColor,
            onError: generalOnErrorColor,
            brightness: brightness,
            colorSchemeType: ColorSchemeType.dynamic,
          )
        : dynamicColorScheme = AntiiQColorScheme(
            primary: dynamicColors.primary,
            onPrimary: dynamicColors.onPrimary,
            secondary: dynamicColors.tertiary,
            onSecondary: dynamicColors.onTertiary,
            surface: dynamicColors.surface,
            onSurface: dynamicColors.onSurface,
            background: dynamicColors.secondaryContainer,
            onBackground: dynamicColors.onSecondaryContainer,
            error: generalErrorColor,
            onError: generalOnErrorColor,
            brightness: brightness,
            colorSchemeType: ColorSchemeType.dynamic,
          );
  }
}

updateThemeStream() {
  themeStream.add(getColorScheme());
  currentColorScheme = getColorScheme();
  updateStatusBarColors();
}

getDynamicColorBrightness() async {
  String brightness = await antiiqStore.get(BoxKeys().dynamicColorBrightness,
      defaultValue: "dark");
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
  await antiiqStore.put(BoxKeys().dynamicColorBrightness, brightness);
  if (dynamicThemeEnabled) {
    await updateDynamicTheme(dynamicColorBrightness);
    updateThemeStream();
  }
}
