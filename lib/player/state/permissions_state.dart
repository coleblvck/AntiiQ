import 'package:permission_handler/permission_handler.dart';
import 'package:restart_app/restart_app.dart';

import '../global_variables.dart';

class PermissionsState {
  bool has = false;

  checkAndRequest({bool retry = false}) async {
    has = await audioQuery.checkAndRequest(
      retryRequest: retry,
    );
    await _furtherRequest();
    retry? Restart.restartApp() : null;
  }



  _furtherRequest() async {
    PermissionStatus status = await Permission.manageExternalStorage.status;

    if (!status.isGranted) {
      status = await Permission.manageExternalStorage.request();
    }
  }
}
