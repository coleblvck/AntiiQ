import 'package:permission_handler/permission_handler.dart';
import 'package:restart_app/restart_app.dart';

class PermissionsState {
  bool has = false;

  checkAndRequest({bool retry = false}) async {
    await _requestMediaPermission();

    has =
        await Permission.storage.isGranted || await Permission.audio.isGranted;

    await _requestIfNeeded(Permission.notification);

    if (retry) {
      Restart.restartApp();
    }
  }

  Future<void> _requestMediaPermission() async {
    if (await _hasMediaPermission()) {
      return;
    }

    await _requestIfNeeded(Permission.audio);

    if (!await _hasMediaPermission()) {
      await _requestIfNeeded(Permission.storage);
    }
  }

  Future<bool> _hasMediaPermission() async {
    return await Permission.storage.isGranted ||
        await Permission.audio.isGranted;
  }

  Future<void> _requestIfNeeded(Permission permission) async {
    final status = await permission.status;
    if (status.isGranted || status.isPermanentlyDenied) {
      return;
    }
    await permission.request();
  }
}
