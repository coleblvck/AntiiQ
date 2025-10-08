import 'package:antiiq/player/state/audio_preferences.dart';
import 'package:antiiq/player/utilities/audio_handler.dart';
import 'package:audio_service/audio_service.dart';

class AudioSetup {
  final AudioPreferences preferences = AudioPreferences();
  late AntiiqAudioHandler _audioHandler;
  AntiiqAudioHandler get audioHandler => _audioHandler;
  init() async {
    _audioHandler = await AudioService.init(
      builder: () => AntiiqAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: "com.coleblvck.antiiq.channel.audio",
        androidNotificationChannelName: "AntiiQ Player",
        androidNotificationIcon: "drawable/antiiq_icon",
        androidNotificationOngoing: false,
        androidStopForegroundOnPause: false,
      ),
    );
    await preferences.init(_audioHandler);
  }
}
