import 'package:antiiq/player/utilities/app_restart.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsState {
  bool has = false;

  Future<void> checkAndRequest({bool retry = false}) async {
    await _requestMediaPermission();

    has =
        await Permission.storage.isGranted || await Permission.audio.isGranted;

    await _requestIfNeeded(Permission.notification);

    if (retry) {
      await restartAntiiQ();
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
