import 'package:flutter/material.dart';

import 'package:antiiq/player/global_variables.dart';

class AntiiQColorScheme {
  const AntiiQColorScheme({
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.background,
    required this.onBackground,
    required this.error,
    required this.onError,
    required this.surface,
    required this.onSurface,
    required this.brightness,
    required this.colorSchemeType,
  });
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color onSecondary;
  final Color background;
  final Color onBackground;
  final Color error;
  final Color onError;
  final Color surface;
  final Color onSurface;
  final Brightness brightness;
  final ColorSchemeType colorSchemeType;
}

Map<String, AntiiQColorScheme> customThemes = {
  "AntiiQ": const AntiiQColorScheme(
    primary: Color.fromARGB(255, 217, 180, 131),
    onPrimary: Color.fromARGB(244, 36, 36, 36),
    secondary: Color.fromARGB(255, 139, 167, 133),
    onSecondary: Color.fromARGB(244, 12, 12, 12),
    background: Color.fromARGB(255, 12, 12, 12),
    onBackground: Color.fromARGB(255, 255, 255, 255),
    surface: Color.fromARGB(255, 52, 70, 61),
    onSurface: Color.fromARGB(255, 255, 255, 255),
    error: Color.fromARGB(199, 248, 0, 0),
    onError: Color.fromARGB(57, 0, 0, 0),
    brightness: Brightness.dark,
    colorSchemeType: ColorSchemeType.antiiq,
  ),
  "Paragraph": const AntiiQColorScheme(
    primary: Color.fromARGB(255, 255, 193, 7),
    onPrimary: Color.fromARGB(255, 0, 0, 0),
    secondary: Color.fromARGB(255, 0, 150, 136),
    onSecondary: Color.fromARGB(255, 255, 255, 255),
    background: Color.fromARGB(255, 12, 12, 12),
    onBackground: Color.fromARGB(255, 255, 255, 255),
    surface: Color.fromARGB(255, 31, 77, 70),
    onSurface: Color.fromARGB(255, 230, 230, 230),
    error: Color.fromARGB(199, 248, 0, 0),
    onError: Color.fromARGB(57, 0, 0, 0),
    brightness: Brightness.dark,
    colorSchemeType: ColorSchemeType.antiiq,
  ),
  "Chaos": const AntiiQColorScheme(
    primary: Colors.deepOrange,
    onPrimary: Color.fromARGB(255, 0, 0, 0),
    secondary: Colors.amber,
    onSecondary: Color.fromARGB(255, 0, 0, 0),
    background: Color.fromARGB(255, 12, 12, 12),
    onBackground: Color.fromARGB(255, 255, 255, 255),
    surface: Color.fromARGB(255, 66, 43, 0),
    onSurface: Color.fromARGB(255, 247, 223, 223),
    error: Color.fromARGB(199, 248, 0, 0),
    onError: Color.fromARGB(57, 0, 0, 0),
    brightness: Brightness.dark,
    colorSchemeType: ColorSchemeType.antiiq,
  ),
  "Candy": const AntiiQColorScheme(
    primary: Colors.yellow,
    onPrimary: Color.fromARGB(255, 0, 0, 0),
    secondary: Colors.green,
    onSecondary: Color.fromARGB(255, 0, 0, 0),
    background: Color.fromARGB(255, 0, 0, 0),
    onBackground: Color.fromARGB(255, 255, 255, 255),
    surface: Color.fromARGB(255, 42, 51, 30),
    onSurface: Color.fromARGB(255, 253, 255, 223),
    error: Color.fromARGB(199, 248, 0, 0),
    onError: Color.fromARGB(57, 0, 0, 0),
    brightness: Brightness.dark,
    colorSchemeType: ColorSchemeType.antiiq,
  ),
  "Ambush": const AntiiQColorScheme(
    primary: Color.fromARGB(255, 228, 141, 44),
    onPrimary: Color.fromARGB(255, 0, 0, 0),
    secondary: Color.fromARGB(255, 129, 184, 142),
    onSecondary: Color.fromARGB(255, 0, 0, 0),
    background: Color.fromARGB(255, 0, 0, 0),
    onBackground: Color.fromARGB(255, 255, 255, 255),
    surface: Color.fromARGB(255, 35, 43, 34),
    onSurface: Color.fromARGB(255, 230, 230, 230),
    error: Color.fromARGB(199, 248, 0, 0),
    onError: Color.fromARGB(57, 0, 0, 0),
    brightness: Brightness.dark,
    colorSchemeType: ColorSchemeType.antiiq,
  ),
  "Just Brown": const AntiiQColorScheme(
    primary: Colors.brown,
    onPrimary: Color.fromARGB(255, 255, 255, 255),
    secondary: Color.fromARGB(255, 185, 166, 114),
    onSecondary: Color.fromARGB(255, 255, 255, 255),
    background: Color.fromARGB(255, 0, 0, 0),
    onBackground: Color.fromARGB(255, 255, 255, 255),
    surface: Color.fromARGB(255, 38, 27, 5),
    onSurface: Color.fromARGB(255, 230, 230, 230),
    error: Color.fromARGB(199, 248, 0, 0),
    onError: Color.fromARGB(57, 0, 0, 0),
    brightness: Brightness.dark,
    colorSchemeType: ColorSchemeType.antiiq,
  ),
  "Greenish Brown": const AntiiQColorScheme(
    primary: Colors.brown,
    onPrimary: Color.fromARGB(255, 255, 255, 255),
    secondary: Color.fromARGB(255, 185, 166, 114),
    onSecondary: Color.fromARGB(255, 255, 255, 255),
    background: Color.fromARGB(255, 0, 0, 0),
    onBackground: Color.fromARGB(255, 255, 255, 255),
    surface: Color.fromARGB(255, 35, 43, 34),
    onSurface: Color.fromARGB(255, 230, 230, 230),
    error: Color.fromARGB(199, 248, 0, 0),
    onError: Color.fromARGB(57, 0, 0, 0),
    brightness: Brightness.dark,
    colorSchemeType: ColorSchemeType.antiiq,
  ),
  "Milky Grey": const AntiiQColorScheme(
    primary: Color.fromARGB(255, 230, 223, 170),
    onPrimary: Color.fromARGB(255, 0, 0, 0),
    secondary: Color.fromARGB(255, 174, 165, 125),
    onSecondary: Color.fromARGB(255, 0, 0, 0),
    background: Color.fromARGB(255, 28, 30, 29),
    onBackground: Color.fromARGB(255, 255, 255, 255),
    surface: Color.fromARGB(255, 72, 73, 71),
    onSurface: Color.fromARGB(255, 255, 255, 255),
    error: Color.fromARGB(199, 248, 0, 0),
    onError: Color.fromARGB(57, 0, 0, 0),
    brightness: Brightness.dark,
    colorSchemeType: ColorSchemeType.antiiq,
  ),
  "Abstract": const AntiiQColorScheme(
    primary: Color.fromARGB(255, 241, 229, 185),
    onPrimary: Color.fromARGB(255, 0, 0, 0),
    secondary: Color.fromARGB(255, 167, 190, 153),
    onSecondary: Color.fromARGB(255, 0, 0, 0),
    background: Color.fromARGB(255, 56, 63, 62),
    onBackground: Color.fromARGB(255, 255, 255, 255),
    surface: Color.fromARGB(255, 47, 40, 49),
    onSurface: Color.fromARGB(255, 255, 255, 255),
    error: Color.fromARGB(199, 248, 0, 0),
    onError: Color.fromARGB(57, 0, 0, 0),
    brightness: Brightness.dark,
    colorSchemeType: ColorSchemeType.antiiq,
  ),
  "Olive": const AntiiQColorScheme(
    primary: Color.fromARGB(255, 230, 223, 170),
    onPrimary: Color.fromARGB(255, 0, 0, 0),
    secondary: Color.fromARGB(255, 167, 190, 153),
    onSecondary: Color.fromARGB(255, 0, 0, 0),
    background: Color.fromARGB(255, 55, 66, 57),
    onBackground: Color.fromARGB(255, 255, 255, 255),
    surface: Color.fromARGB(255, 64, 87, 74),
    onSurface: Color.fromARGB(255, 255, 255, 255),
    error: Color.fromARGB(199, 248, 0, 0),
    onError: Color.fromARGB(57, 0, 0, 0),
    brightness: Brightness.dark,
    colorSchemeType: ColorSchemeType.antiiq,
  ),
  "Olive Black": const AntiiQColorScheme(
    primary: Color.fromARGB(255, 230, 223, 170),
    onPrimary: Color.fromARGB(255, 0, 0, 0),
    secondary: Color.fromARGB(255, 167, 190, 153),
    onSecondary: Color.fromARGB(255, 0, 0, 0),
    background: Color.fromARGB(255, 0, 0, 0),
    onBackground: Color.fromARGB(255, 255, 255, 255),
    surface: Color.fromARGB(255, 64, 87, 74),
    onSurface: Color.fromARGB(255, 255, 255, 255),
    error: Color.fromARGB(199, 248, 0, 0),
    onError: Color.fromARGB(57, 0, 0, 0),
    brightness: Brightness.dark,
    colorSchemeType: ColorSchemeType.antiiq,
  ),
  "Olive Blacker": const AntiiQColorScheme(
    primary: Color.fromARGB(255, 230, 223, 170),
    onPrimary: Color.fromARGB(255, 0, 0, 0),
    secondary: Color.fromARGB(255, 167, 190, 153),
    onSecondary: Color.fromARGB(255, 0, 0, 0),
    background: Color.fromARGB(255, 0, 0, 0),
    onBackground: Color.fromARGB(255, 255, 255, 255),
    surface: Color.fromARGB(255, 0, 0, 0),
    onSurface: Color.fromARGB(255, 255, 255, 255),
    error: Color.fromARGB(199, 248, 0, 0),
    onError: Color.fromARGB(57, 0, 0, 0),
    brightness: Brightness.dark,
    colorSchemeType: ColorSchemeType.antiiq,
  ),
};

AntiiQColorScheme currentColorScheme = getColorScheme();

AntiiQColorScheme getColorScheme() {
  return currentColorSchemeType == ColorSchemeType.antiiq
      ? customThemes[currentTheme]!
      : customColorScheme!;
}

var backgroundClipArts = {
  "ambush": "assets/bg_cliparts/default.png",
  "olive": "assets/bg_cliparts/default.png",
  "candy": "assets/bg_cliparts/default.png",
  "chaos": "assets/bg_cliparts/default.png",
  "paragraph": "assets/bg_cliparts/default.png",
};

AntiiQColorScheme? customColorScheme;
