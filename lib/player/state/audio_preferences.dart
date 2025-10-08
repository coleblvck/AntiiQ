import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/utilities/audio_handler.dart';
import 'package:antiiq/player/utilities/playlist_generator/playlist_generator.dart';
import 'package:antiiq/player/utilities/settings/user_settings.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class AudioPreferences {
  late AntiiqAudioHandler _audioHandler;
  init(AntiiqAudioHandler audioHandler) async {
    _audioHandler = audioHandler;
    await _getEqualizerEnabled();
    await _getBandFrequencies();
    await _getAndSetLoopMode();
    await _getAndSetShuffleMode();
    await _getEndlessPlayEnabled();
  }

  _configureEndlessPlay(bool value) {
    if (value) {
      _audioHandler.configureEndlessPlay(
        bufferThreshold: 8, // Trigger when 8 tracks left
        generateBatchSize: 20, // Add 20 tracks each time
      );

      _audioHandler.setEndlessPlay(true,
          context: PlaylistType.fromHistory, // or current playlist type
          filterValue: null // or genre/artist/etc if applicable
          );
    } else {
      _audioHandler.setEndlessPlay(false);
    }
  }

  setEndlessPlayEnabled(bool value) async {
    _configureEndlessPlay(value);
    await antiiqState.store.put(MainBoxKeys.endlessPlayEnabled, value);
  }

  _getEndlessPlayEnabled() async {
    final bool enabled = await antiiqState.store
        .get(MainBoxKeys.endlessPlayEnabled, defaultValue: false);
    _configureEndlessPlay(enabled);
  }

  setEqualizerEnabled(bool value) async {
    _audioHandler.equalizer.setEnabled(value);
    await antiiqState.store.put(MainBoxKeys.eqEnabledStorage, value);
  }

  _getEqualizerEnabled() async {
    final bool enabled = await antiiqState.store
        .get(MainBoxKeys.eqEnabledStorage, defaultValue: false);
    _audioHandler.equalizer.setEnabled(enabled);
  }

  saveBandFrequencies() async {
    final params = await _audioHandler.equalizer.parameters;
    List<double> frequencies = params.bands.map((e) => e.gain).toList();
    await antiiqState.store.put(MainBoxKeys.bandFrequencyStorage, frequencies);
  }

  List bandFrequencies = [];

  _getBandFrequencies() async {
    bandFrequencies = await antiiqState.store
        .get(MainBoxKeys.bandFrequencyStorage, defaultValue: []);
  }

  setBands() async {
    final params = await _audioHandler.equalizer.parameters;
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
    final AudioServiceShuffleMode shuffleMode =
        mode ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none;
    await _audioHandler.setShuffleMode(shuffleMode);
    await antiiqState.store.put(MainBoxKeys.shuffleModeStorage, mode);
    if (mode) {
      updateLoopMode(AudioServiceRepeatMode.all);
    }
  }

  updateLoopMode(AudioServiceRepeatMode mode) async {
    await _audioHandler.setRepeatMode(mode);
    if (mode == AudioServiceRepeatMode.one) {
      await antiiqState.store.put(MainBoxKeys.loopModeStorage, "one");
    } else if (mode == AudioServiceRepeatMode.all) {
      await antiiqState.store.put(MainBoxKeys.loopModeStorage, "all");
    } else if (mode == AudioServiceRepeatMode.none) {
      await antiiqState.store.put(MainBoxKeys.loopModeStorage, "off");
    }
  }

  _getAndSetShuffleMode() async {
    bool storedShuffleMode = await antiiqState.store
        .get(MainBoxKeys.shuffleModeStorage, defaultValue: false);
    final AudioServiceShuffleMode shuffleMode = storedShuffleMode
        ? AudioServiceShuffleMode.all
        : AudioServiceShuffleMode.none;
    await _audioHandler.setShuffleMode(shuffleMode);
  }

  _getAndSetLoopMode() async {
    String mode = await antiiqState.store
        .get(MainBoxKeys.loopModeStorage, defaultValue: "off");
    await _setLoopMode(mode);
  }

  _setLoopMode(String mode) async {
    AudioServiceRepeatMode modeToSet = AudioServiceRepeatMode.none;
    if (mode == "all") {
      modeToSet = AudioServiceRepeatMode.all;
    } else if (mode == "one") {
      modeToSet = AudioServiceRepeatMode.one;
    }
    await _audioHandler.setRepeatMode(modeToSet);
  }
}
