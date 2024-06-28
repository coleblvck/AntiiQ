import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/state/audio_setup.dart';
import 'package:antiiq/player/state/music_state.dart';
import 'package:antiiq/player/state/permissions_state.dart';
import 'package:antiiq/player/utilities/file_handling/art_queries.dart';
import 'package:antiiq/player/utilities/initialize.dart';
import 'package:antiiq/player/utilities/platform.dart';
import 'package:antiiq/player/utilities/user_settings.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

late AntiiqState state;

class AntiiqState {
  final AudioSetup _audioSetup = AudioSetup();
  final MusicState music = MusicState();
  final PermissionsState permissions = PermissionsState();
  final Boxes _boxes = Boxes();
  late bool dataIsInitialized;

  init() async {
    await getDeviceInfo();
    await permissions.checkAndRequest();
    await Hive.initFlutter();
    await _boxes.open();
    dataIsInitialized = await antiiqStore.get("dataInit", defaultValue: false);
    await initializeUserSettings();
    antiiqDirectory = await getApplicationDocumentsDirectory();
    await setDefaultArt();
    await setOrientation();
    await _audioSetup.init();
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
