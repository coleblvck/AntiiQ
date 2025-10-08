import 'dart:io';
import 'package:antiiq/chaos/chaos_ui_state.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

Future<Directory?> pickChaosFolder(String path, BuildContext context) async {
  final chaosUIState = context.read<ChaosUIState>();
  //final radius = chaosUIState.chaosRadius;
  final innerRadius = chaosUIState.getAdjustedRadius(2);

  String? newPath = await FilesystemPicker.openDialog(
    context: context,
    rootDirectory: Directory(path),
    fsType: FilesystemType.folder,
    pickText: "SELECT",
    title: "CHAOS FOLDER SELECTOR",
    constraints: BoxConstraints(
      maxWidth: MediaQuery.of(context).size.width * 0.9,
      maxHeight: MediaQuery.of(context).size.height * 0.8,
    ),
    theme: FilesystemPickerTheme(
      topBar: FilesystemPickerTopBarThemeData(
        backgroundColor: AntiiQTheme.of(context).colorScheme.background,
        foregroundColor: AntiiQTheme.of(context).colorScheme.primary,
        shadowColor: Colors.transparent,
        elevation: 0,
        shape: Border(
          bottom: BorderSide(
            color: AntiiQTheme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        titleTextStyle: TextStyle(
          color: AntiiQTheme.of(context).colorScheme.primary,
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: 3,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: AntiiQTheme.of(context).colorScheme.background,
          statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
        ),
        breadcrumbsTheme: BreadcrumbsThemeData(
          textStyle: TextStyle(
            color: AntiiQTheme.of(context).colorScheme.onBackground.withValues(alpha: 0.7),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
          separatorColor: AntiiQTheme.of(context).colorScheme.primary.withValues(alpha: 0.4),
        ),
      ),
      backgroundColor: AntiiQTheme.of(context).colorScheme.background,
      fileList: FilesystemPickerFileListThemeData(
        fileTextStyle: AntiiQTheme.of(context).textStyles.onBackgroundText.copyWith(
          letterSpacing: 0.8,
        ),
        folderTextStyle: AntiiQTheme.of(context).textStyles.onBackgroundText.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
        upIconColor: AntiiQTheme.of(context).colorScheme.secondary,
      ),
      pickerAction: FilesystemPickerActionThemeData(
        backgroundColor: AntiiQTheme.of(context).colorScheme.secondary,
        foregroundColor: AntiiQTheme.of(context).colorScheme.onSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(innerRadius),
          side: BorderSide(
            color: AntiiQTheme.of(context).colorScheme.secondary,
            width: 2,
          ),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    ),
    folderIconColor: AntiiQTheme.of(context).colorScheme.primary,
  );

  if (newPath != null) {
    HapticFeedback.mediumImpact();
    return Directory(newPath);
  }
  
  return null;
}