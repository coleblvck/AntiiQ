import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/utilities/settings/user_settings.dart';
import 'package:just_audio/just_audio.dart';

class AudioPreferences {
  init() async {
    await _getEqualizerEnabled();
    await _getBandFrequencies();
    await _getAndSetLoopMode();
    await _getAndSetShuffleMode();
  }

  setEqualizerEnabled(bool value) async {
    audioHandler.equalizer.setEnabled(value);
    await antiiqState.store.put(MainBoxKeys.eqEnabledStorage, value);
  }

  _getEqualizerEnabled() async {
    final bool enabled = await antiiqState.store.get(MainBoxKeys.eqEnabledStorage,
        defaultValue: false);
    audioHandler.equalizer.setEnabled(enabled);
  }

  saveBandFrequencies() async {
    final params = await audioHandler.equalizer.parameters;
    List<double> frequencies = params.bands.map((e) => e.gain).toList();
    await antiiqState.store.put(MainBoxKeys.bandFrequencyStorage, frequencies);
  }

  List bandFrequencies = [];

  _getBandFrequencies() async {
    bandFrequencies = await antiiqState.store
        .get(MainBoxKeys.bandFrequencyStorage, defaultValue: []);
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
    await antiiqState.store.put(MainBoxKeys.shuffleModeStorage, mode);
    if (mode) {
      updateLoopMode(LoopMode.all);
    }
  }

  updateLoopMode(LoopMode mode) async {
    await audioHandler.audioPlayer.setLoopMode(mode);
    if (mode == LoopMode.one) {
      await antiiqState.store.put(MainBoxKeys.loopModeStorage, "one");
    } else if (mode == LoopMode.all) {
      await antiiqState.store.put(MainBoxKeys.loopModeStorage, "all");
    } else if (mode == LoopMode.off) {
      await antiiqState.store.put(MainBoxKeys.loopModeStorage, "off");
    }
  }

  _getAndSetShuffleMode() async {
    bool shuffleMode = await antiiqState.store.get(MainBoxKeys.shuffleModeStorage,
        defaultValue: false);
    await audioHandler.audioPlayer.setShuffleModeEnabled(shuffleMode);
  }

  _getAndSetLoopMode() async {
    String mode =
        await antiiqState.store.get(MainBoxKeys.loopModeStorage, defaultValue: "off");
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
}
