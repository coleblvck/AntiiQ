import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/utilities/file_handling/backup_and_restore.dart';
import 'package:flutter/material.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:antiiq/player/utilities/folder_picker.dart';

class BackupRestore extends StatefulWidget {
  const BackupRestore({
    super.key,
  });

  @override
  State<BackupRestore> createState() => _BackupRestoreState();
}

class _BackupRestoreState extends State<BackupRestore> {
  showBackUpRestoreDirectoryList() async {
    backupRestoreDirectoryList = [];
    final List<Directory>? rootList = await getExternalStorageDirectories();
    if (rootList != null) {
      for (Directory place in rootList) {
        backupRestoreDirectoryList.add(place.path.split("Android")[0]);
      }
      setState(() {});
    }
  }

  clearBackupRestoreDirectoryList() {
    setState(() {
      backupRestoreDirectoryList = [];
    });
  }

  selectBackupRestorePath(String path) async {
    Directory? newPath = await pickFolder(path, context);
    if (newPath != null) {
      backupRestorePath = newPath.path;
      setState(() {});
    }
  }

  String backupRestorePath = "";
  List<String> backupRestoreDirectoryList = [];

  backupOrRestore(bool toBackUp) async {
    showDialog(
      useSafeArea: true,
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: AntiiQTheme.of(context).colorScheme.background,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 5,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Please wait..."),
                  SizedBox(
                    height: 15,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.0),
                    child: CustomInfiniteProgressIndicator(),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (backupRestorePath != "") {
      if (toBackUp) {
        await backup(backupRestorePath);
      } else if (!toBackUp) {
        await restore(backupRestorePath);
      }
    }
    if (mounted) {
      setState(() {
        backupRestorePath = "";
        backupRestoreDirectoryList = [];
      });

      Navigator.of(context).pop();
    } else {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 75,
          backgroundColor: AntiiQTheme.of(context).colorScheme.background,
          elevation: settingsPageAppBarElevation,
          surfaceTintColor: Colors.transparent,
          shadowColor: AntiiQTheme.of(context).colorScheme.onBackground,
          leading: IconButton(
            iconSize: settingsPageAppBarIconButtonSize,
            color: AntiiQTheme.of(context).colorScheme.onBackground,
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(RemixIcon.arrow_left),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: Text(
                "Backup",
                style: AntiiQTheme.of(context)
                    .textStyles
                    .onBackgroundLargeHeader,
              ),
            ),
          ],
        ),
        backgroundColor: AntiiQTheme.of(context).colorScheme.background,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(
                  height: 20,
                ),
                backupRestorePath == ""
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: CustomButton(
                                style: ButtonStyles().style1,
                                function: () {
                                  showBackUpRestoreDirectoryList();
                                },
                                child: const Text(
                                    "Select Directory for Backup/Restore"),
                              ),
                            ),
                            backupRestoreDirectoryList.isNotEmpty
                                ? Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Select Storage",
                                          style: AntiiQTheme.of(context)
                                              .textStyles
                                              .onBackgroundText,
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            clearBackupRestoreDirectoryList();
                                          },
                                          icon: Icon(
                                            RemixIcon.close_circle,
                                            color: AntiiQTheme.of(context)
                                                .colorScheme
                                                .onBackground,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Container(),
                            for (String path in backupRestoreDirectoryList)
                              CustomButton(
                                style: ButtonStyles().style3,
                                function: () {
                                  selectBackupRestorePath(path);
                                },
                                child: Text(path),
                              ),
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: CustomCard(
                          theme: AntiiQTheme.of(context).cardThemes.surface,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(5.0),
                                  child: Text(
                                    "Select Action",
                                    style: AntiiQTheme.of(context)
                                        .textStyles
                                        .onSurfaceText,
                                  ),
                                ),
                                CustomButton(
                                  style: ButtonStyles().style3,
                                  function: () {
                                    backupOrRestore(true);
                                  },
                                  child: const Text("Backup"),
                                ),
                                CustomButton(
                                  style: ButtonStyles().style1,
                                  function: () {
                                    backupOrRestore(false);
                                  },
                                  child: const Text("Restore"),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
