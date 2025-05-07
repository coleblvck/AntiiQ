import 'dart:ui';
import 'dart:async';
import 'dart:isolate';

import 'package:antiiq/home_widget/home_widget_manager.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

const String PLAY_PAUSE_ACTION = 'play_pause';
const String NEXT_ACTION = 'next';
const String PREVIOUS_ACTION = 'previous';
const String OPEN_APP_ACTION = 'open_app';

@pragma('vm:entry-point')
void backgroundCallback(Uri? uri) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  if (uri == null) return;

  final action = uri.host;

  await HomeWidget.saveWidgetData<String>('last_action', action);

  final SendPort? mainIsolateSendPort = IsolateNameServer.lookupPortByName(
    'antiiq_widget_port',
  );

  if (mainIsolateSendPort != null) {
    mainIsolateSendPort.send(action);
  }

  await updateWidgetUI(action);
}

Future<void> updateWidgetUI(String action) async {
  switch (action) {
    case PLAY_PAUSE_ACTION:
      final currentState =
          await HomeWidget.getWidgetData<bool>('is_playing') ?? false;
      await HomeWidget.saveWidgetData<bool>('is_playing', !currentState);
      break;
    default:
      break;
  }

  await HomeWidget.updateWidget(
    androidName: 'AntiiqMusicGlanceWidgetReceiver',
  );
}

final ReceivePort receivePort = ReceivePort();

void setupIsolateComms() {
  final bool isRegistered = IsolateNameServer.registerPortWithName(
    receivePort.sendPort,
    'antiiq_widget_port',
  );

  if (!isRegistered) {
      IsolateNameServer.removePortNameMapping('antiiq_widget_port');
      IsolateNameServer.registerPortWithName(receivePort.sendPort, 'antiiq_widget_port');
  }

  receivePort.listen((message) {
    if (message is String) {
      final uri = Uri.parse('antiiqwidget://$message');
      HomeWidgetManager.handleWidgetClicked(uri);

      HomeWidget.saveWidgetData<String>('last_action', null);
    }
  });
}

void setupBackgroundHandler() {
  setupIsolateComms();

  HomeWidget.registerInteractivityCallback(backgroundCallback);

  HomeWidget.getWidgetData<String>('last_action').then((action) {
    if (action != null) {
      Uri uri = Uri.parse('antiiqwidget://$action');
      HomeWidgetManager.handleWidgetClicked(uri);
      HomeWidget.saveWidgetData<String>('last_action', null);
    }
  });
}

void disposeIsolateComms() {
    receivePort.close();
    IsolateNameServer.removePortNameMapping('antiiq_widget_port');
}
