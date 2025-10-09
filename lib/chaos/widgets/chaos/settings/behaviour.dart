import 'package:antiiq/chaos/chaos_global_constants.dart';
import 'package:antiiq/chaos/chaos_ui_state.dart';
import 'package:chaos_ui/chaos_rotation.dart';
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/settings/user_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class Behaviour extends StatefulWidget {
  const Behaviour({super.key});

  @override
  State<Behaviour> createState() => _BehaviourState();
}

class _BehaviourState extends State<Behaviour> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(chaosBasePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /* THIS SETTING IS IRRELEVANT HERE (PERHAPS)
            _ToggleSetting(
              label: 'SWIPE GESTURES',
              description:
                  'Enable swipe controls on Now Playing and Mini Player',
              value: swipeGestures,
              onChanged: (value) {
                HapticFeedback.lightImpact();
                setState(() {
                  setSwipeGestures(value);
                });
              },
            ),
            const SizedBox(height: chaosBasePadding),
            */
            _ToggleSetting(
              label: 'PREVIOUS RESTARTS',
              description:
                  'Previous button restarts current track before going back',
              value: previousRestart,
              onChanged: (value) {
                HapticFeedback.lightImpact();
                setState(() {
                  setPreviousButtonAction(value);
                });
              },
            ),
            const SizedBox(height: chaosBasePadding),
            _ToggleSetting(
              label: 'INTERACTIVE SEEKBAR',
              description: 'Enable seekbar interaction when Mini Player is collapsed',
              value: interactiveMiniPlayerSeekbar,
              onChanged: (value) {
                HapticFeedback.lightImpact();
                setState(() {
                  interactiveSeekBarSwitch(value);
                });
              },
            ),
            const SizedBox(height: chaosBasePadding),
            _ToggleSetting(
              label: 'TRACK DURATION',
              description: 'Show track duration in player',
              value: showTrackDuration,
              onChanged: (value) {
                HapticFeedback.lightImpact();
                setState(() {
                  trackDurationShowSwitch(value);
                });
              },
            ),
            /* THIS SETTING IS IRRELEVANT HERE FOR THIS UI (PERHAPS)
            const SizedBox(height: chaosBasePadding),
            _ToggleSetting(
              label: 'MINI PLAYER CONTROLS',
              description: 'Show additional controls in Mini Player',
              value: additionalMiniPlayerControls,
              onChanged: (value) {
                HapticFeedback.lightImpact();
                setState(() {
                  changeAdditionalMiniPlayerControls(value);
                });
              },
            ),
            */
            const SizedBox(height: chaosBasePadding * 2),
            const _SectionDivider(label: 'EXIT BEHAVIOUR'),
            const SizedBox(height: chaosBasePadding),
            _SettingContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BACK BUTTON ACTION',
                    style: TextStyle(
                      color: AntiiQTheme.of(context)
                          .colorScheme
                          .onBackground
                          .withValues(alpha: 0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: BinaryOption(
                          label: 'DIALOG',
                          isSelected: currentQuitType == QuitType.dialog,
                          onTap: () {
                            if (currentQuitType != QuitType.dialog) {
                              HapticFeedback.lightImpact();
                              setQuitType("dialog");
                              setState(() {});
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: chaosBasePadding),
                      Expanded(
                        child: BinaryOption(
                          label: 'DOUBLE TAP',
                          isSelected: currentQuitType == QuitType.doubleTap,
                          onTap: () {
                            if (currentQuitType != QuitType.doubleTap) {
                              HapticFeedback.lightImpact();
                              setQuitType("doubleTap");
                              setState(() {});
                            }
                          },
                        ),
                      ),
                    ],
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
  final String label;
  final String description;
  final bool value;
  final Function(bool) onChanged;

  const _ToggleSetting({
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

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
          ChaosSwitch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SettingContainer extends StatelessWidget {
  final Widget child;

  const _SettingContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    final chaosUIState = context.watch<ChaosUIState>();
    final outerRadius = chaosUIState.getAdjustedRadius(2);
    return ChaosRotatedStatefulWidget(
      child: Container(
        padding: const EdgeInsets.all(chaosBasePadding * 2),
        decoration: BoxDecoration(
          color:
              AntiiQTheme.of(context).colorScheme.surface.withValues(alpha: 0.2),
          border: Border.all(
            color: AntiiQTheme.of(context)
                .colorScheme
                .surface
                .withValues(alpha: 0.5),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(outerRadius),
        ),
        child: child,
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  final String label;

  const _SectionDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: AntiiQTheme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: AntiiQTheme.of(context).colorScheme.primary,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            color: AntiiQTheme.of(context)
                .colorScheme
                .primary
                .withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }
}

class BinaryOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const BinaryOption({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chaosUIState = context.watch<ChaosUIState>();
    final innerRadius = chaosUIState.getAdjustedRadius(4);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AntiiQTheme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.2)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? AntiiQTheme.of(context).colorScheme.primary
                : AntiiQTheme.of(context)
                    .colorScheme
                    .surface
                    .withValues(alpha: 0.5),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(innerRadius),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? AntiiQTheme.of(context).colorScheme.primary
                  : AntiiQTheme.of(context)
                      .colorScheme
                      .onBackground
                      .withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}

// Chaos-style switch (squared minimal design)
class ChaosSwitch extends StatelessWidget {
  final bool value;
  final Function(bool) onChanged;

  const ChaosSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final chaosUIState = context.watch<ChaosUIState>();
    final outerRadius = chaosUIState.getAdjustedRadius(4);
    final innerRadius = chaosUIState.getAdjustedRadius(6);
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
          borderRadius: BorderRadius.circular(outerRadius),
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
                  borderRadius: BorderRadius.circular(innerRadius),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
