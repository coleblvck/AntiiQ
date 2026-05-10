import 'package:antiiq/chaos/chaos_global_constants.dart';
import 'package:antiiq/chaos/chaos_ui_state.dart';
import 'package:antiiq/chaos/utilities/angle.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/settings/user_settings.dart';
import 'package:antiiq/player/widgets/ui/antiiq_slider.dart';
import 'package:chaos_ui/chaos_rotation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class Playback extends StatefulWidget {
  const Playback({super.key});

  @override
  State<Playback> createState() => _PlaybackState();
}

class _PlaybackState extends State<Playback> {
  bool _gaplessEnabled = true;
  bool _crossfadeEnabled = false;
  int _crossfadeMs = 1000;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final store = antiiqState.store;
    final gaplessEnabled =
        await store.get(MainBoxKeys.gaplessEnabled, defaultValue: true);
    final crossfadeEnabled =
        await store.get(MainBoxKeys.crossfadeEnabled, defaultValue: false);
    final crossfadeMs =
        await store.get(MainBoxKeys.crossfadeDurationMs, defaultValue: 1000);
    if (!mounted) return;
    setState(() {
      _gaplessEnabled = gaplessEnabled;
      _crossfadeEnabled = crossfadeEnabled;
      _crossfadeMs = crossfadeMs;
    });
  }

  @override
  Widget build(BuildContext context) {
    final chaosUIState = context.watch<ChaosUIState>();
    final innerRadius = chaosUIState.getAdjustedRadius(4);
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(chaosBasePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ToggleSetting(
              label: 'GAPLESS PLAYBACK',
              description: 'Start the next track without silence between songs',
              value: _gaplessEnabled,
              onChanged: (value) {
                HapticFeedback.lightImpact();
                setState(() => _gaplessEnabled = value);
                antiiqState.audioSetup.preferences.setGaplessEnabled(value);
              },
            ),
            const SizedBox(height: chaosBasePadding),
            _ToggleSetting(
              label: 'CROSSFADE',
              description: 'Blend the outgoing track into the next track',
              value: _crossfadeEnabled,
              onChanged: (value) {
                HapticFeedback.lightImpact();
                setState(() => _crossfadeEnabled = value);
                antiiqState.audioSetup.preferences.setCrossfadeEnabled(value);
              },
            ),
            const SizedBox(height: chaosBasePadding),
            _SettingContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CROSSFADE DURATION',
                    style: TextStyle(
                      color: AntiiQTheme.of(context).colorScheme.onBackground,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(_crossfadeMs / 1000).toStringAsFixed(1)} SECONDS',
                    style: TextStyle(
                      color: AntiiQTheme.of(context)
                          .colorScheme
                          .onBackground
                          .withValues(alpha: 0.6),
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 24,
                    child: AntiiQSlider(
                      min: 0,
                      max: 5000,
                      value: _crossfadeMs.toDouble(),
                      step: 100,
                      activeTrackColor:
                          AntiiQTheme.of(context).colorScheme.secondary,
                      inactiveTrackColor:
                          AntiiQTheme.of(context).colorScheme.surface,
                      thumbColor:
                          AntiiQTheme.of(context).colorScheme.onBackground,
                      thumbWidth: 24.0,
                      thumbHeight: 24.0,
                      thumbBorderRadius: innerRadius,
                      trackHeight: 24.0,
                      trackBorderRadius: innerRadius,
                      orientation: Axis.horizontal,
                      selectByTap: true,
                      onChanged: (value) {
                        setState(() => _crossfadeMs = value.round());
                      },
                      onChangeEnd: (value) {
                        final duration = value.round();
                        setState(() => _crossfadeMs = duration);
                        antiiqState.audioSetup.preferences
                            .setCrossfadeDuration(duration);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleSetting extends StatelessWidget {
  const _ToggleSetting({
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SettingContainer(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AntiiQTheme.of(context).colorScheme.onBackground,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: AntiiQTheme.of(context)
                        .colorScheme
                        .onBackground
                        .withValues(alpha: 0.6),
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ChaosSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SettingContainer extends StatelessWidget {
  const _SettingContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final chaosUIState = context.watch<ChaosUIState>();
    return ChaosRotatedStatefulWidget(
      maxAngle: getAnglePercentage(0.1, chaosUIState.chaosLevel),
      child: Container(
        padding: const EdgeInsets.all(chaosBasePadding * 2),
        decoration: BoxDecoration(
          color: AntiiQTheme.of(context)
              .colorScheme
              .surface
              .withValues(alpha: 0.2),
          border: Border.all(
            color: AntiiQTheme.of(context)
                .colorScheme
                .surface
                .withValues(alpha: 0.5),
            width: 1,
          ),
          borderRadius:
              BorderRadius.circular(chaosUIState.getAdjustedRadius(2)),
        ),
        child: child,
      ),
    );
  }
}

class ChaosSwitch extends StatelessWidget {
  const ChaosSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final chaosUIState = context.watch<ChaosUIState>();
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 48,
        height: 24,
        decoration: BoxDecoration(
          color: value
              ? AntiiQTheme.of(context).colorScheme.primary
              : AntiiQTheme.of(context).colorScheme.surface,
          border: Border.all(
            color: AntiiQTheme.of(context)
                .colorScheme
                .onBackground
                .withValues(alpha: 0.3),
            width: 1,
          ),
          borderRadius:
              BorderRadius.circular(chaosUIState.getAdjustedRadius(4)),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutQuart,
              left: value ? 26 : 2,
              top: 2,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: value
                      ? AntiiQTheme.of(context).colorScheme.onPrimary
                      : AntiiQTheme.of(context)
                          .colorScheme
                          .onBackground
                          .withValues(alpha: 0.6),
                  borderRadius:
                      BorderRadius.circular(chaosUIState.getAdjustedRadius(6)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
