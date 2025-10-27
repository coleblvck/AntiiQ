import 'package:antiiq/chaos/chaos_global_constants.dart';
import 'package:antiiq/chaos/chaos_ui_state.dart';
import 'package:antiiq/chaos/utilities/angle.dart';
import 'package:chaos_ui/chaos_rotation.dart';
import 'package:antiiq/home_widget/home_widget_manager.dart';
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/ui/elements/ui_colours.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/settings/user_settings.dart';
import 'package:antiiq/player/widgets/ui/antiiq_slider.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';
import 'package:antiiq/player/utilities/settings/theme_settings.dart';
import 'package:home_widget/home_widget.dart';

class UserInterface extends StatefulWidget {
  const UserInterface({super.key});

  @override
  State<UserInterface> createState() => _UserInterfaceState();
}

class _UserInterfaceState extends State<UserInterface>
    with SingleTickerProviderStateMixin {
  bool _coverArtBackground = true;
  int _backgroundOpacity = 50;
  bool _isLoading = true;
  late AnimationController _glitchController;

  @override
  void initState() {
    super.initState();
    _glitchController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    _loadWidgetSettings();
  }

  @override
  void dispose() {
    _glitchController.dispose();
    super.dispose();
  }

  Future<void> _loadWidgetSettings() async {
    try {
      final coverArtBackground =
          await HomeWidget.getWidgetData<bool>('cover_art_background');
      final backgroundOpacity =
          await HomeWidget.getWidgetData<int>('background_opacity');

      setState(() {
        _coverArtBackground = coverArtBackground ?? true;
        _backgroundOpacity = backgroundOpacity ?? 50;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _SectionHeader(title: 'UI MODE', glitchController: _glitchController),
        _UIModeSetting(setPageState: setState),
        _ChaosLevelSetting(),
        _SectionHeader(
            title: 'DASHBOARD MODE', glitchController: _glitchController),
        _DashboardModeSetting(),
        _SectionHeader(title: 'GENERAL', glitchController: _glitchController),
        _StatusBarModeSetting(setPageState: setState),
        _UiRoundnessSetting(),
        _CoverArtFitSetting(setPageState: setState),
        _SectionHeader(title: 'WIDGET', glitchController: _glitchController),
        _WidgetSettingsSection(
          coverArtBackground: _coverArtBackground,
          backgroundOpacity: _backgroundOpacity,
          isLoading: _isLoading,
          onCoverArtBackgroundChanged: (value) {
            setState(() => _coverArtBackground = value);
          },
          onBackgroundOpacityChanged: (value) {
            setState(() => _backgroundOpacity = value.round());
          },
        ),
        _SectionHeader(title: 'THEME', glitchController: _glitchController),
        _DynamicThemeSetting(setPageState: setState),
        _SettingsThemeGrid(),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final AnimationController glitchController;

  const _SectionHeader({required this.title, required this.glitchController});

  @override
  Widget build(BuildContext context) {
    final currentRadius = context.watch<ChaosUIState>().chaosRadius;
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(chaosBasePadding, chaosBasePadding,
            chaosBasePadding, chaosBasePadding),
        padding: const EdgeInsets.all(chaosBasePadding * 1.5),
        decoration: BoxDecoration(
          border: Border.all(
            color: AntiiQTheme.of(context)
                .colorScheme
                .primary
                .withValues(alpha: 0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(currentRadius - 2),
        ),
        child: AnimatedBuilder(
          animation: glitchController,
          builder: (context, child) {
            final glitchOffset = glitchController.value > 0.95
                ? Offset((glitchController.value - 0.95) * 20, 0)
                : Offset.zero;

            return Transform.translate(
              offset: glitchOffset,
              child: Text(
                title,
                style: TextStyle(
                  color: AntiiQTheme.of(context).colorScheme.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _UIModeSetting extends StatelessWidget {
  final void Function(void Function()) setPageState;

  const _UIModeSetting({required this.setPageState});

  Future<void> _showChaosUIDialog(
      BuildContext context, ChaosUIState chaosUIState, bool enable) {
    final currentRadius = context.read<ChaosUIState>().chaosRadius;
    return showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AntiiQTheme.of(context).colorScheme.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(currentRadius),
            side: BorderSide(
              color: AntiiQTheme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(chaosBasePadding * 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'SWITCH TO CLASSIC UI?',
                  style: TextStyle(
                    color: AntiiQTheme.of(context).colorScheme.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  enable
                      ? 'This will add subtle rotations and visual effects to UI elements throughout the app. You can switch back anytime from the settings menu.'
                      : 'This will disable Chaos UI, removing all Chaos rotations and Chaos visual effects from UI elements, switching to the AntiiQ Classic UI.',
                  style: TextStyle(
                    color: AntiiQTheme.of(context)
                        .colorScheme
                        .onBackground
                        .withValues(alpha: 0.8),
                    fontSize: 12,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(chaosBasePadding * 1.5),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AntiiQTheme.of(context)
                                  .colorScheme
                                  .surface
                                  .withValues(alpha: 0.5),
                              width: 1,
                            ),
                            borderRadius:
                                BorderRadius.circular(currentRadius - 6),
                          ),
                          child: Center(
                            child: Text(
                              'CANCEL',
                              style: TextStyle(
                                color: AntiiQTheme.of(context)
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
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          chaosUIState.setChaosUIStatus(enable);
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(chaosBasePadding * 1.5),
                          decoration: BoxDecoration(
                            color: AntiiQTheme.of(context).colorScheme.primary,
                            border: Border.all(
                              color: AntiiQTheme.of(context)
                                  .colorScheme
                                  .onPrimary
                                  .withValues(alpha: 0.3),
                              width: 1,
                            ),
                            borderRadius:
                                BorderRadius.circular(currentRadius - 6),
                          ),
                          child: Center(
                            child: Text(
                              'SWITCH',
                              style: TextStyle(
                                color: AntiiQTheme.of(context)
                                    .colorScheme
                                    .onPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chaosUIState = context.watch<ChaosUIState>();
    return SliverToBoxAdapter(
      child: _SettingContainer(
        child: Row(
          children: [
            Expanded(
              child: _BinaryOption(
                label: "CLASSIC",
                isSelected: !chaosUIState.chaosUIStatus,
                onTap: () {
                  if (chaosUIState.chaosUIStatus) {
                    _showChaosUIDialog(context, chaosUIState, false);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _BinaryOption(
                label: "CHAOS",
                isSelected: chaosUIState.chaosUIStatus,
                onTap: () {
                  if (!chaosUIState.chaosUIStatus) {
                    _showChaosUIDialog(context, chaosUIState, true);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardModeSetting extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final chaosUIState = context.watch<ChaosUIState>();
    final canvasEnabled = chaosUIState.canvasEnabled;
    return SliverToBoxAdapter(
      child: _SettingContainer(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CANVAS',
              style: TextStyle(
                color: AntiiQTheme.of(context).colorScheme.onBackground,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            _ChaosSwitch(
              value: canvasEnabled,
              onChanged: (value) async {
                HapticFeedback.lightImpact();
                await chaosUIState.setCanvasEnabled(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBarModeSetting extends StatelessWidget {
  final void Function(void Function()) setPageState;

  const _StatusBarModeSetting({required this.setPageState});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: _SettingContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'STATUS BAR',
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
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _BinaryOption(
                    label: 'DEFAULT',
                    isSelected:
                        currentStatusBarMode == StatusBarMode.defaultMode,
                    onTap: () {
                      if (currentStatusBarMode != StatusBarMode.defaultMode) {
                        HapticFeedback.lightImpact();
                        setStatusBarMode("default");
                        setPageState(() {});
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _BinaryOption(
                    label: 'IMMERSIVE',
                    isSelected:
                        currentStatusBarMode == StatusBarMode.immersiveMode,
                    onTap: () {
                      if (currentStatusBarMode != StatusBarMode.immersiveMode) {
                        HapticFeedback.lightImpact();
                        setStatusBarMode("immersive");
                        setPageState(() {});
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverArtFitSetting extends StatelessWidget {
  final void Function(void Function()) setPageState;

  const _CoverArtFitSetting({required this.setPageState});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: _SettingContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'COVER ART FIT',
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
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _BinaryOption(
                    label: 'COVER',
                    isSelected: currentCoverArtFit == ArtFit.cover,
                    onTap: () {
                      if (currentCoverArtFit != ArtFit.cover) {
                        HapticFeedback.lightImpact();
                        changeCoverArtFit("cover");
                        setPageState(() {});
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _BinaryOption(
                    label: 'CONTAIN',
                    isSelected: currentCoverArtFit == ArtFit.contain,
                    onTap: () {
                      if (currentCoverArtFit != ArtFit.contain) {
                        HapticFeedback.lightImpact();
                        changeCoverArtFit("contain");
                        setPageState(() {});
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UiRoundnessSetting extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final chaosState = context.read<ChaosUIState>();
    final currentRadius = context.watch<ChaosUIState>().chaosRadius;
    return SliverToBoxAdapter(
      child: _SettingContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CHAOS UI ROUNDNESS',
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
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: chaosBasePadding,
                      vertical: chaosBasePadding / 2),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AntiiQTheme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.5),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(currentRadius - 4),
                  ),
                  child: Text(
                    '${currentRadius.round()}PX',
                    style: TextStyle(
                      color: AntiiQTheme.of(context).colorScheme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 24,
              child: AntiiQSlider(
                activeTrackColor: AntiiQTheme.of(context).colorScheme.primary,
                inactiveTrackColor: AntiiQTheme.of(context).colorScheme.surface,
                thumbColor: AntiiQTheme.of(context).colorScheme.onBackground,
                thumbWidth: 24.0,
                thumbHeight: 24.0,
                thumbBorderRadius: currentRadius - 4,
                trackHeight: 24.0,
                trackBorderRadius: currentRadius - 4,
                orientation: Axis.horizontal,
                selectByTap: true,
                value: currentRadius,
                min: 0,
                max: 16,
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  chaosState.setChaosRadius(value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChaosLevelSetting extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final chaosState = context.watch<ChaosUIState>();
    final currentRadius = chaosState.chaosRadius;
    final currentLevel = chaosState.chaosLevel;
    return SliverToBoxAdapter(
      child: _SettingContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CHAOS LEVEL',
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
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: chaosBasePadding,
                      vertical: chaosBasePadding / 2),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AntiiQTheme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.5),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(currentRadius - 4),
                  ),
                  child: Text(
                    currentLevel.toStringAsFixed(2),
                    style: TextStyle(
                      color: AntiiQTheme.of(context).colorScheme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 24,
              child: AntiiQSlider(
                activeTrackColor: AntiiQTheme.of(context).colorScheme.primary,
                inactiveTrackColor: AntiiQTheme.of(context).colorScheme.surface,
                thumbColor: AntiiQTheme.of(context).colorScheme.onBackground,
                thumbWidth: 24.0,
                thumbHeight: 24.0,
                thumbBorderRadius: currentRadius - 4,
                trackHeight: 24.0,
                trackBorderRadius: currentRadius - 4,
                orientation: Axis.horizontal,
                selectByTap: true,
                value: currentLevel,
                min: 0,
                max: 1,
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  chaosState.setChaosLevel(value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WidgetSettingsSection extends StatelessWidget {
  final bool coverArtBackground;
  final int backgroundOpacity;
  final bool isLoading;
  final Function(bool) onCoverArtBackgroundChanged;
  final Function(double) onBackgroundOpacityChanged;

  const _WidgetSettingsSection({
    required this.coverArtBackground,
    required this.backgroundOpacity,
    required this.isLoading,
    required this.onCoverArtBackgroundChanged,
    required this.onBackgroundOpacityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currentRadius = context.watch<ChaosUIState>().chaosRadius;
    if (isLoading) {
      return const SliverToBoxAdapter(
        child: _SettingContainer(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: _SettingContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'COVER ART BG',
                  style: TextStyle(
                    color: AntiiQTheme.of(context).colorScheme.onBackground,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                _ChaosSwitch(
                  value: coverArtBackground,
                  onChanged: (value) {
                    HapticFeedback.lightImpact();
                    onCoverArtBackgroundChanged(value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'OPACITY',
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
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: chaosBasePadding,
                      vertical: chaosBasePadding / 2),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AntiiQTheme.of(context)
                          .colorScheme
                          .secondary
                          .withValues(alpha: 0.5),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(currentRadius - 4),
                  ),
                  child: Text(
                    '$backgroundOpacity%',
                    style: TextStyle(
                      color: AntiiQTheme.of(context).colorScheme.secondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 24,
              child: AntiiQSlider(
                activeTrackColor: AntiiQTheme.of(context).colorScheme.secondary,
                inactiveTrackColor: AntiiQTheme.of(context).colorScheme.surface,
                thumbColor: AntiiQTheme.of(context).colorScheme.onBackground,
                thumbWidth: 24.0,
                thumbHeight: 24.0,
                thumbBorderRadius: currentRadius - 4,
                trackHeight: 24.0,
                trackBorderRadius: currentRadius - 4,
                orientation: Axis.horizontal,
                selectByTap: true,
                value: backgroundOpacity.toDouble(),
                min: 0,
                max: 100,
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  onBackgroundOpacityChanged(value);
                },
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                HomeWidgetManager.updateVisuals(
                    backgroundOpacity, coverArtBackground);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'WIDGET UPDATED',
                      style: TextStyle(
                        color: AntiiQTheme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    backgroundColor:
                        AntiiQTheme.of(context).colorScheme.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(currentRadius),
                      side: BorderSide(
                        color: AntiiQTheme.of(context)
                            .colorScheme
                            .onPrimary
                            .withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(chaosBasePadding * 2),
                decoration: BoxDecoration(
                  color: AntiiQTheme.of(context).colorScheme.primary,
                  border: Border.all(
                    color: AntiiQTheme.of(context)
                        .colorScheme
                        .onPrimary
                        .withValues(alpha: 0.3),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(currentRadius - 4),
                ),
                child: Center(
                  child: Text(
                    'APPLY',
                    style: TextStyle(
                      color: AntiiQTheme.of(context).colorScheme.onPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DynamicThemeSetting extends StatelessWidget {
  final void Function(void Function()) setPageState;

  const _DynamicThemeSetting({required this.setPageState});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: _SettingContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'DYNAMIC',
                  style: TextStyle(
                    color: AntiiQTheme.of(context).colorScheme.onBackground,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                _ChaosSwitch(
                  value: dynamicThemeEnabled,
                  onChanged: (value) {
                    HapticFeedback.lightImpact();
                    setPageState(() {
                      switchDynamicTheme(value);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _BinaryOption(
                    label: 'DARK',
                    isSelected: dynamicColorBrightness == Brightness.dark,
                    onTap: () {
                      if (dynamicColorBrightness != Brightness.dark) {
                        HapticFeedback.lightImpact();
                        changeDynamicColorBrightness("dark");
                        setPageState(() {});
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _BinaryOption(
                    label: 'LIGHT',
                    isSelected: dynamicColorBrightness == Brightness.light,
                    onTap: () {
                      if (dynamicColorBrightness != Brightness.light) {
                        HapticFeedback.lightImpact();
                        changeDynamicColorBrightness("light");
                        setPageState(() {});
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AMOLED',
                  style: TextStyle(
                    color: AntiiQTheme.of(context).colorScheme.onBackground,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                _ChaosSwitch(
                  value: dynamicAmoledEnabled,
                  onChanged: (value) {
                    HapticFeedback.lightImpact();
                    setPageState(() {
                      switchDynamicAmoled(value);
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsThemeGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.only(
          bottom: chaosBasePadding,
          left: chaosBasePadding,
          right: chaosBasePadding),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.1,
          crossAxisSpacing: chaosBasePadding,
          mainAxisSpacing: chaosBasePadding,
        ),
        delegate: SliverChildListDelegate([
          _CustomThemeCard(),
          for (String theme in customThemes.keys) _ThemeCard(themeName: theme),
        ]),
      ),
    );
  }
}

class _CustomThemeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final chaosUIState = context.watch<ChaosUIState>();
    final currentRadius = chaosUIState.chaosRadius;
    final chaosLevel = chaosUIState.chaosLevel;
    return ChaosRotatedStatefulWidget(
      maxAngle: getAnglePercentage(0.1, chaosLevel),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          _customColorEditSheet(context);
        },
        child: Container(
          decoration: BoxDecoration(
            color: AntiiQTheme.of(context)
                .colorScheme
                .surface
                .withValues(alpha: 0.3),
            border: Border.all(
              color: AntiiQTheme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.5),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(currentRadius - 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                RemixIcon.palette,
                color: AntiiQTheme.of(context).colorScheme.primary,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'CUSTOM',
                style: TextStyle(
                  color: AntiiQTheme.of(context).colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final String themeName;

  const _ThemeCard({required this.themeName});

  @override
  Widget build(BuildContext context) {
    final chaosUIState = context.watch<ChaosUIState>();
    final currentRadius = chaosUIState.chaosRadius;
    final chaosLevel = chaosUIState.chaosLevel;
    final theme = customThemes[themeName]!;

    return ChaosRotatedStatefulWidget(
      maxAngle: getAnglePercentage(0.1, chaosLevel),
      child: StreamBuilder<AntiiQColorScheme>(
          stream: themeStream.stream,
          builder: (context, snapshot) {
            final isActive = currentTheme == themeName && !dynamicThemeEnabled;
            return GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                changeTheme(themeName);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: theme.background,
                  border: Border.all(
                    color: isActive
                        ? theme.primary
                        : theme.surface.withValues(alpha: 0.5),
                    width: isActive ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(currentRadius - 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(chaosBasePadding * 1.5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        themeName.toUpperCase(),
                        style: TextStyle(
                          color: theme.onBackground,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          _ColorBlock(color: theme.primary, size: 16),
                          const SizedBox(width: 4),
                          _ColorBlock(color: theme.secondary, size: 16),
                          const SizedBox(width: 4),
                          _ColorBlock(color: theme.surface, size: 16),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.primary,
                            borderRadius:
                                BorderRadius.circular(currentRadius - 8),
                          ),
                          child: Text(
                            'ACTIVE',
                            style: TextStyle(
                              color: theme.onPrimary,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
    );
  }
}

class _ColorBlock extends StatelessWidget {
  final Color color;
  final double size;

  const _ColorBlock({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    final currentRadius = context.watch<ChaosUIState>().chaosRadius;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(currentRadius - 8),
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
    final currentRadius = chaosUIState.chaosRadius;
    final chaosLevel = chaosUIState.chaosLevel;
    return ChaosRotatedStatefulWidget(
      maxAngle: getAnglePercentage(0.1, chaosLevel),
      child: Container(
        margin: const EdgeInsets.only(
            left: chaosBasePadding,
            right: chaosBasePadding,
            bottom: chaosBasePadding),
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
          borderRadius: BorderRadius.circular(currentRadius - 2),
        ),
        child: child,
      ),
    );
  }
}

class _BinaryOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _BinaryOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentRadius = context.watch<ChaosUIState>().chaosRadius;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: chaosBasePadding * 1.5),
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
          borderRadius: BorderRadius.circular(currentRadius - 4),
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

class _ChaosSwitch extends StatelessWidget {
  final bool value;
  final Function(bool) onChanged;

  const _ChaosSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final currentRadius = context.watch<ChaosUIState>().chaosRadius;
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
          borderRadius: BorderRadius.circular(currentRadius - 4),
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
                  borderRadius: BorderRadius.circular(currentRadius - 6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _customColorEditSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      AntiiQColorScheme schemeToEdit = customColorScheme ?? currentColorScheme;
      Color primaryColor = schemeToEdit.primary;
      Color secondaryColor = schemeToEdit.secondary;
      Color surfaceColor = schemeToEdit.surface;
      Color backgroundColor = schemeToEdit.background;
      Color onPrimaryColor = schemeToEdit.onPrimary;
      Color onSecondaryColor = schemeToEdit.onSecondary;
      Color onSurfaceColor = schemeToEdit.onSurface;
      Color onBackgroundColor = schemeToEdit.onBackground;
      Brightness brightness = schemeToEdit.brightness;

      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          final currentRadius = context.watch<ChaosUIState>().chaosRadius;
          void setScheme() {
            AntiiQColorScheme newCustomScheme = AntiiQColorScheme(
              primary: primaryColor,
              onPrimary: onPrimaryColor,
              secondary: secondaryColor,
              onSecondary: onSecondaryColor,
              background: backgroundColor,
              onBackground: onBackgroundColor,
              error: generalErrorColor,
              onError: generalOnErrorColor,
              surface: surfaceColor,
              onSurface: onSurfaceColor,
              brightness: brightness,
              colorSchemeType: ColorSchemeType.custom,
            );
            setCustomTheme(newCustomScheme);
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          }

          void updateEditedColor(String name, Color value) {
            Color contrastColor =
                value.computeLuminance() >= 0.5 ? Colors.black : Colors.white;
            setState(() {
              switch (name) {
                case "primary":
                  primaryColor = value;
                  onPrimaryColor = contrastColor;
                  break;
                case "secondary":
                  secondaryColor = value;
                  onSecondaryColor = contrastColor;
                  break;
                case "surface":
                  surfaceColor = value;
                  onSurfaceColor = contrastColor;
                  break;
                case "background":
                  backgroundColor = value;
                  onBackgroundColor = contrastColor;
                  brightness = contrastColor == Colors.white
                      ? Brightness.dark
                      : Brightness.light;
                  break;
              }
            });
          }

          void showColorPickDialog(String name, Color pickerColor) {
            showDialog(
              context: context,
              builder: (context) {
                return Dialog(
                  backgroundColor:
                      AntiiQTheme.of(context).colorScheme.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(currentRadius),
                    side: BorderSide(
                      color: AntiiQTheme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(chaosBasePadding * 2),
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(chaosBasePadding),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: AntiiQTheme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Text(
                            name.toUpperCase(),
                            style: TextStyle(
                              color:
                                  AntiiQTheme.of(context).colorScheme.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            child: ColorPicker(
                              enableShadesSelection: true,
                              enableTonalPalette: false,
                              height: 30,
                              width: 30,
                              showColorCode: true,
                              colorCodeReadOnly: true,
                              colorCodeHasColor: true,
                              color: pickerColor,
                              padding: EdgeInsets.zero,
                              copyPasteBehavior:
                                  const ColorPickerCopyPasteBehavior(
                                copyButton: true,
                                pasteButton: true,
                              ),
                              pickersEnabled: const <ColorPickerType, bool>{
                                ColorPickerType.wheel: true,
                                ColorPickerType.primary: false,
                                ColorPickerType.accent: false,
                              },
                              onColorChanged: (color) {
                                updateEditedColor(name, color);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            width: double.infinity,
                            padding:
                                const EdgeInsets.all(chaosBasePadding * 1.5),
                            decoration: BoxDecoration(
                              color:
                                  AntiiQTheme.of(context).colorScheme.primary,
                              border: Border.all(
                                color: AntiiQTheme.of(context)
                                    .colorScheme
                                    .onPrimary
                                    .withValues(alpha: 0.3),
                                width: 1,
                              ),
                              borderRadius:
                                  BorderRadius.circular(currentRadius - 6),
                            ),
                            child: Center(
                              child: Text(
                                'DONE',
                                style: TextStyle(
                                  color: AntiiQTheme.of(context)
                                      .colorScheme
                                      .onPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: AntiiQTheme.of(context).colorScheme.background,
              border: Border(
                top: BorderSide(
                  color: AntiiQTheme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(currentRadius)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(chaosBasePadding * 2),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AntiiQTheme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'CUSTOM THEME',
                        style: TextStyle(
                          color: AntiiQTheme.of(context).colorScheme.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AntiiQTheme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.5),
                              width: 1,
                            ),
                            borderRadius:
                                BorderRadius.circular(currentRadius - 4),
                          ),
                          child: Icon(
                            Icons.close,
                            color: AntiiQTheme.of(context).colorScheme.primary,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(chaosBasePadding * 2),
                    child: Column(
                      children: [
                        _ColorRow(
                          label: 'PRIMARY',
                          color: primaryColor,
                          onColor: onPrimaryColor,
                          onTap: () =>
                              showColorPickDialog("primary", primaryColor),
                        ),
                        const SizedBox(height: 12),
                        _ColorRow(
                          label: 'SECONDARY',
                          color: secondaryColor,
                          onColor: onSecondaryColor,
                          onTap: () =>
                              showColorPickDialog("secondary", secondaryColor),
                        ),
                        const SizedBox(height: 12),
                        _ColorRow(
                          label: 'SURFACE',
                          color: surfaceColor,
                          onColor: onSurfaceColor,
                          onTap: () =>
                              showColorPickDialog("surface", surfaceColor),
                        ),
                        const SizedBox(height: 12),
                        _ColorRow(
                          label: 'BACKGROUND',
                          color: backgroundColor,
                          onColor: onBackgroundColor,
                          onTap: () => showColorPickDialog(
                              "background", backgroundColor),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(chaosBasePadding * 2),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      setScheme();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(chaosBasePadding * 2),
                      decoration: BoxDecoration(
                        color: AntiiQTheme.of(context).colorScheme.primary,
                        border: Border.all(
                          color: AntiiQTheme.of(context)
                              .colorScheme
                              .onPrimary
                              .withValues(alpha: 0.3),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(currentRadius - 4),
                      ),
                      child: Center(
                        child: Text(
                          'APPLY',
                          style: TextStyle(
                            color:
                                AntiiQTheme.of(context).colorScheme.onPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _ColorRow extends StatelessWidget {
  final String label;
  final Color color;
  final Color onColor;
  final VoidCallback onTap;

  const _ColorRow({
    required this.label,
    required this.color,
    required this.onColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentRadius = context.watch<ChaosUIState>().chaosRadius;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(
            color: onColor.withValues(alpha: 0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(currentRadius - 4),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 12,
              top: 8,
              child: Text(
                label,
                style: TextStyle(
                  color: onColor.withValues(alpha: 0.6),
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
            Center(
              child: Text(
                color.value.toRadixString(16).toUpperCase().padLeft(8, '0'),
                style: TextStyle(
                  color: onColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
