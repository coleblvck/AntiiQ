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
              child: Text(
                "Settings",
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary, fontSize: 50),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const UserInterface(),
                      ),
                    );
                  },
                  child: CustomCard(
                    theme: CardThemes().settingsItemTheme,
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: SizedBox(
                        height: 80,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Icon(
                              RemixIcon.magic,
                              color: Theme.of(context).colorScheme.secondary,
                              size: 30,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "Interface",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                                fontSize: 30,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const Library(),
                      ),
                    );
                  },
                  child: CustomCard(
                    theme: CardThemes().surfaceColor,
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: SizedBox(
                        height: 80,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Icon(
                              RemixIcon.folder,
                              color: Theme.of(context).colorScheme.onSurface,
                              size: 30,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "Library",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 30,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const Behaviour(),
                      ),
                    );
                  },
                  child: CustomCard(
                    theme: CardThemes().settingsItemTheme,
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: SizedBox(
                        height: 80,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Icon(
                              RemixIcon.play,
                              color: Theme.of(context).colorScheme.primary,
                              size: 30,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "Behaviour",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 30,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const BackupRestore(),
                      ),
                    );
                  },
                  child: CustomCard(
                    theme: CardThemes().surfaceColor,
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: SizedBox(
                        height: 80,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Icon(
                              RemixIcon.save_3,
                              color: Theme.of(context).colorScheme.onSurface,
                              size: 30,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "Backup & Restore",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 30,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const About(),
                      ),
                    );
                  },
                  child: CustomCard(
                    theme: CardThemes().primaryColor,
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: SizedBox(
                        height: 80,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Icon(
                              RemixIcon.information,
                              color: Theme.of(context).colorScheme.onPrimary,
                              size: 30,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "About",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 30,
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
