import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/screens/settings/changelog_data.dart';
import 'package:flutter/material.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';

class Changelog extends StatelessWidget {
  const Changelog({
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
                    "Changelog",
                    style: TextStyle(
                        color: AntiiQTheme.of(context).colorScheme.primary,
                        fontSize: 30),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                for (Version version in versions)
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
                              "Code Name: ${version.title}",
                              style: TextStyle(
                                color: AntiiQTheme.of(context)
                                    .colorScheme
                                    .onSurface,
                                fontSize: 20,
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
                                    "Version: ${version.version}",
                                    style: TextStyle(
                                      color: AntiiQTheme.of(context)
                                          .colorScheme
                                          .primary,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Text(
                                    version.date,
                                    style: TextStyle(
                                      color: AntiiQTheme.of(context)
                                          .colorScheme
                                          .secondary,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10.0),
                                    child: Text(
                                      "changes",
                                      style: TextStyle(
                                        decorationStyle:
                                            TextDecorationStyle.solid,
                                        decoration: TextDecoration.underline,
                                        decorationColor: AntiiQTheme.of(context)
                                            .colorScheme
                                            .onBackground,
                                        fontSize: 20,
                                        color: AntiiQTheme.of(context)
                                            .colorScheme
                                            .onBackground,
                                      ),
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      for (String change in version.changes)
                                        Text(
                                          change,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: AntiiQTheme.of(context)
                                                .colorScheme
                                                .onBackground,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
