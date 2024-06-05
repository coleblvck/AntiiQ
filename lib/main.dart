//Flutter Packages
import 'package:antiiq/player/utilities/file_handling/intent.dart';
import 'package:antiiq/player/utilities/user_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

//Audio Service
import 'package:audio_service/audio_service.dart';

//Antiiq Packages
import 'package:antiiq/player/utilities/audio_handler.dart';
import 'package:antiiq/player/ui/elements/ui_colours.dart';
import 'package:antiiq/player/screens/main_screen/main_box.dart';
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/utilities/initialize.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initialLoad();
  await SystemChrome.setPreferredOrientations(
    [
      DeviceOrientation.portraitUp,
    ],
  );
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: currentColorScheme.background,
    ),
  );

  audioHandler = await AudioService.init(
      builder: () => AntiiqAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: "com.coleblvck.antiiq.channel.audio",
        androidNotificationChannelName: "Antiiq Player",
        androidNotificationIcon: "drawable/antiiq_icon",
        androidNotificationOngoing: false,
        androidStopForegroundOnPause: false,
      ));
  await initializeAudioPreferences();
  // Remove this from here or invoke optional popup.
  await initReceiveIntent();

  runApp(const Antiiq());
}

class Antiiq extends StatelessWidget {
  const Antiiq({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ColorScheme>(
        stream: themeStream.stream,
        builder: (context, snapshot) {
          return MaterialApp(
            title: 'AntiiQ',
            theme: ThemeData(
              colorScheme: snapshot.data ?? getColorScheme(),
              useMaterial3: true,
            ),
            debugShowCheckedModeBanner: false,
            home: const MainBox(),
          );
        });
  }
}
