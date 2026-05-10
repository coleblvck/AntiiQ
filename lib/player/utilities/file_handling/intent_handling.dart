import 'dart:async';

import 'package:antiiq/player/utilities/activity_handlers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const MethodChannel _intentChannel =
    MethodChannel('com.coleblvck.antiiq/intent_audio');

String? _lastIntentUri;
DateTime? _lastIntentAt;

Future<void> initReceiveIntent() async {
  _intentChannel.setMethodCallHandler(_handleIntentCall);

  try {
    final payload = await _intentChannel.invokeMapMethod<String, dynamic>(
      'getInitialIntent',
    );
    await _handleIntentPayload(payload);
  } on PlatformException catch (error) {
    debugPrint('Failed to read initial audio intent: $error');
  }
}

Future<dynamic> _handleIntentCall(MethodCall call) async {
  if (call.method != 'receivedIntent') return null;
  final arguments = call.arguments;
  if (arguments is Map) {
    await _handleIntentPayload(Map<String, dynamic>.from(arguments));
  }
  return null;
}

Future<void> _handleIntentPayload(Map<String, dynamic>? payload) async {
  final uri = payload?['uri'] as String?;
  if (uri == null || uri.isEmpty) return;

  final now = DateTime.now();
  if (_lastIntentUri == uri &&
      _lastIntentAt != null &&
      now.difference(_lastIntentAt!) < const Duration(seconds: 2)) {
    return;
  }

  _lastIntentUri = uri;
  _lastIntentAt = now;
  await playFromIntentLink(uri);
}
