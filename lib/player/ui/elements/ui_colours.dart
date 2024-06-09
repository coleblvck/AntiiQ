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
  ),
};

AntiiQColorScheme currentColorScheme = getColorScheme();

AntiiQColorScheme getColorScheme() {
  return customThemes[currentTheme]!;
}

var backgroundClipArts = {
  "ambush": "assets/bg_cliparts/default.png",
  "olive": "assets/bg_cliparts/default.png",
  "candy": "assets/bg_cliparts/default.png",
  "chaos": "assets/bg_cliparts/default.png",
  "paragraph": "assets/bg_cliparts/default.png",
};
