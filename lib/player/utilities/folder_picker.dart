import 'dart:io';

import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
        backgroundColor: AntiiQTheme.of(context).colorScheme.surface,
        foregroundColor: AntiiQTheme.of(context).colorScheme.onSurface,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: AntiiQTheme.of(context).colorScheme.background,
        )
      ),
      backgroundColor: AntiiQTheme.of(context).colorScheme.background,
      fileList: FilesystemPickerFileListThemeData(
        fileTextStyle: AntiiQTheme.of(context).textStyles.onBackgroundText,
        folderTextStyle: AntiiQTheme.of(context).textStyles.onBackgroundText,
      ),
      pickerAction: FilesystemPickerActionThemeData(
        backgroundColor: AntiiQTheme.of(context).colorScheme.primary,
        checkIconColor: AntiiQTheme.of(context).colorScheme.onPrimary,
      ),
    ),
    pickText: "Select Folder",
    folderIconColor: AntiiQTheme.of(context).colorScheme.secondary,
  );
  Directory? directoryToReturn;
  if (newPath != null) {
    directoryToReturn = Directory(newPath);
  }
  return directoryToReturn;
}
