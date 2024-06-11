import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/screens/settings/about.dart';
import 'package:antiiq/player/screens/settings/backup_restore.dart';
import 'package:antiiq/player/screens/settings/behaviour.dart';
import 'package:antiiq/player/screens/settings/library.dart';
import 'package:antiiq/player/screens/settings/user_interface.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:flutter/material.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';

class Settings extends StatelessWidget {
  const Settings({
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
              child: Text(
                "Settings",
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
        body: SingleChildScrollView(
          child: Column(
            children: [
              for (var i in settingsPages(context).entries)
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => i.value["page"],
                        ),
                      );
                    },
                    child: CustomCard(
                      theme: i.value["cardTheme"],
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: SizedBox(
                          height: 70,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Icon(
                                i.value["icon"],
                                color: i.value["color"],
                                size: 30,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  i.key,
                                  style: AntiiQTheme.of(context)
                                      .textStyles
                                      .onBackgroundLargeHeader
                                      .copyWith(
                                        color: i.value["color"],
                                      ),
                                ),
                              ),
                            ],
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
    );
  }
}

settingsPages(context) => {
      "Interface": {
        "color": AntiiQTheme.of(context).colorScheme.secondary,
        "cardTheme": AntiiQTheme.of(context).cardThemes.background,
        "icon": RemixIcon.magic,
        "page": const UserInterface(),
      },
      "Library": {
        "color": AntiiQTheme.of(context).colorScheme.onSurface,
        "cardTheme": AntiiQTheme.of(context).cardThemes.surface,
        "icon": RemixIcon.folder,
        "page": const Library(),
      },
      "Behaviour": {
        "color": AntiiQTheme.of(context).colorScheme.primary,
        "cardTheme": AntiiQTheme.of(context).cardThemes.background,
        "icon": RemixIcon.play,
        "page": const Behaviour(),
      },
      "Backup/Restore": {
        "color": AntiiQTheme.of(context).colorScheme.onSurface,
        "cardTheme": AntiiQTheme.of(context).cardThemes.surface,
        "icon": RemixIcon.save_3,
        "page": const BackupRestore(),
      },
      "About": {
        "color": AntiiQTheme.of(context).colorScheme.onPrimary,
        "cardTheme": AntiiQTheme.of(context).cardThemes.primary,
        "icon": RemixIcon.information,
        "page": const About(),
      },
    };
