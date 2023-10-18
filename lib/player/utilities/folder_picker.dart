import 'package:easy_folder_picker/FolderPicker.dart';
import 'dart:io';

import 'package:flutter/material.dart';

Future<Directory?> pickFolder(String path, context) async {
  Directory? newPath = await FolderPicker.pick(
    backgroundColor: Theme.of(context).colorScheme.background,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    context: context,
    rootDirectory: Directory(path),
  );
  return newPath;
}
