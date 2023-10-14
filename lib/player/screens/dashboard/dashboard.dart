//Flutter Packages
import 'package:flutter/material.dart';

//Antiiq Packages
import 'package:antiiq/player/screens/dashboard/dashboard_items.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GridView(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
      ),
      children: [
        for (var i in dashboardItems(context).entries)
          GestureDetector(
            onTap: () {
              i.value["function"]();
            },
            child: CustomCard(
              theme: CardThemes().dashboardItemTheme,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Icon(
                        i.value["icon"] as IconData,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      i.value["title"] as String,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
