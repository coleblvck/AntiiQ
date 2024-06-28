import 'package:antiiq/player/state/audio_preferences.dart';
import 'package:audio_service/audio_service.dart';
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/utilities/audio_handler.dart';

class AudioSetup {
  final AudioPreferences preferences = AudioPreferences();
  init() async {
    audioHandler = await AudioService.init(
      builder: () => AntiiqAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: "com.coleblvck.antiiq.channel.audio",
        androidNotificationChannelName: "Antiiq Player",
        androidNotificationIcon: "drawable/antiiq_icon",
        androidNotificationOngoing: false,
        androidStopForegroundOnPause: false,
      ),
    );
    await preferences.init();
  }
}
