import 'package:flutter/material.dart';

import 'package:antiiq/player/global_variables.dart';

class CustomColorScheme extends ColorScheme {
  static const Color customPrimaryColor = Color.fromARGB(255, 217, 180, 131);
  static const Color customOnPrimaryColor = Color.fromARGB(244, 36, 36, 36);
  static const Color customSecondaryColor = Color.fromARGB(255, 139, 167, 133);
  static const Color customOnSecondaryColor = Color.fromARGB(244, 12, 12, 12);
  static const Color customBackgroundColor = Color.fromARGB(255, 12, 12, 12);
  static const Color customOnBackgroundColor =
      Color.fromARGB(255, 255, 255, 255);
  static const Color customErrorColor = Color.fromARGB(199, 248, 0, 0);
  static const Color customOnErrorColor = Color.fromARGB(57, 0, 0, 0);
  static const Color customSurfaceColor = Color.fromARGB(255, 52, 70, 61);
  static const Color customOnSurfaceColor = Color.fromARGB(255, 255, 255, 255);
  const CustomColorScheme({
    Color primary = customPrimaryColor,
    Color onPrimary = customOnPrimaryColor,
    Color secondary = customSecondaryColor,
    Color onSecondary = customOnSecondaryColor,
    Color background = customBackgroundColor,
    Color onBackground = customOnBackgroundColor,
    Color error = customErrorColor,
    Color onError = customOnErrorColor,
    Color surface = customSurfaceColor,
    Color onSurface = customOnSurfaceColor,
    Brightness brightness = Brightness.dark,
  }) : super(
          primary: primary,
          onPrimary: onPrimary,
          secondary: secondary,
          onSecondary: onSecondary,
          background: background,
          onBackground: onBackground,
          error: error,
          onError: onError,
          surface: surface,
          onSurface: onSurface,
          brightness: brightness,
        );
}

Map<String, ColorScheme> customThemes = {
  "AntiiQ": const CustomColorScheme(),
  "Paragraph": const CustomColorScheme(
    primary: Color.fromARGB(255, 255, 193, 7),
    onPrimary: Color.fromARGB(255, 0, 0, 0),
    secondary: Color.fromARGB(255, 0, 150, 136),
    onSecondary: Color.fromARGB(255, 255, 255, 255),
    background: Color.fromARGB(255, 12, 12, 12),
    onBackground: Color.fromARGB(255, 255, 255, 255),
    surface: Color.fromARGB(255, 31, 77, 70),
    onSurface: Color.fromARGB(255, 230, 230, 230),
  ),
  "Chaos": ColorScheme.fromSeed(
    seedColor: Colors.deepOrange,
    primary: Colors.deepOrange,
    onPrimary: const Color.fromARGB(255, 0, 0, 0),
    secondary: Colors.amber,
    onSecondary: const Color.fromARGB(255, 0, 0, 0),
    background: const Color.fromARGB(255, 12, 12, 12),
    onBackground: const Color.fromARGB(255, 255, 255, 255),
    surface: const Color.fromARGB(255, 66, 43, 0),
    onSurface: const Color.fromARGB(255, 247, 223, 223),
    brightness: Brightness.dark,
  ),
  "Candy": ColorScheme.fromSeed(
    seedColor: Colors.yellow,
    primary: Colors.yellow,
    onPrimary: const Color.fromARGB(255, 0, 0, 0),
    secondary: Colors.green,
    onSecondary: const Color.fromARGB(255, 0, 0, 0),
    background: const Color.fromARGB(255, 0, 0, 0),
    onBackground: const Color.fromARGB(255, 255, 255, 255),
    surface: const Color.fromARGB(255, 42, 51, 30),
    onSurface: const Color.fromARGB(255, 253, 255, 223),
    brightness: Brightness.dark,
  ),
  "Ambush": const CustomColorScheme(
    primary: Color.fromARGB(255, 228, 141, 44),
    onPrimary: Color.fromARGB(255, 0, 0, 0),
    secondary: Color.fromARGB(255, 129, 184, 142),
    onSecondary: Color.fromARGB(255, 0, 0, 0),
    background: Color.fromARGB(255, 0, 0, 0),
    onBackground: Color.fromARGB(255, 255, 255, 255),
    surface: Color.fromARGB(255, 35, 43, 34),
    onSurface: Color.fromARGB(255, 230, 230, 230),
  ),
  "Just Brown": ColorScheme.fromSwatch(
    primarySwatch: Colors.brown,
    accentColor: const Color.fromARGB(255, 185, 166, 114),
    backgroundColor: Colors.black,
    cardColor: const Color.fromARGB(221, 37, 26, 5),
    brightness: Brightness.dark,
  ),
};

ColorScheme currentColorScheme = getColorScheme();

ColorScheme getColorScheme() {
  return customThemes[currentTheme]!;
}

var backgroundClipArts = {
  "ambush": "assets/bg_cliparts/default.png",
  "olive": "assets/bg_cliparts/default.png",
  "candy": "assets/bg_cliparts/default.png",
  "chaos": "assets/bg_cliparts/default.png",
  "paragraph": "assets/bg_cliparts/default.png",
};
