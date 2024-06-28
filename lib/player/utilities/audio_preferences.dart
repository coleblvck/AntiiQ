import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/utilities/user_settings.dart';
import 'package:just_audio/just_audio.dart';

setEqualizerEnabled(bool value) async {
  audioHandler.equalizer.setEnabled(value);
  await antiiqStore.put(MainBoxKeys.eqEnabledStorage, value);
}

getEqualizerEnabled() async {
  final bool enabled =
      await antiiqStore.get(MainBoxKeys.eqEnabledStorage, defaultValue: false);
  audioHandler.equalizer.setEnabled(enabled);
}

saveBandFrequencies() async {
  final params = await audioHandler.equalizer.parameters;
  List<double> frequencies = params.bands.map((e) => e.gain).toList();
  await antiiqStore.put(MainBoxKeys.bandFrequencyStorage, frequencies);
}

List bandFrequencies = [];

getBandFrequencies() async {
  bandFrequencies =
      await antiiqStore.get(MainBoxKeys.bandFrequencyStorage, defaultValue: []);
}

setBands() async {
  final params = await audioHandler.equalizer.parameters;
  List<AndroidEqualizerBand> bands = params.bands;
  if (bandFrequencies.isNotEmpty) {
    for (var band in bands) {
      band.setGain(bandFrequencies[bands.indexOf(band)]);
    }
  }
  bandsSet = true;
}

bool bandsSet = false;

updateShuffleMode(bool mode) async {
  await audioHandler.audioPlayer.setShuffleModeEnabled(mode);
  await antiiqStore.put(MainBoxKeys.shuffleModeStorage, mode);
  if (mode) {
    updateLoopMode(LoopMode.all);
  }
}

updateLoopMode(LoopMode mode) async {
  await audioHandler.audioPlayer.setLoopMode(mode);
  if (mode == LoopMode.one) {
    await antiiqStore.put(MainBoxKeys.loopModeStorage, "one");
  } else if (mode == LoopMode.all) {
    await antiiqStore.put(MainBoxKeys.loopModeStorage, "all");
  } else if (mode == LoopMode.off) {
    await antiiqStore.put(MainBoxKeys.loopModeStorage, "off");
  }
}

getAndSetShuffleMode() async {
  bool shuffleMode = await antiiqStore.get(MainBoxKeys.shuffleModeStorage,
      defaultValue: false);
  await audioHandler.audioPlayer.setShuffleModeEnabled(shuffleMode);
}

getAndSetLoopMode() async {
  String mode =
      await antiiqStore.get(MainBoxKeys.loopModeStorage, defaultValue: "off");
  await setLoopMode(mode);
}

setLoopMode(String mode) async {
  LoopMode modeToSet = LoopMode.off;
  if (mode == "all") {
    modeToSet = LoopMode.all;
  } else if (mode == "one") {
    modeToSet = LoopMode.one;
  }
  await audioHandler.audioPlayer.setLoopMode(modeToSet);
}
