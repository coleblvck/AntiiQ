/*

Setup Song Library:
- Get all Songs, Albums, Artists and Genres and;
- Perform necessary conversions

*/


//Flutter Packages
import 'package:antiiq/player/utilities/files/query_and_sort.dart';
import 'package:antiiq/player/utilities/user_settings.dart';

//Path Provider
import 'package:path_provider/path_provider.dart';


//Hive
import 'package:hive_flutter/hive_flutter.dart';

import 'package:permission_handler/permission_handler.dart';

//Antiiq Packages
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/utilities/files/art_queries.dart';

initialLoad() async {
  await checkAndRequestPermissions();
  await furtherPermissionRequest();
  await Hive.initFlutter();
  antiiqStore = await Hive.openBox('antiiqBox');
  playlistStore = await Hive.openBox("playlists");
  playlistNameStore = await Hive.openBox("playlistNames");
  dataIsInitialized = await antiiqStore.get("dataInit", defaultValue: false);
  await initializeUserSettings();
  antiiqDirectory = await getApplicationDocumentsDirectory();
  await setDefaultArt();
}


loadLibrary() async {
  if (hasPermissions) {
    await queryAndSort();
  }
}

checkAndRequestPermissions({bool retry = false, stateSet}) async {
  // The param 'retryRequest' is false, by default.
  hasPermissions = await audioQuery.checkAndRequest(
    retryRequest: retry,
  );

  retry ? {loadLibrary(), stateSet()} : null;
}

furtherPermissionRequest() async {
  PermissionStatus status = await Permission.manageExternalStorage.status;
  if (status.isRestricted) {
    status = await Permission.manageExternalStorage.request();
  }

  if (status.isDenied) {
    status = await Permission.manageExternalStorage.request();
  }

  if (status.isPermanentlyDenied) {
    furtherPermissionPermanentlyDenied = true;
  }

  if (status.isGranted) {
    furtherPermissionGranted = true;
  }
}