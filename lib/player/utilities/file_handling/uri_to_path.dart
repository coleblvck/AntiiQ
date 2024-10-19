import 'package:flutter/services.dart';


const channel = MethodChannel("uriPathChannel");
/*
Future<String?> getPathFromURI(String contentUri) async {
  try {
    final String result = await channel.invokeMethod("getRealPathFromURI", contentUri);
    return result;
  } on PlatformException catch (e) {
    print("Failed to get path: '${e.message}'.");
    return null;
  }
}

*/
