import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/state/audio_setup.dart';
import 'package:antiiq/player/state/music_state.dart';
import 'package:antiiq/player/state/permissions_state.dart';
import 'package:antiiq/player/utilities/file_handling/art_queries.dart';
import 'package:antiiq/player/utilities/file_handling/intent_handling.dart';
import 'package:antiiq/player/utilities/initialize.dart';
import 'package:antiiq/player/utilities/settings/theme_settings.dart';
import 'package:antiiq/player/utilities/user_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

late AntiiqState antiiqState;

class AntiiqState {
  final AudioSetup audioSetup;
  final MusicState music;
  final PermissionsState permissions;
  final Boxes _boxes;
  late bool dataIsInitialized;
  late Box store;

  AntiiqState._create({
    required this.audioSetup,
    required this.music,
    required this.permissions,
    required Boxes boxes,
  }) : _boxes = boxes;

  static Future create() async {
    final state = AntiiqState._create(
      audioSetup: AudioSetup(),
      music: MusicState(),
      permissions: PermissionsState(),
      boxes: Boxes(),
    );
    antiiqState = state;
    await antiiqState._init();
  }

  _init() async {
    await permissions.checkAndRequest();
    await Hive.initFlutter();
    await _boxes.open(this);
    dataIsInitialized = await store.get("dataInit", defaultValue: false);
    await initializeUserSettings();
    antiiqDirectory = await getApplicationDocumentsDirectory();
    await setDefaultArt();
    await setOrientation();
    await audioSetup.init();
    await initReceiveIntent();
    WidgetsBinding.instance.addObserver(
      LifecycleEventHandler(
        resumeCallBack: () async => _resumeCallBack(),
      ),
    );
  }

  _resumeCallBack() async {
    if (dynamicThemeEnabled) {
      await updateDynamicTheme(dynamicColorBrightness);
      broadcastTheme();
    }
    updateStatusBarColors();
    updateStatusBarMode();
  }

  libraryInit() async {
    await music.init(this);
  }

  setOrientation() async {
    await SystemChrome.setPreferredOrientations(
      [
        DeviceOrientation.portraitUp,
      ],
    );
  }
}

class LifecycleEventHandler extends WidgetsBindingObserver {
  final AsyncCallback? resumeCallBack;
  final AsyncCallback? suspendingCallBack;

  LifecycleEventHandler({
    this.resumeCallBack,
    this.suspendingCallBack,
  });

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    //print("state changed ${state.name}");
    switch (state) {
      case AppLifecycleState.resumed:
        if (resumeCallBack != null) {
          await resumeCallBack!();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        if (suspendingCallBack != null) {
          await suspendingCallBack!();
        }
        break;
    }
  }
}
