import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/utilities/audio_handler.dart';
import 'package:antiiq/player/utilities/native_audio_player.dart';
import 'package:antiiq/player/utilities/playlist_generator/playlist_generator.dart';
import 'package:antiiq/player/utilities/settings/user_settings.dart';
import 'package:audio_service/audio_service.dart';

class AudioPreferences {
  late AntiiqAudioHandler _audioHandler;
  init(AntiiqAudioHandler audioHandler) async {
    _audioHandler = audioHandler;
    await _getEqualizerEnabled();
    await _getBandFrequencies();
    await _getGaplessEnabled();
    await _getCrossfadeSettings();
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
    await _audioHandler.audioPlayer.setEffectsEnabled(value);
    await antiiqState.store.put(MainBoxKeys.eqEnabledStorage, value);
  }

  _getEqualizerEnabled() async {
    final bool enabled = await antiiqState.store
        .get(MainBoxKeys.eqEnabledStorage, defaultValue: false);
    await _audioHandler.audioPlayer.setEffectsEnabled(enabled);
  }

  saveBandFrequencies() async {
    await antiiqState.store.put(MainBoxKeys.bandFrequencyStorage, bandGains);
  }

  static const List<double> defaultBandFrequencies = [
    31,
    45,
    63,
    90,
    125,
    180,
    250,
    355,
    500,
    710,
    1000,
    1400,
    2000,
    4000,
    8000,
  ];

  List<double> bandGains = List<double>.filled(15, 0.0);

  _getBandFrequencies() async {
    final stored = await antiiqState.store
        .get(MainBoxKeys.bandFrequencyStorage, defaultValue: []);
    if (stored is List && stored.isNotEmpty) {
      bandGains = stored
          .take(15)
          .map((value) => (value as num).toDouble())
          .toList();
      while (bandGains.length < 15) {
        bandGains.add(0.0);
      }
    }
  }

  setBands() async {
    await _audioHandler.audioPlayer.setParametricEqBands(_nativeBands);
    bandsSet = true;
  }

  Future<void> updateBandGain(int index, double gainDb) async {
    if (index < 0 || index >= bandGains.length) return;
    bandGains[index] = gainDb.clamp(-12.0, 12.0);
    await setBands();
    await saveBandFrequencies();
  }

  List<NativeEqBand> get _nativeBands {
    return [
      for (int i = 0; i < defaultBandFrequencies.length; i++)
        NativeEqBand(
          frequency: defaultBandFrequencies[i],
          gainDb: bandGains[i],
          q: 1.0,
        ),
    ];
  }

  Future<void> setGaplessEnabled(bool value) async {
    await _audioHandler.audioPlayer.setGaplessEnabled(value);
    await antiiqState.store.put(MainBoxKeys.gaplessEnabled, value);
  }

  Future<void> _getGaplessEnabled() async {
    final enabled =
        await antiiqState.store.get(MainBoxKeys.gaplessEnabled, defaultValue: true);
    await _audioHandler.audioPlayer.setGaplessEnabled(enabled);
  }

  Future<void> setCrossfadeEnabled(bool value) async {
    await _audioHandler.audioPlayer.setCrossfadeEnabled(value);
    await antiiqState.store.put(MainBoxKeys.crossfadeEnabled, value);
  }

  Future<void> setCrossfadeDuration(int milliseconds) async {
    final duration = milliseconds.clamp(0, 5000);
    await _audioHandler.audioPlayer
        .setCrossfadeDuration(Duration(milliseconds: duration));
    await antiiqState.store.put(MainBoxKeys.crossfadeDurationMs, duration);
  }

  Future<void> _getCrossfadeSettings() async {
    final enabled = await antiiqState.store
        .get(MainBoxKeys.crossfadeEnabled, defaultValue: false);
    final duration = await antiiqState.store
        .get(MainBoxKeys.crossfadeDurationMs, defaultValue: 1000);
    await _audioHandler.audioPlayer.setCrossfadeEnabled(enabled);
    await _audioHandler.audioPlayer
        .setCrossfadeDuration(Duration(milliseconds: duration));
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
