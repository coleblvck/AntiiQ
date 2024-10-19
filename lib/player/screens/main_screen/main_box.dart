import 'dart:async';

import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/screens/main_screen/main_backdrop.dart';
import 'package:antiiq/player/screens/now_playing/now_playing.dart';
import 'package:antiiq/player/screens/queue/queue.dart';
import 'package:antiiq/player/screens/settings/settings.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/ui/elements/ui_colours.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/widgets/mini_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sliding_box/flutter_sliding_box.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';

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
  DateTime? currentBackPressTime;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) {
        if (antiiqState.permissions.has) {
          initData();
        }
      },
    );
  }

  Future<bool> doubleTapPop() {
    DateTime now = DateTime.now();
    if (currentBackPressTime == null ||
        now.difference(currentBackPressTime!) > const Duration(seconds: 2)) {
      currentBackPressTime = now;
      Fluttertoast.showToast(
        msg: "Tap back again to quit",
        backgroundColor: currentColorScheme.surface,
        textColor: currentColorScheme.primary,
        gravity: ToastGravity.BOTTOM,
      );
      return Future.value(false);
    } else {
      return Future.value(true);
    }
  }

  Future<bool?> showPopDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AntiiQTheme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(generalRadius),
          ),
          title: Text(
            'Exit:',
            style: AntiiQTheme.of(context).textStyles.onSurfaceLargeHeader,
          ),
          content: Text(
            'Are you sure?',
            style: AntiiQTheme.of(context).textStyles.onSurfaceText,
          ),
          actions: <Widget>[
            CustomButton(
              style: AntiiQTheme.of(context).buttonStyles.style1,
              child: const Text('Stay'),
              function: () {
                Navigator.pop(context, false);
              },
            ),
            CustomButton(
              style: AntiiQTheme.of(context).buttonStyles.style2,
              child: const Text('Exit'),
              function: () {
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
              backgroundColor: AntiiQTheme.of(context).colorScheme.background,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(generalRadius),
              ),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message,
                      style:
                          AntiiQTheme.of(context).textStyles.onBackgroundText,
                    ),
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
                    Text(
                      "Processing Files $loadProgress of $loadTotal",
                      style:
                          AntiiQTheme.of(context).textStyles.onBackgroundText,
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
    await antiiqState.libraryInit();

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
        statusBarColor: AntiiQTheme.of(context).colorScheme.background,
      ),
    );
    //
    double bottomNavigationBarHeight = 60;
    double appBarHeight = 50;
    double minHeightBox = 50 + bottomNavigationBarHeight;
    double viewInsetsHeight = MediaQuery.of(context).viewPadding.top +
        MediaQuery.of(context).viewPadding.bottom;
    double maxHeightBox = MediaQuery.of(context).size.height -
        appBarHeight -
        viewInsetsHeight -
        bottomNavigationBarHeight;

    //
    return PopScope(
      canPop: false,
      //
      // Look further into this
      //
      onPopInvokedWithResult: (bool didPop, _) async {
        if (didPop) {
          return;
        }
        if (boxController.isBoxClosed) {
          if (mainPageController.page != 0) {
            mainPageController.jumpToPage(0);
          } else {
            final bool shouldPop = currentQuitType == QuitType.dialog
                ? await showPopDialog() ?? false
                : await doubleTapPop();
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
            backgroundColor: AntiiQTheme.of(context).colorScheme.background,
            title: Text(
              "AntiiQ",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AntiiQTheme.of(context).colorScheme.primary,
              ),
            ),
            actions: [
              IconButton(
                iconSize: 27,
                icon: Icon(
                  RemixIcon.play_list_2,
                  color: AntiiQTheme.of(context).colorScheme.primary,
                ),
                onPressed: () {
                  showQueue(context);
                },
              ),
              IconButton(
                iconSize: 27,
                icon: Icon(
                  RemixIcon.settings_6,
                  color: AntiiQTheme.of(context).colorScheme.primary,
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
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(generalRadius),
              topRight: Radius.circular(generalRadius),
            ),
            draggableIconColor: AntiiQTheme.of(context).colorScheme.onSurface,
            color: AntiiQTheme.of(context).colorScheme.surface,
            style: BoxStyle.sheet,
            backdrop: Backdrop(
              overlayOpacity: 0.0,
              fading: true,
              overlay: true,
              color: AntiiQTheme.of(context).colorScheme.background,
              body:
                  !antiiqState.permissions.has ? noAccessToLibraryWidget() : mainBackdrop(),
            ),
            onBoxOpen: () {
              FocusManager.instance.primaryFocus?.unfocus();
            },
            body: NowPlaying(
              pageHeight: maxHeightBox,
              boxController: boxController,
            ),
            collapsedBody: MiniPlayer(boxController: boxController),
          ),
          bottomNavigationBar: BottomAppBar(
            padding: EdgeInsets.zero,
            height: bottomNavigationBarHeight,
            color: AntiiQTheme.of(context).colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            child: CustomCard(
              theme: AntiiQTheme.of(context).cardThemes.background,
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
                      color: AntiiQTheme.of(context).colorScheme.primary,
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
                      color: AntiiQTheme.of(context).colorScheme.primary,
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
                      color: AntiiQTheme.of(context).colorScheme.primary,
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
              onPressed: () => antiiqState.permissions.checkAndRequest(
                retry: true,
              ),
              child: const Text("Allow"),
            ),
          ],
        ),
      ),
    );
  }
}
