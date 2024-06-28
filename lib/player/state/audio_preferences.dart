import 'package:antiiq/player/utilities/audio_preferences.dart';

class AudioPreferences {
  init() async {
    await getEqualizerEnabled();
    await getBandFrequencies();
    await getAndSetLoopMode();
    await getAndSetShuffleMode();
  }
}
