


import 'package:device_info_plus/device_info_plus.dart';

getDeviceInfo() async {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
  droidVersion = int.parse(androidInfo.version.release);
}

late int droidVersion;