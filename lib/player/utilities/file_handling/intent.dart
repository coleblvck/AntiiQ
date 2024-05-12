import 'dart:async';

import 'package:flutter/services.dart';
import 'package:receive_intent/receive_intent.dart';

Future<void> initReceiveInitialIntent() async {
  try {
    final receivedIntent = await ReceiveIntent.getInitialIntent();
    // TO DO
    print(receivedIntent!.data);

  } on PlatformException {
    null;
  }
}

late StreamSubscription intentSub;
Future<void> initReceiveIntent() async {
  await initReceiveInitialIntent();
  intentSub = ReceiveIntent.receivedIntentStream.listen((Intent? intent) {
    // TO DO
    print(intent!.data);
  });
}