import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/utilities/user_settings.dart';
import 'package:flutter/material.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'dart:io';
import 'package:easy_folder_picker/FolderPicker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:restart_app/restart_app.dart';

class Library extends StatefulWidget {
  const Library({
    super.key,
  });

  @override
  State<Library> createState() => _LibraryState();
}

class _LibraryState extends State<Library> {
  stateSet() {
    setState(() {});
  }

  List<String> directoryList = [];

  clearDirectoryList() {
    setState(() {
      directoryList = [];
    });
  }

  selectRootDirectory() async {
    directoryList = [];
    final List<Directory>? rootList = await getExternalStorageDirectories();
    if (rootList != null) {
      for (Directory place in rootList) {
        directoryList.add(place.path.split("Android")[0]);
      }
      setState(() {});
    }
  }

  directoryAdd(String path) async {
    if (furtherPermissionGranted) {
      Directory? newPath = await FolderPicker.pick(
        context: context,
        rootDirectory: Directory(path),
      );
      if (newPath != null) {
        specificPathsToQuery.add(newPath.path);
        await updateDirectories();
        setState(() {});
      }
    }
  }

  directoryRemove(index) async {
    specificPathsToQuery.removeAt(index);
    await updateDirectories();
    setState(() {});
  }

  rescan() async {
    dataIsInitialized = false;
    await antiiqStore.put("dataInit", false);
    Restart.restartApp();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 75,
          backgroundColor: Theme.of(context).colorScheme.background,
          elevation: 2,
          surfaceTintColor: Colors.transparent,
          shadowColor: Theme.of(context).colorScheme.onBackground,
          leading: IconButton(
            iconSize: 50,
            color: Theme.of(context).colorScheme.onBackground,
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(RemixIcon.arrow_left),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: Icon(
                RemixIcon.folder,
                color: Theme.of(context).colorScheme.onBackground,
                size: 30,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.background,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  "Directories",
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontSize: 30),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: CustomCard(
                  theme: CardThemes().settingsItemTheme.copyWith(
                        surfaceTintColor: Colors.transparent,
                        elevation: 0,
                      ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomButton(
                        style: ButtonStyles().style2,
                        function: () {
                          rescan();
                        },
                        child: const Text("!Re-Scan Library!"),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Note: Adding directories here, excludes all other directories from being scanned.",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onBackground,
                          ),
                        ),
                      ),
                      CustomButton(
                        style: ButtonStyles().style3,
                        function: () {
                          selectRootDirectory();
                        },
                        child: const Text("Add Directory from Storage"),
                      ),
                      directoryList.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Select Storage"),
                                  IconButton(
                                    onPressed: () {
                                      clearDirectoryList();
                                    },
                                    icon: const Icon(
                                      RemixIcon.close_circle,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Container(),
                      for (String path in directoryList)
                        CustomButton(
                          style: ButtonStyles().style3,
                          function: () {
                            directoryAdd(path);
                          },
                          child: Text(path),
                        ),
                      specificPathsToQuery.isNotEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(10.0),
                              child: Text("Paths"),
                            )
                          : Container(),
                      for (String directory in specificPathsToQuery)
                        CustomCard(
                          theme: CardThemes().settingsItemTheme.copyWith(
                                color: Theme.of(context).colorScheme.surface,
                              ),
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: TextScroll(
                                        directory,
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                CustomButton(
                                  style: ButtonStyles().style1,
                                  function: () {
                                    directoryRemove(specificPathsToQuery
                                        .indexOf(directory));
                                  },
                                  child: const Text("Remove Directory"),
                                )
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
