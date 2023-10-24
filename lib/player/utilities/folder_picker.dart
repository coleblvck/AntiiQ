import 'dart:io';

import 'package:antiiq/player/global_variables.dart';
import 'package:flutter/material.dart';
import 'package:filesystem_picker/filesystem_picker.dart';

Future<Directory?> pickFolder(String path, context) async {

  String? newPath = await FilesystemPicker.openBottomSheet(
    context: context,
    shape: bottomSheetShape,
    rootDirectory: Directory(path),
    fsType: FilesystemType.folder,
    barrierColor: Colors.transparent,
    constraints: const BoxConstraints(),
    theme: FilesystemPickerTheme(
      topBar: FilesystemPickerTopBarThemeData(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      )
    ),
    pickText: "Select Folder",
    folderIconColor: Theme.of(context).colorScheme.secondary,
  );
  Directory? directoryToReturn;
  if (newPath != null) {
    directoryToReturn = Directory(newPath);
  }
  return directoryToReturn;
}
