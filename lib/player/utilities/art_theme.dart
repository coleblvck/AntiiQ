import 'dart:io';

import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/ui/elements/ui_colours.dart';
import 'package:flutter/material.dart';

Future<AntiiQColorScheme> getArtTheme(Uri artUri) async {
  ColorScheme dynamicColors = await ColorScheme.fromImageProvider(
    provider: FileImage(File(artUri.toFilePath())),
    brightness: Brightness.dark,
  );

  return AntiiQColorScheme(
    primary: dynamicColors.primary,
    onPrimary: dynamicColors.onPrimary,
    secondary: dynamicColors.tertiary,
    onSecondary: dynamicColors.onTertiary,
    surface: dynamicColors.secondaryContainer,
    onSurface: dynamicColors.onSecondaryContainer,
    background: Colors.black /*: dynamicColors.surface*/,
    onBackground: dynamicColors.onSurface,
    error: generalErrorColor,
    onError: generalOnErrorColor,
    brightness: Brightness.dark,
    colorSchemeType: ColorSchemeType.dynamic,
  );
}
