import 'dart:typed_data';

import 'package:access_wallpaper/access_wallpaper.dart';
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/ui/elements/ui_colours.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:antiiq/player/utilities/settings/user_settings.dart';

final AccessWallpaper accessWallpaper = AccessWallpaper();

themeInit() async {
  String schemeType = await antiiqState.store
      .get(MainBoxKeys.colorSchemeType, defaultValue: "antiiq");
  currentTheme = await antiiqState.store
      .get(MainBoxKeys.userTheme, defaultValue: "AntiiQ");
  List<int> customColorList = await antiiqState.store
      .get(MainBoxKeys.customColorList, defaultValue: <int>[]);
  if (customColorList.isNotEmpty) {
    getColorSchemeFromList(customColorList);
  }

  dynamicAmoledEnabled = await antiiqState.store
      .get(MainBoxKeys.dynamicAmoledEnabled, defaultValue: false);

  await getDynamicColorBrightness();

  await updateDynamicTheme(dynamicColorBrightness);

  dynamicThemeEnabled = await antiiqState.store
      .get(MainBoxKeys.dynamicThemeEnabled, defaultValue: false);

  if (schemeType == "antiiq") {
    currentColorSchemeType = ColorSchemeType.antiiq;
  } else if (schemeType == "custom") {
    currentColorSchemeType = ColorSchemeType.custom;
  }
  broadcastThemeSettings();
}

changeTheme(String theme) async {
  if (dynamicThemeEnabled) {
    await setDynamicTheme(false);
  }
  currentTheme = theme;
  currentColorSchemeType = ColorSchemeType.antiiq;
  await antiiqState.store.put(MainBoxKeys.userTheme, theme);
  await antiiqState.store.put(MainBoxKeys.colorSchemeType, "antiiq");
  broadcastThemeSettings();
}

setCustomTheme(AntiiQColorScheme themeToSet) async {
  if (dynamicThemeEnabled) {
    await setDynamicTheme(false);
  }
  customColorScheme = themeToSet;
  currentColorSchemeType = ColorSchemeType.custom;
  broadcastThemeSettings();
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
  await antiiqState.store.put(MainBoxKeys.customColorList, colorIntegers);
  await antiiqState.store.put(MainBoxKeys.colorSchemeType, "custom");
}

switchDynamicTheme(bool value) async {
  await setDynamicTheme(value);
  broadcastThemeSettings();
}

setDynamicTheme(bool value) async {
  dynamicThemeEnabled = value;
  await antiiqState.store.put(MainBoxKeys.dynamicThemeEnabled, value);
  if (value) {
    await updateDynamicTheme(dynamicColorBrightness);
  }
}

bool dynamicAmoledEnabled = false;

switchDynamicAmoled(bool value) async {
  dynamicAmoledEnabled = value;
  await antiiqState.store.put(MainBoxKeys.dynamicAmoledEnabled, value);
  if (dynamicThemeEnabled && dynamicColorBrightness == Brightness.dark) {
    await updateDynamicTheme(dynamicColorBrightness);
    broadcastThemeSettings();
  }
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
            background: dynamicAmoledEnabled? Colors.black: dynamicColors.surface,
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
  } else {
    Uint8List? wallpaperBytes =
        await accessWallpaper.getWallpaper(AccessWallpaper.homeScreenFlag);
    if (wallpaperBytes != null) {
      ColorScheme dynamicColors = await ColorScheme.fromImageProvider(
        provider: MemoryImage(wallpaperBytes),
        brightness: brightness,
      );
      brightness == Brightness.dark
          ? dynamicColorScheme = AntiiQColorScheme(
              primary: dynamicColors.primary,
              onPrimary: dynamicColors.onPrimary,
              secondary: dynamicColors.tertiary,
              onSecondary: dynamicColors.onTertiary,
              surface: dynamicColors.secondaryContainer,
              onSurface: dynamicColors.onSecondaryContainer,
              background: dynamicAmoledEnabled? Colors.black: dynamicColors.surface,
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
}

broadcastThemeSettings() {
  broadcastTheme();
  updateStatusBarColors();
}

broadcastTheme() {
  themeStream.add(getColorScheme());
  currentColorScheme = getColorScheme();
}
