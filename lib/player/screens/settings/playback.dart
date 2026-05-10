import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/widgets/ui/antiiq_slider.dart';
import 'package:flutter/material.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';

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
    final gaplessEnabled = await store.get(
      'gaplessEnabled',
      defaultValue: true,
    );
    final crossfadeEnabled = await store.get(
      'crossfadeEnabled',
      defaultValue: false,
    );
    final crossfadeMs = await store.get(
      'crossfadeDurationMs',
      defaultValue: 1000,
    );
    if (!mounted) return;
    setState(() {
      _gaplessEnabled = gaplessEnabled;
      _crossfadeEnabled = crossfadeEnabled;
      _crossfadeMs = crossfadeMs;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AntiiQTheme.of(context);
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 75,
          backgroundColor: theme.colorScheme.background,
          elevation: settingsPageAppBarElevation,
          surfaceTintColor: Colors.transparent,
          shadowColor: theme.colorScheme.onBackground,
          leading: IconButton(
            iconSize: settingsPageAppBarIconButtonSize,
            color: theme.colorScheme.secondary,
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(RemixIcon.arrow_left),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: Text(
                "Playback",
                style: theme.textStyles.onBackgroundLargeHeader.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.background,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                _SwitchCard(
                  title: "Gapless playback:",
                  value: _gaplessEnabled,
                  onChanged: (value) async {
                    setState(() => _gaplessEnabled = value);
                    await antiiqState.audioSetup.preferences
                        .setGaplessEnabled(value);
                  },
                ),
                _SwitchCard(
                  title: "Crossfade between tracks:",
                  value: _crossfadeEnabled,
                  onChanged: (value) async {
                    setState(() => _crossfadeEnabled = value);
                    await antiiqState.audioSetup.preferences
                        .setCrossfadeEnabled(value);
                  },
                ),
                CustomCard(
                  theme: theme.cardThemes.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Crossfade duration: ${(_crossfadeMs / 1000).toStringAsFixed(1)} seconds",
                          style: theme.textStyles.onSurfaceText,
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 20,
                          child: AntiiQSlider(
                            min: 0,
                            max: 5000,
                            value: _crossfadeMs.toDouble(),
                            step: 100,
                            activeTrackColor: theme.colorScheme.secondary,
                            inactiveTrackColor: theme.colorScheme.primary,
                            thumbColor: theme.colorScheme.onPrimary,
                            thumbWidth: 30.0,
                            thumbHeight: 16.0,
                            thumbBorderRadius: generalRadius / 2,
                            trackHeight: 20.0,
                            trackBorderRadius: generalRadius - 6,
                            orientation: Axis.horizontal,
                            selectByTap: true,
                            onChanged: (value) {
                              setState(() => _crossfadeMs = value.round());
                            },
                            onChangeEnd: (value) async {
                              final duration = value.round();
                              setState(() => _crossfadeMs = duration);
                              await antiiqState.audioSetup.preferences
                                  .setCrossfadeDuration(duration);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SwitchCard extends StatelessWidget {
  const _SwitchCard({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = AntiiQTheme.of(context);
    return CustomCard(
      theme: theme.cardThemes.surface,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textStyles.onSurfaceText,
            ),
            Switch(
              activeTrackColor: theme.colorScheme.primary,
              activeThumbColor: theme.colorScheme.onPrimary,
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
