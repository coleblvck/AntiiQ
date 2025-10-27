import 'package:antiiq/chaos/widgets/antiiq_update.dart';

List<AntiiQUpdate> antiiqUpdates = [
  const AntiiQUpdate(
    title: 'Breaking Changes Ahead',
    subtitle: 'Some changes to expect in future versions of AntiiQ starting from version 2.0.0',
    version: '2.0.0',
    updates: [
      'New native audio engine for improved performance and broad codec support, based on FFmpeg.',
      'Improved audio effects including a new multiband parametric equalizer with more bands and better precision',
      'Gapless playback & crossfade',
      'New native library metadata scanning, much better than the current implementation, but all current library arrangements would be lost: playlists, history, etc.',
      'The current Chaos UI being the only supported UI mode going forward.',
    ],
  )
];
