import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_sliding_box/flutter_sliding_box.dart';

import 'package:remix_icon_icons/remix_icon_icons.dart';

import 'package:antiiq/player/screens/main_screen/main_backdrop.dart';
import 'package:antiiq/player/widgets/mini_player.dart';
import 'package:antiiq/player/screens/now_playing/now_playing.dart';
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/utilities/initialize.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/screens/queue/queue.dart';
import 'package:antiiq/player/screens/settings/settings.dart';

class MainBox extends StatefulWidget {
  const MainBox({
    super.key,
  });
  @override
  State<MainBox> createState() => _MainBoxState();
}

class _MainBoxState extends State<MainBox> {
  final BoxController boxController = BoxController();
  final TextEditingController textEditingController = TextEditingController();

  late Timer libraryLoadTimer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) {
        if (hasPermissions) {
          initData();
        }
      },
    );
  }

  Future<bool?> showPopDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text('Exit?'),
          content: const Text(
            'Are you sure',
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Stay'),
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Exit'),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
          ],
        );
      },
    );
  }

  initData() async {
    showDialog(
      useSafeArea: true,
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          int loadProgress = libraryLoadProgress;
          int loadTotal = libraryLoadTotal;
          String message = loadingMessage;
          libraryLoadTimer =
              Timer.periodic(const Duration(seconds: 1), (timer) {
            if (context.mounted) {
              setState(() {});
            }
          });
          return PopScope(
            canPop: false,
            child: Dialog(
              backgroundColor: Theme.of(context).colorScheme.background,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(message),
                    const SizedBox(
                      height: 15,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: CustomProgressIndicator(
                        progress: loadProgress / loadTotal,
                      ),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    Text("Processing Files $loadProgress of $loadTotal"),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
    await loadLibrary();

    libraryLoadTimer.cancel();

    if (mounted) {
      stateSet();
      libraryLoadTotal = 1;
      libraryLoadProgress = 0;
      loadingMessage = "Loading Library";
      Navigator.of(context).pop();
    } else {
      return;
    }
  }

  stateSet() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Theme.of(context).colorScheme.background,
      ),
    );
    //
    double bottomNavigationBarHeight = 50;
    double appBarHeight = 50;
    double minHeightBox = 45 + bottomNavigationBarHeight;
    double maxHeightBox = MediaQuery.of(context).size.height -
        appBarHeight -
        35 -
        bottomNavigationBarHeight;

    //
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) {
          return;
        }
        if (boxController.isBoxClosed) {
          if (mainPageController.page != 0) {
            mainPageController.jumpToPage(0);
          } else {
            final bool shouldPop = await showPopDialog() ?? false;
            if (context.mounted && shouldPop) {
              audioHandler.stop();
              SystemNavigator.pop();
            }
          }
        } else {
          boxController.closeBox();
        }
      },
      child: SafeArea(
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            toolbarHeight: appBarHeight,
            backgroundColor: Theme.of(context).colorScheme.background,
            title: Text(
              "AntiiQ",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            actions: [
              IconButton(
                iconSize: 27,
                icon: Icon(
                  RemixIcon.play_list_2,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () {
                  showQueue(context);
                },
              ),
              IconButton(
                iconSize: 27,
                icon: Icon(
                  RemixIcon.settings_6,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const Settings(),
                    ),
                  );
                },
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
              )
            ],
          ),
          body: SlidingBox(
            draggable: false,
            collapsed: true,
            controller: boxController,
            minHeight: minHeightBox,
            maxHeight: maxHeightBox,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(7),
              topRight: Radius.circular(7),
            ),
            draggableIconColor: Theme.of(context).colorScheme.onSurface,
            color: Theme.of(context).colorScheme.surface,
            style: BoxStyle.sheet,
            backdrop: Backdrop(
              overlayOpacity: 0.0,
              fading: true,
              overlay: true,
              color: Theme.of(context).colorScheme.background,
              body:
                  !hasPermissions ? noAccessToLibraryWidget() : mainBackdrop(),
            ),
            body: NowPlaying(
              pageHeight: maxHeightBox - bottomNavigationBarHeight + 50,
              boxController: boxController,
            ),
            collapsedBody: MiniPlayer(boxController: boxController),
          ),
          bottomNavigationBar: BottomAppBar(
            padding: EdgeInsets.zero,
            height: bottomNavigationBarHeight,
            color: Theme.of(context).colorScheme.surface,
            elevation: 10,
            shadowColor: Colors.black,
            surfaceTintColor: Colors.transparent,
            child: CustomCard(
              theme: CardThemes().bottomNavBarTheme,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    onPressed: () {
                      boxController.closeBox();
                      mainPageController.jumpToPage(
                        mainPageIndexes["dashboard"] as int,
                      );
                    },
                    icon: Icon(
                      RemixIcon.dashboard,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      boxController.closeBox();
                      mainPageController.jumpToPage(
                        mainPageIndexes["equalizer"] as int,
                      );
                    },
                    icon: Icon(
                      RemixIcon.equalizer,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      boxController.closeBox();
                      mainPageController.jumpToPage(
                        mainPageIndexes["search"] as int,
                      );
                    },
                    icon: Icon(
                      RemixIcon.search_eye,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget noAccessToLibraryWidget() {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.redAccent.withOpacity(0.5),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Application doesn't have access to the library"),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => checkAndRequestPermissions(
                retry: true,
                stateSet: stateSet,
              ),
              child: const Text("Allow"),
            ),
          ],
        ),
      ),
    );
  }
}
