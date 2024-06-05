import 'dart:async';

import 'package:antiiq/player/utilities/activity_handlers.dart';
import 'package:flutter/services.dart';
import 'package:receive_intent/receive_intent.dart';

Future<void> initReceiveInitialIntent() async {
  try {
    final receivedIntent = await ReceiveIntent.getInitialIntent();
    if (receivedIntent?.data != null) {
      playFromIntentLink(receivedIntent!.data!);
    }

  } on PlatformException {
    null;
  }
}

late StreamSubscription intentSub;
Future<void> initReceiveIntent() async {
  await initReceiveInitialIntent();
  intentSub = ReceiveIntent.receivedIntentStream.listen((Intent? intent) {
    playFromIntentLink(intent!.data!);
  });
}