import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/utilities/user_settings.dart';
import 'package:flutter/material.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:restart_app/restart_app.dart';

class Behaviour extends StatefulWidget {
  const Behaviour({
    super.key,
  });

  @override
  State<Behaviour> createState() => _BehaviourState();
}

rescan() async {
  dataIsInitialized = false;
  await antiiqStore.put("dataInit", false);
  Restart.restartApp();
}

class _BehaviourState extends State<Behaviour> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 75,
          backgroundColor: Theme.of(context).colorScheme.background,
          elevation: 2,
          surfaceTintColor: Colors.transparent,
          shadowColor: Theme.of(context).colorScheme.onBackground,
          leading: IconButton(
            iconSize: 50,
            color: Theme.of(context).colorScheme.primary,
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(RemixIcon.arrow_left),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: Icon(
                RemixIcon.play,
                color: Theme.of(context).colorScheme.primary,
                size: 30,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.background,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    "Behaviour",
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 30),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                CustomCard(
                  theme: CardThemes().surfaceColor,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                            "Enable/Disable Swipe Gestures on the Now Playing Screen and Mini Player:"),
                        Switch(
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
                  theme: CardThemes().surfaceColor,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Previous Button restarts current Track first:"),
                        Switch(
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
                  theme: CardThemes().surfaceColor,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Interactive Seekbar in Mini Player:"),
                        Switch(
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
                  theme: CardThemes().surfaceColor,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Show playing Track Duration:"),
                        Switch(
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
