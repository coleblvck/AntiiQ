import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/user_settings.dart';
import 'package:flutter/material.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';
import 'package:restart_app/restart_app.dart';

class Behaviour extends StatefulWidget {
  const Behaviour({
    super.key,
  });

  @override
  State<Behaviour> createState() => _BehaviourState();
}

rescan() async {
  antiiqState.dataIsInitialized = false;
  await antiiqState.store.put("dataInit", false);
  Restart.restartApp();
}

class _BehaviourState extends State<Behaviour> {
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
            color: AntiiQTheme.of(context).colorScheme.primary,
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(RemixIcon.arrow_left),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: Text(
                "Behaviour",
                style: AntiiQTheme.of(context)
                    .textStyles
                    .onBackgroundLargeHeader
                    .copyWith(
                  color: AntiiQTheme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AntiiQTheme.of(context).colorScheme.background,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(
                  height: 20,
                ),
                CustomCard(
                  theme: AntiiQTheme.of(context).cardThemes.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Enable/Disable Swipe Gestures on the Now Playing Screen and Mini Player:",
                          style:
                              AntiiQTheme.of(context).textStyles.onSurfaceText,
                        ),
                        Switch(
                          activeTrackColor:
                              AntiiQTheme.of(context).colorScheme.primary,
                          activeColor:
                              AntiiQTheme.of(context).colorScheme.onPrimary,
                          value: swipeGestures,
                          onChanged: (value) {
                            setState(() {
                              setSwipeGestures(value);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                CustomCard(
                  theme: AntiiQTheme.of(context).cardThemes.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Previous Button restarts current Track first:",
                          style:
                              AntiiQTheme.of(context).textStyles.onSurfaceText,
                        ),
                        Switch(
                          activeTrackColor:
                              AntiiQTheme.of(context).colorScheme.primary,
                          activeColor:
                              AntiiQTheme.of(context).colorScheme.onPrimary,
                          value: previousRestart,
                          onChanged: (value) {
                            setState(() {
                              setPreviousButtonAction(value);
                            });
                          },
                        )
                      ],
                    ),
                  ),
                ),
                CustomCard(
                  theme: AntiiQTheme.of(context).cardThemes.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Interactive Seekbar in Mini Player:",
                          style:
                              AntiiQTheme.of(context).textStyles.onSurfaceText,
                        ),
                        Switch(
                          activeTrackColor:
                              AntiiQTheme.of(context).colorScheme.primary,
                          activeColor:
                              AntiiQTheme.of(context).colorScheme.onPrimary,
                          value: interactiveMiniPlayerSeekbar,
                          onChanged: (value) {
                            setState(() {
                              interactiveSeekBarSwitch(value);
                            });
                          },
                        )
                      ],
                    ),
                  ),
                ),
                CustomCard(
                  theme: AntiiQTheme.of(context).cardThemes.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Show playing Track Duration:",
                          style:
                              AntiiQTheme.of(context).textStyles.onSurfaceText,
                        ),
                        Switch(
                          activeTrackColor:
                              AntiiQTheme.of(context).colorScheme.primary,
                          activeColor:
                              AntiiQTheme.of(context).colorScheme.onPrimary,
                          value: showTrackDuration,
                          onChanged: (value) {
                            setState(() {
                              trackDurationShowSwitch(value);
                            });
                          },
                        )
                      ],
                    ),
                  ),
                ),
                Divider(
                  color: AntiiQTheme.of(context).colorScheme.primary,
                ),
                CustomCard(
                  theme: AntiiQTheme.of(context).cardThemes.primary,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "Back button exit behaviour:",
                            style: AntiiQTheme.of(context)
                                .textStyles
                                .onPrimaryText,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color:
                                AntiiQTheme.of(context).colorScheme.background,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    if (currentQuitType != QuitType.dialog) {
                                      setQuitType("dialog");
                                      setState(() {});
                                    }
                                  },
                                  child: Card(
                                    color: currentQuitType == QuitType.dialog
                                        ? AntiiQTheme.of(context)
                                            .colorScheme
                                            .surface
                                        : Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    surfaceTintColor: Colors.transparent,
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Align(
                                        alignment: Alignment.center,
                                        child: Text(
                                          "Dialog",
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
                                    if (currentQuitType != QuitType.doubleTap) {
                                      setQuitType("doubleTap");
                                      setState(() {});
                                    }
                                  },
                                  child: Card(
                                    color: currentQuitType == QuitType.doubleTap
                                        ? AntiiQTheme.of(context)
                                            .colorScheme
                                            .surface
                                        : Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    surfaceTintColor: Colors.transparent,
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Align(
                                        alignment: Alignment.center,
                                        child: Text(
                                          "Double Tap",
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
                        )
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
