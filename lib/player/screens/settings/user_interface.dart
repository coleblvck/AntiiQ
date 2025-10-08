import 'package:antiiq/chaos/chaos_ui_state.dart';
import 'package:antiiq/home_widget/home_widget_manager.dart';
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/ui/elements/ui_colours.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/settings/user_settings.dart';
import 'package:antiiq/player/widgets/ui/antiiq_slider.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';
import 'package:antiiq/player/utilities/settings/theme_settings.dart';
import 'package:home_widget/home_widget.dart';

class UserInterface extends StatefulWidget {
  const UserInterface({
    super.key,
  });
  @override
  State<UserInterface> createState() => _UserInterfaceState();
}

class _UserInterfaceState extends State<UserInterface> {
  bool _coverArtBackground = true;
  int _backgroundOpacity = 50;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWidgetSettings();
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
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 75,
          backgroundColor: AntiiQTheme.of(context).colorScheme.background,
          elevation: settingsPageAppBarElevation,
          surfaceTintColor: Colors.transparent,
          shadowColor: AntiiQTheme.of(context).colorScheme.onBackground,
          leading: IconButton(
            iconSize: settingsPageAppBarIconButtonSize,
            color: AntiiQTheme.of(context).colorScheme.secondary,
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(RemixIcon.arrow_left),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: Text(
                "Interface",
                style: AntiiQTheme.of(context)
                    .textStyles
                    .onBackgroundLargeHeader
                    .copyWith(
                      color: AntiiQTheme.of(context).colorScheme.secondary,
                    ),
              ),
            ),
          ],
        ),
        backgroundColor: AntiiQTheme.of(context).colorScheme.background,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 20,
                ),
              ),
              ChaosUIStatusSetting(
                setPageState: setState,
              ),
              StatusbarModeSetting(
                setPageState: setState,
              ),
              UiRoundnessSetting(
                setPageState: setState,
              ),
              CoverArtFitSetting(
                setPageState: setState,
              ),
              WidgetSettingsSection(
                coverArtBackground: _coverArtBackground,
                backgroundOpacity: _backgroundOpacity,
                isLoading: _isLoading,
                onCoverArtBackgroundChanged: (value) {
                  setState(() {
                    _coverArtBackground = value;
                  });
                },
                onBackgroundOpacityChanged: (value) {
                  setState(() {
                    _backgroundOpacity = value.round();
                  });
                },
              ),
              const ThemeSettingsTitle(),
              DynamicThemeSetting(
                setPageState: setState,
              ),
              const SettingsThemeGrid(),
            ],
          ),
        ),
      ),
    );
  }
}

class WidgetSettingsSection extends StatelessWidget {
  final bool coverArtBackground;
  final int backgroundOpacity;
  final bool isLoading;
  final Function(bool) onCoverArtBackgroundChanged;
  final Function(double) onBackgroundOpacityChanged;

  const WidgetSettingsSection({
    super.key,
    required this.coverArtBackground,
    required this.backgroundOpacity,
    required this.isLoading,
    required this.onCoverArtBackgroundChanged,
    required this.onBackgroundOpacityChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SliverToBoxAdapter(
        child: CustomCard(
          theme: AntiiQTheme.of(context).cardThemes.surface,
          child: const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: CustomCard(
        theme: AntiiQTheme.of(context).cardThemes.surface,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Widget Settings:",
                  style: AntiiQTheme.of(context).textStyles.onSurfaceText,
                ),
              ),
              CustomCard(
                theme: AntiiQTheme.of(context).cardThemes.background,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Cover Art Background",
                            style: AntiiQTheme.of(context)
                                .textStyles
                                .onBackgroundText,
                          ),
                          Switch(
                            activeTrackColor:
                                AntiiQTheme.of(context).colorScheme.secondary,
                            activeColor:
                                AntiiQTheme.of(context).colorScheme.onSecondary,
                            value: coverArtBackground,
                            onChanged: onCoverArtBackgroundChanged,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Background Opacity: ${backgroundOpacity.round()}%",
                        style: AntiiQTheme.of(context).textStyles.onSurfaceText,
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 20,
                        child: AntiiQSlider(
                          activeTrackColor:
                              AntiiQTheme.of(context).colorScheme.secondary,
                          inactiveTrackColor:
                              AntiiQTheme.of(context).colorScheme.primary,
                          thumbColor:
                              AntiiQTheme.of(context).colorScheme.onPrimary,
                          thumbWidth: 30.0,
                          thumbHeight: 16.0,
                          thumbBorderRadius: generalRadius / 2,
                          trackHeight: 20.0,
                          trackBorderRadius: generalRadius - 6,
                          orientation: Axis.horizontal,
                          selectByTap: true,
                          value: backgroundOpacity.toDouble(),
                          min: 0,
                          max: 100,
                          onChanged: onBackgroundOpacityChanged,
                        ),
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        style: AntiiQTheme.of(context).buttonStyles.style2,
                        function: () {
                          HomeWidgetManager.updateVisuals(
                              backgroundOpacity, coverArtBackground);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Widget settings updated',
                                style: TextStyle(
                                  color: AntiiQTheme.of(context)
                                      .colorScheme
                                      .onPrimary,
                                ),
                              ),
                              backgroundColor:
                                  AntiiQTheme.of(context).colorScheme.primary,
                            ),
                          );
                        },
                        child: const Text("Apply to Widgets"),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PrimaryDividerAdapter extends StatelessWidget {
  const PrimaryDividerAdapter({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Divider(
        color: AntiiQTheme.of(context).colorScheme.primary,
      ),
    );
  }
}

class CoverArtFitSetting extends StatelessWidget {
  const CoverArtFitSetting({
    super.key,
    required this.setPageState,
  });

  final void Function(void Function()) setPageState;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: CustomCard(
        theme: AntiiQTheme.of(context).cardThemes.secondary,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Cover Art Fit:",
                  style: AntiiQTheme.of(context).textStyles.onSecondaryText,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AntiiQTheme.of(context).colorScheme.surface,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (currentCoverArtFit != ArtFit.cover) {
                            changeCoverArtFit("cover");
                            setPageState(() {});
                          }
                        },
                        child: Card(
                          color: currentCoverArtFit == ArtFit.cover
                              ? AntiiQTheme.of(context).colorScheme.background
                              : Colors.transparent,
                          shadowColor: Colors.transparent,
                          surfaceTintColor: Colors.transparent,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(
                                "Cover",
                                style: TextStyle(
                                  color: AntiiQTheme.of(context)
                                      .colorScheme
                                      .primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (currentCoverArtFit != ArtFit.contain) {
                            changeCoverArtFit("contain");
                            setPageState(() {});
                          }
                        },
                        child: Card(
                          color: currentCoverArtFit == ArtFit.contain
                              ? AntiiQTheme.of(context).colorScheme.background
                              : Colors.transparent,
                          shadowColor: Colors.transparent,
                          surfaceTintColor: Colors.transparent,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(
                                "Contain",
                                style: TextStyle(
                                  color: AntiiQTheme.of(context)
                                      .colorScheme
                                      .primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UiRoundnessSetting extends StatelessWidget {
  const UiRoundnessSetting({
    super.key,
    required this.setPageState,
  });

  final void Function(void Function()) setPageState;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: CustomCard(
        theme: AntiiQTheme.of(context).cardThemes.surface,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                "UI Roundness",
                style: AntiiQTheme.of(context)
                    .textStyles
                    .onBackgroundLargeHeader
                    .copyWith(
                      color: AntiiQTheme.of(context).colorScheme.primary,
                    ),
              ),
            ),
            CustomCard(
              theme: AntiiQTheme.of(context).cardThemes.background,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Radius: ${generalRadius.round()}",
                      style: AntiiQTheme.of(context).textStyles.onSurfaceText,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    SizedBox(
                      height: 20,
                      child: AntiiQSlider(
                          activeTrackColor:
                              AntiiQTheme.of(context).colorScheme.secondary,
                          inactiveTrackColor:
                              AntiiQTheme.of(context).colorScheme.primary,
                          thumbColor:
                              AntiiQTheme.of(context).colorScheme.onPrimary,
                          thumbWidth: 30.0,
                          thumbHeight: 16.0,
                          thumbBorderRadius: generalRadius / 2,
                          trackHeight: 20.0,
                          trackBorderRadius: generalRadius - 6,
                          orientation: Axis.horizontal,
                          selectByTap: true,
                          value: generalRadius,
                          min: 0,
                          max: 25,
                          onChanged: (value) => {
                                setPageState(() {
                                  setGeneralRadius(value);
                                })
                              }),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DynamicThemeSetting extends StatelessWidget {
  const DynamicThemeSetting({
    super.key,
    required this.setPageState,
  });

  final void Function(void Function()) setPageState;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: CustomCard(
        theme: AntiiQTheme.of(context).cardThemes.secondary,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Dynamic Theme",
                      style: AntiiQTheme.of(context)
                          .textStyles
                          .onSecondaryText
                          .copyWith(fontSize: 20),
                    ),
                    Switch(
                      activeTrackColor:
                          AntiiQTheme.of(context).colorScheme.primary,
                      activeColor:
                          AntiiQTheme.of(context).colorScheme.onPrimary,
                      value: dynamicThemeEnabled,
                      onChanged: (value) {
                        setPageState(
                          () {
                            switchDynamicTheme(value);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: AntiiQTheme.of(context).colorScheme.surface,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (dynamicColorBrightness != Brightness.dark) {
                              changeDynamicColorBrightness("dark");
                              setPageState(() {});
                            }
                          },
                          child: Card(
                            color: dynamicColorBrightness == Brightness.dark
                                ? AntiiQTheme.of(context).colorScheme.background
                                : Colors.transparent,
                            shadowColor: Colors.transparent,
                            surfaceTintColor: Colors.transparent,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  "Dark",
                                  style: TextStyle(
                                    color: AntiiQTheme.of(context)
                                        .colorScheme
                                        .primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (dynamicColorBrightness != Brightness.light) {
                              changeDynamicColorBrightness("light");
                              setPageState(() {});
                            }
                          },
                          child: Card(
                            color: dynamicColorBrightness == Brightness.light
                                ? AntiiQTheme.of(context).colorScheme.background
                                : Colors.transparent,
                            shadowColor: Colors.transparent,
                            surfaceTintColor: Colors.transparent,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  "Light",
                                  style: TextStyle(
                                    color: AntiiQTheme.of(context)
                                        .colorScheme
                                        .primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              CustomCard(
                theme: AntiiQTheme.of(context)
                    .cardThemes
                    .background
                    .copyWith(color: Colors.black),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Amoled Dark",
                        style: AntiiQTheme.of(context)
                            .textStyles
                            .onSecondaryText
                            .copyWith(
                              fontSize: 20,
                              color: Colors.white,
                            ),
                      ),
                      Switch(
                        activeTrackColor:
                            AntiiQTheme.of(context).colorScheme.primary,
                        activeColor:
                            AntiiQTheme.of(context).colorScheme.onPrimary,
                        value: dynamicAmoledEnabled,
                        onChanged: (value) {
                          setPageState(
                            () {
                              switchDynamicAmoled(value);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChaosUIStatusSetting extends StatelessWidget {
  const ChaosUIStatusSetting({
    super.key,
    required this.setPageState,
  });

  final void Function(void Function()) setPageState;

  @override
  Widget build(BuildContext context) {
    final chaosUIState = context.watch<ChaosUIState>();
    return SliverToBoxAdapter(
      child: CustomCard(
        theme: AntiiQTheme.of(context).cardThemes.primary,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "UI Mode:",
                  style: AntiiQTheme.of(context).textStyles.onPrimaryText,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AntiiQTheme.of(context).colorScheme.surface,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          chaosUIState.setChaosUIStatus(false);
                        },
                        child: Card(
                          color: !chaosUIState.chaosUIStatus
                              ? AntiiQTheme.of(context).colorScheme.background
                              : Colors.transparent,
                          shadowColor: Colors.transparent,
                          surfaceTintColor: Colors.transparent,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(
                                "Classic",
                                style: TextStyle(
                                  color: AntiiQTheme.of(context)
                                      .colorScheme
                                      .primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (!chaosUIState.chaosUIStatus) {
                            _showChaosUIConfirmationDialog(
                                context, chaosUIState);
                          } else {
                            chaosUIState.setChaosUIStatus(false);
                          }
                        },
                        child: Card(
                          color: chaosUIState.chaosUIStatus
                              ? AntiiQTheme.of(context).colorScheme.background
                              : Colors.transparent,
                          shadowColor: Colors.transparent,
                          surfaceTintColor: Colors.transparent,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(
                                "Chaos",
                                style: TextStyle(
                                  color: AntiiQTheme.of(context)
                                      .colorScheme
                                      .primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showChaosUIConfirmationDialog(
    BuildContext context, ChaosUIState chaosUIState) {
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(generalRadius),
        ),
        backgroundColor: AntiiQTheme.of(context).colorScheme.surface,
        title: Text(
          "Switch to Chaos UI?",
          style: AntiiQTheme.of(context).textStyles.onSurfaceText.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
        ),
        content: RichText(
          text: TextSpan(
            style: AntiiQTheme.of(context).textStyles.onSurfaceText,
            children: const [
              TextSpan(
                  text:
                      'Chaos UI is an experimental interface with rotated elements, '
                      'unconventional layouts, and hidden gestures. It prioritizes '
                      'aesthetics over efficiency.\n\n'),
              TextSpan(
                text:
                    'Not for daily use. Or maybe it is. You can switch back anytime in settings anyway.',
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          CustomButton(
            style: AntiiQTheme.of(context).buttonStyles.style3,
            function: () {
              Navigator.of(context).pop();
            },
            child: Text(
              "Cancel",
              style: TextStyle(
                color: AntiiQTheme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
          CustomButton(
            style: AntiiQTheme.of(context).buttonStyles.style2,
            function: () {
              chaosUIState.setChaosUIStatus(true);
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text(
              "Switch",
              style: TextStyle(
                color: AntiiQTheme.of(context).colorScheme.onSecondary,
              ),
            ),
          ),
        ],
      );
    },
  );
}

class StatusbarModeSetting extends StatelessWidget {
  const StatusbarModeSetting({
    super.key,
    required this.setPageState,
  });

  final void Function(void Function()) setPageState;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: CustomCard(
        theme: AntiiQTheme.of(context).cardThemes.primary,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Status Bar Mode:",
                  style: AntiiQTheme.of(context).textStyles.onPrimaryText,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AntiiQTheme.of(context).colorScheme.surface,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (currentStatusBarMode !=
                              StatusBarMode.defaultMode) {
                            setStatusBarMode("default");
                            setPageState(() {});
                          }
                        },
                        child: Card(
                          color: currentStatusBarMode ==
                                  StatusBarMode.defaultMode
                              ? AntiiQTheme.of(context).colorScheme.background
                              : Colors.transparent,
                          shadowColor: Colors.transparent,
                          surfaceTintColor: Colors.transparent,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(
                                "Default",
                                style: TextStyle(
                                  color: AntiiQTheme.of(context)
                                      .colorScheme
                                      .primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (currentStatusBarMode !=
                              StatusBarMode.immersiveMode) {
                            setStatusBarMode("immersive");
                            setPageState(() {});
                          }
                        },
                        child: Card(
                          color: currentStatusBarMode ==
                                  StatusBarMode.immersiveMode
                              ? AntiiQTheme.of(context).colorScheme.background
                              : Colors.transparent,
                          shadowColor: Colors.transparent,
                          surfaceTintColor: Colors.transparent,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(
                                "Immersive",
                                style: TextStyle(
                                  color: AntiiQTheme.of(context)
                                      .colorScheme
                                      .primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ThemeSettingsTitle extends StatelessWidget {
  const ThemeSettingsTitle({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: CustomCard(
        theme: AntiiQTheme.of(context).cardThemes.background,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(
            "App Theming",
            style: AntiiQTheme.of(context).textStyles.onBackgroundLargeHeader,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class SettingsThemeGrid extends StatelessWidget {
  const SettingsThemeGrid({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1,
      ),
      delegate: SliverChildListDelegate(
        [
          CustomCard(
              theme: AntiiQTheme.of(context).cardThemes.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Custom",
                    style: AntiiQTheme.of(context)
                        .textStyles
                        .onPrimaryText
                        .copyWith(fontSize: 20),
                  ),
                  CustomButton(
                    style: AntiiQTheme.of(context).buttonStyles.style3,
                    function: () {
                      customColorEditSheet(context);
                    },
                    child: const Icon(RemixIcon.magic),
                  ),
                ],
              )),
          for (String theme in customThemes.keys)
            CustomCard(
              theme: AntiiQTheme.of(context).cardThemes.background.copyWith(
                    color: customThemes[theme]!.background,
                  ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: CustomCard(
                  theme: AntiiQTheme.of(context).cardThemes.background.copyWith(
                        color: customThemes[theme]!.surface,
                      ),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          theme,
                          style: TextStyle(
                            color: customThemes[theme]!.onSurface,
                            fontSize: 15,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              height: 20,
                              width: 20,
                              color: customThemes[theme]!.primary,
                            ),
                            Container(
                              height: 20,
                              width: 20,
                              color: customThemes[theme]!.secondary,
                            ),
                            Container(
                              height: 20,
                              width: 20,
                              color: customThemes[theme]!.surface,
                            ),
                            Container(
                              height: 20,
                              width: 20,
                              color: customThemes[theme]!.background,
                            ),
                          ],
                        ),
                        CustomButton(
                          style: ButtonStyles().style1.copyWith(
                                backgroundColor: WidgetStatePropertyAll(
                                  customThemes[theme]!.primary,
                                ),
                                foregroundColor: WidgetStatePropertyAll(
                                  customThemes[theme]!.onPrimary,
                                ),
                              ),
                          function: () {
                            changeTheme(theme);
                          },
                          child: const Text("Apply"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

customColorEditSheet(context) {
  showModalBottomSheet(
    enableDrag: true,
    shape: AntiiQTheme.of(context).bottomSheetShape,
    context: context,
    backgroundColor: AntiiQTheme.of(context).colorScheme.surface,
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
        setScheme() {
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

        updateEditedColor(String name, Color value) {
          Color contrastColor =
              value.computeLuminance() >= 0.5 ? Colors.black : Colors.white;
          setState(() {
            name == "primary"
                ? {
                    primaryColor = value,
                    onPrimaryColor = contrastColor,
                  }
                : name == "secondary"
                    ? {
                        secondaryColor = value,
                        onSecondaryColor = contrastColor,
                      }
                    : name == "surface"
                        ? {
                            surfaceColor = value,
                            onSurfaceColor = contrastColor,
                          }
                        : name == "background"
                            ? {
                                backgroundColor = value,
                                onBackgroundColor = contrastColor,
                                brightness = contrastColor == Colors.white
                                    ? Brightness.dark
                                    : Brightness.light,
                              }
                            : null;
          });
        }

        showColorPickDialog(String name, Color pickerColor) {
          return showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(generalRadius),
                ),
                backgroundColor: AntiiQTheme.of(context).colorScheme.primary,
                content: SizedBox(
                  height: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.vertical -
                      150,
                  child: Column(
                    children: [
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
                      CustomButton(
                        style: AntiiQTheme.of(context).buttonStyles.style1,
                        child: const Center(
                          child: Icon(RemixIcon.arrow_down_double),
                        ),
                        function: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
                child: CustomCard(
              theme: AntiiQTheme.of(context).cardThemes.background,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Primary:",
                              style: AntiiQTheme.of(context)
                                  .textStyles
                                  .onBackgroundText,
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                showColorPickDialog("primary", primaryColor);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius:
                                      BorderRadius.circular(generalRadius),
                                ),
                                constraints: const BoxConstraints.expand(),
                                child: Center(
                                  child: Text(
                                    primaryColor.hex,
                                    style: AntiiQTheme.of(context)
                                        .textStyles
                                        .onBackgroundText
                                        .copyWith(color: onPrimaryColor),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Secondary:",
                              style: AntiiQTheme.of(context)
                                  .textStyles
                                  .onBackgroundText,
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                showColorPickDialog(
                                    "secondary", secondaryColor);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: secondaryColor,
                                  borderRadius:
                                      BorderRadius.circular(generalRadius),
                                ),
                                constraints: const BoxConstraints.expand(),
                                child: Center(
                                  child: Text(
                                    secondaryColor.hex,
                                    style: AntiiQTheme.of(context)
                                        .textStyles
                                        .onBackgroundText
                                        .copyWith(color: onSecondaryColor),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Surface:",
                              style: AntiiQTheme.of(context)
                                  .textStyles
                                  .onBackgroundText,
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                showColorPickDialog("surface", surfaceColor);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: surfaceColor,
                                  borderRadius:
                                      BorderRadius.circular(generalRadius),
                                ),
                                constraints: const BoxConstraints.expand(),
                                child: Center(
                                  child: Text(
                                    surfaceColor.hex,
                                    style: AntiiQTheme.of(context)
                                        .textStyles
                                        .onBackgroundText
                                        .copyWith(color: onSurfaceColor),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Background:",
                              style: AntiiQTheme.of(context)
                                  .textStyles
                                  .onBackgroundText,
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                showColorPickDialog(
                                    "background", backgroundColor);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: backgroundColor,
                                  borderRadius:
                                      BorderRadius.circular(generalRadius),
                                ),
                                constraints: const BoxConstraints.expand(),
                                child: Center(
                                  child: Text(
                                    backgroundColor.hex,
                                    style: AntiiQTheme.of(context)
                                        .textStyles
                                        .onBackgroundText
                                        .copyWith(color: onBackgroundColor),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: CustomButton(
                style: AntiiQTheme.of(context).buttonStyles.style2,
                function: () {
                  setScheme();
                },
                child: const Text("Apply"),
              ),
            ),
          ],
        );
      });
    },
  );
}
