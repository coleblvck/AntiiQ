import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/utilities/user_settings.dart';
import 'package:flutter/material.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/ui/elements/ui_colours.dart';
import 'package:restart_app/restart_app.dart';

class UserInterface extends StatefulWidget {
  const UserInterface({
    super.key,
  });
  @override
  State<UserInterface> createState() => _UserInterfaceState();
}

class _UserInterfaceState extends State<UserInterface> {
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
            color: Theme.of(context).colorScheme.secondary,
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(RemixIcon.arrow_left),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: Icon(
                RemixIcon.magic,
                color: Theme.of(context).colorScheme.secondary,
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
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    "Colours",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: 30,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Text(
                  "You will need to restart application for colours to apply properly.",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: CustomButton(
                    style: ButtonStyles().style2,
                    function: () {
                      Restart.restartApp();
                    },
                    child: const Text("Restart App"),
                  ),
                ),
                CustomCard(
                  theme: CardThemes().settingsItemTheme.copyWith(
                        color: Theme.of(context).colorScheme.surface,
                      ),
                  child: Column(
                    children: [
                      for (String theme in customThemes.keys)
                        CustomCard(
                          theme: CardThemes().settingsItemTheme.copyWith(
                                color: customThemes[theme]!.background,
                              ),
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Text(
                                        theme,
                                        style: TextStyle(
                                          color: customThemes[theme]!
                                              .onBackground,
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          height: 20,
                                          width: 20,
                                          color: customThemes[theme]!.primary,
                                        ),
                                        Container(
                                          height: 20,
                                          width: 20,
                                          color:
                                              customThemes[theme]!.secondary,
                                        ),
                                        Container(
                                          height: 20,
                                          width: 20,
                                          color: customThemes[theme]!.surface,
                                        ),
                                        Container(
                                          height: 20,
                                          width: 20,
                                          color:
                                              customThemes[theme]!.background,
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                                CustomButton(
                                  style: ButtonStyles().style1.copyWith(
                                        backgroundColor:
                                            MaterialStatePropertyAll(
                                          customThemes[theme]!.secondary,
                                        ),
                                        foregroundColor:
                                            MaterialStatePropertyAll(
                                          customThemes[theme]!.onSecondary,
                                        ),
                                      ),
                                  function: () {
                                    changeTheme(theme);
                                  },
                                  child: const Text("Use This Theme"),
                                ),
                              ],
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
      ),
    );
  }
}
