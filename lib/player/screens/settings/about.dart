import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/screens/settings/changelog.dart';
import 'package:antiiq/player/screens/settings/changelog_data.dart';
import 'package:antiiq/player/screens/settings/links.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:flutter/material.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';

class About extends StatelessWidget {
  const About({
    super.key,
  });

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
              child: Icon(
                RemixIcon.information,
                color: AntiiQTheme.of(context).colorScheme.primary,
                size: 30,
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
                Image.asset(
                  logoImage,
                  height: 150,
                  width: 150,
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    "About",
                    style: TextStyle(
                        color: AntiiQTheme.of(context).colorScheme.primary,
                        fontSize: 30),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                CustomCard(
                  theme: AntiiQTheme.of(context).cardThemes.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Text(
                            "AntiiQ is an Open Source Music Player for Music Collectors and Enthusiasts, built with Flutter.",
                            style: TextStyle(
                              color: AntiiQTheme.of(context).colorScheme.onSurface,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        CustomCard(
                          theme: AntiiQTheme.of(context).cardThemes.background,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  "Developer:",
                                  style: TextStyle(
                                    color:
                                        AntiiQTheme.of(context).colorScheme.primary,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  "Cole Blvck",
                                  style: TextStyle(
                                    color:
                                        AntiiQTheme.of(context).colorScheme.secondary,
                                    fontSize: 18,
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        openLink(emailUri);
                                      },
                                      icon: Icon(
                                        RemixIcon.mail,
                                        color: AntiiQTheme.of(context).colorScheme.onBackground,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        openLink(githubUri);
                                      },
                                      icon: Icon(
                                        RemixIcon.github,
                                        color: AntiiQTheme.of(context).colorScheme.onBackground,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        openLink(twitterUri);
                                      },
                                      icon: Icon(
                                        RemixIcon.twitter_x,
                                        color: AntiiQTheme.of(context).colorScheme.onBackground,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                CustomCard(
                  theme: AntiiQTheme.of(context).cardThemes.primary,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5.0),
                          child: Text(
                            "Changelog:",
                            style: TextStyle(
                              color: AntiiQTheme.of(context).colorScheme.onPrimary,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Text(
                            "Latest:",
                            style: TextStyle(
                              color: AntiiQTheme.of(context).colorScheme.onPrimary,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        CustomCard(
                          theme: AntiiQTheme.of(context).cardThemes.surface,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  versions[0].version,
                                  style: TextStyle(
                                    color:
                                        AntiiQTheme.of(context).colorScheme.onSurface,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  "Codename: ${versions[0].title}",
                                  style: TextStyle(
                                    color:
                                        AntiiQTheme.of(context).colorScheme.primary,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  versions[0].date,
                                  style: TextStyle(
                                    color:
                                        AntiiQTheme.of(context).colorScheme.onSurface,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                for (String change in versions[0].changes)
                                  Text(
                                    change,
                                    style: TextStyle(
                                      color: AntiiQTheme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontSize: 15,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5.0),
                          child: CustomButton(
                            style: ButtonStyles().style1,
                            function: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const Changelog(),
                                ),
                              );
                            },
                            child: const Text(
                              "View all",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                CustomCard(
                  theme: AntiiQTheme.of(context).cardThemes.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: CustomButton(
                      style: ButtonStyles().style1,
                      function: () {
                        null;
                      },
                      child: const Text("Licenses (unavailable)"),
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

showLicenses(context) {
  showModalBottomSheet(
    enableDrag: true,
    isScrollControlled: true,
    useSafeArea: true,
    shape: AntiiQTheme.of(context).bottomSheetShape,
    context: context,
    builder: (context) => SizedBox(
      height: MediaQuery.of(context).size.height - 150,
      child: const LicensePage(),
    ),
  );
}
