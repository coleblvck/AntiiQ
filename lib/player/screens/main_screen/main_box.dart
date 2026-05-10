import 'dart:async';

import 'package:antiiq/chaos/antiiq_updates.dart';
import 'package:antiiq/chaos/widgets/antiiq_update.dart';
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/screens/main_screen/main_backdrop.dart';
import 'package:antiiq/player/screens/main_screen/sliding_box.dart';
import 'package:antiiq/player/screens/now_playing/now_playing.dart';
import 'package:antiiq/player/screens/queue/queue.dart';
import 'package:antiiq/player/screens/settings/settings.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/state/version_updates.dart';
import 'package:antiiq/player/ui/elements/ui_colours.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/widgets/mini_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';

class MainBoxMetrics {
  static double bottomNavigationBarHeight = 56;
  static double appBarHeight = 50;
  static double minHeightBox = 60 + bottomNavigationBarHeight;
}

class MainBox extends StatefulWidget {
  const MainBox({
    super.key,
  });
  @override
  State<MainBox> createState() => _MainBoxState();
}

class _MainBoxState extends State<MainBox> {
  final AntiiQBoxController boxController = AntiiQBoxController();
  final TextEditingController textEditingController = TextEditingController();

  Timer? libraryLoadTimer;
  DateTime? currentBackPressTime;
  bool _isLibraryLoading = false;
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
    if (mounted) {
      setState(() => _isLibraryLoading = true);
    }
    libraryLoadTimer ??=
        Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (mounted) setState(() {});
    });
    await antiiqState.libraryInit();

    libraryLoadTimer?.cancel();
    libraryLoadTimer = null;

    if (mounted) {
      stateSet();
      libraryLoadTotal = 1;
      libraryLoadProgress = 0;
      loadingMessage = "Loading Library";
      _isLibraryLoading = false;
      _showUpdateDialogIfNeeded();
    } else {
      return;
    }
  }

  Widget _buildLibraryStatusBar() {
    if (!_isLibraryLoading) return const SizedBox.shrink();
    final loadProgress = libraryLoadProgress;
    final loadTotal = libraryLoadTotal;
    final hasKnownTotal = loadTotal > 0;
    final progressValue =
        hasKnownTotal ? (loadProgress / loadTotal).clamp(0.0, 1.0) : 0.0;
    final progressText = hasKnownTotal
        ? "$loadProgress / $loadTotal"
        : loadProgress > 0
            ? "$loadProgress found"
            : "Scanning";

    return Positioned(
      top: 8,
      left: 12,
      right: 12,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AntiiQTheme.of(context)
                .colorScheme
                .background
                .withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(generalRadius),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      loadingMessage,
                      overflow: TextOverflow.ellipsis,
                      style:
                          AntiiQTheme.of(context).textStyles.onBackgroundText,
                    ),
                  ),
                  Text(
                    progressText,
                    style: AntiiQTheme.of(context).textStyles.onBackgroundText,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              CustomProgressIndicator(
                progress: hasKnownTotal ? progressValue : 0,
              ),
            ],
          ),
        ),
      ),
    );
  }

  stateSet() {
    setState(() {});
  }

  void _showUpdateDialogIfNeeded() async {
    final versionUpdates = context.read<VersionUpdates>();
    final currentVersion = antiiqUpdates[0].version;

    if (versionUpdates.shouldShowUpdate(currentVersion)) {
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        await AntiiQUpdateDialogClassic.show(
          context,
          antiiqUpdates[0],
          () {
            versionUpdates.setLastSeenUpdateVersion(currentVersion);
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: AntiiQTheme.of(context).colorScheme.background,
      ),
    );

    double maxHeightBox = MediaQuery.of(context).size.height -
        MainBoxMetrics.appBarHeight -
        MediaQuery.of(context).padding.vertical -
        MainBoxMetrics.bottomNavigationBarHeight;

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
              globalAntiiqAudioHandler.stop();
              SystemNavigator.pop();
            }
          }
        } else {
          boxController.closeBox();
        }
      },
      child: SafeArea(
        child: StreamBuilder<bool>(
            stream: boxController.visibilityStream,
            initialData: boxController.isCollapsedBodyVisible,
            builder: (context, snapshot) {
              return Scaffold(
                resizeToAvoidBottomInset: false,
                appBar: AppBar(
                  toolbarHeight: MainBoxMetrics.appBarHeight,
                  backgroundColor:
                      AntiiQTheme.of(context).colorScheme.background,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
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
                body: Stack(
                  children: [
                    AntiiQSlidingBox(
                      draggable: true,
                      controller: boxController,
                      minHeight: MainBoxMetrics.minHeightBox,
                      maxHeight: maxHeightBox,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(generalRadius),
                        topRight: Radius.circular(generalRadius),
                      ),
                      draggableIconColor:
                          AntiiQTheme.of(context).colorScheme.onSurface,
                      color: AntiiQTheme.of(context).colorScheme.surface,
                      backdrop: !antiiqState.permissions.has
                          ? noAccessToLibraryWidget()
                          : const MainBackdrop(),
                      onBoxOpen: () {
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                      body: NowPlaying(
                        pageHeight: maxHeightBox,
                        boxController: boxController,
                      ),
                      collapsedBody: MiniPlayer(boxController: boxController),
                    ),
                    _buildLibraryStatusBar(),
                  ],
                ),
                bottomNavigationBar: BottomAppBar(
                  padding: EdgeInsets.zero,
                  height: MainBoxMetrics.bottomNavigationBarHeight,
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
              );
            }),
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
