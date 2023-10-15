import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/utilities/user_settings.dart';
import 'package:flutter/material.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:restart_app/restart_app.dart';
import 'package:flutter_xlider/flutter_xlider.dart';

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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                            "Minimum Track Length: $minimumTrackLength seconds"),
                        const SizedBox(
                          height: 20,
                        ),
                        SizedBox(
                          height: 20,
                          child: FlutterSlider(
                              selectByTap: true,
                              tooltip: FlutterSliderTooltip(
                                disabled: true,
                              ),
                              handlerHeight: 20,
                              handlerWidth: 5,
                              step: const FlutterSliderStep(
                                  step: 1, isPercentRange: false),
                              values: [minimumTrackLength.toDouble()],
                              min: 5,
                              max: 120,
                              handler: FlutterSliderHandler(
                                decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(5)),
                                child: Container(),
                              ),
                              foregroundDecoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(1)),
                              trackBar: FlutterSliderTrackBar(
                                inactiveTrackBar: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: Theme.of(context).colorScheme.primary,
                                  border: Border.all(
                                    width: 3,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                activeTrackBar: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                              onDragging: (handlerIndex, lowerValue,
                                      upperValue) =>
                                  {
                                    setState(() {
                                      setMinimumTrackLength(lowerValue.round());
                                    })
                                  }),
                        ),
                        CustomButton(
                          style: ButtonStyles().style1,
                          function: () {
                            rescan();
                          },
                          child: const Text("!Re-Scan Library!"),
                        ),
                      ],
                    ),
                  ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
