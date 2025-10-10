import 'package:permission_handler/permission_handler.dart';
import 'package:restart_app/restart_app.dart';

class PermissionsState {
  bool has = false;

  checkAndRequest({bool retry = false}) async {
    await Permission.storage.request();
    await Permission.audio.request();

    has =
        await Permission.storage.isGranted || await Permission.audio.isGranted;

    await _furtherRequest();

    if (retry) {
      Restart.restartApp();
    }
  }

  _furtherRequest() async {
    PermissionStatus status = await Permission.manageExternalStorage.status;

    if (!status.isGranted) {
      status = await Permission.manageExternalStorage.request();
    }
  }
}
