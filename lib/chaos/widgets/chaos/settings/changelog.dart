import 'package:antiiq/chaos/chaos_global_constants.dart';
import 'package:antiiq/chaos/chaos_ui_state.dart';
import 'package:antiiq/chaos/utilities/angle.dart';
import 'package:chaos_ui/chaos_rotation.dart';
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/screens/settings/changelog_data.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Changelog extends StatelessWidget {
  const Changelog({super.key});

  @override
  Widget build(BuildContext context) {
    final chaosUIState = context.watch<ChaosUIState>();
    final outerRadius = chaosUIState.getAdjustedRadius(2);
    return SingleChildScrollView(
      child: Container(
        color: AntiiQTheme.of(context).colorScheme.background,
        padding: const EdgeInsets.all(chaosBasePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo header
            Container(
              padding: const EdgeInsets.all(chaosBasePadding * 3),
              margin: const EdgeInsets.only(bottom: chaosBasePadding),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AntiiQTheme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.3),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(outerRadius),
              ),
              child: Image.asset(
                logoImage,
                height: 80,
                width: 80,
              ),
            ),

            // Version cards
            for (int i = 0; i < versions.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: chaosBasePadding),
                child: _VersionCard(
                  version: versions[i],
                  isLatest: i == 0,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VersionCard extends StatelessWidget {
  final Version version;
  final bool isLatest;

  const _VersionCard({
    required this.version,
    required this.isLatest,
  });

  @override
  Widget build(BuildContext context) {
    final chaosUIState = context.watch<ChaosUIState>();
    final chaosLevel = chaosUIState.chaosLevel;
    final outerRadius = chaosUIState.getAdjustedRadius(2);
    final innerRadius = chaosUIState.getAdjustedRadius(4);
    return ChaosRotatedStatefulWidget(
      maxAngle: getAnglePercentage(0.1, chaosLevel),
      child: Container(
        decoration: BoxDecoration(
          color:
              AntiiQTheme.of(context).colorScheme.surface.withValues(alpha: 0.2),
          border: Border.all(
            color: isLatest
                ? AntiiQTheme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.5)
                : AntiiQTheme.of(context)
                    .colorScheme
                    .surface
                    .withValues(alpha: 0.5),
            width: isLatest ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(outerRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(chaosBasePadding * 2),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AntiiQTheme.of(context)
                        .colorScheme
                        .surface
                        .withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isLatest)
                        Container(
                          margin: const EdgeInsets.only(right: chaosBasePadding),
                          padding: const EdgeInsets.symmetric(
                              horizontal: chaosBasePadding,
                              vertical: chaosBasePadding / 2),
                          decoration: BoxDecoration(
                            color: AntiiQTheme.of(context).colorScheme.secondary,
                            borderRadius: BorderRadius.circular(innerRadius),
                          ),
                          child: Text(
                            'LATEST',
                            style: TextStyle(
                              color:
                                  AntiiQTheme.of(context).colorScheme.onSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      Text(
                        version.version,
                        style: TextStyle(
                          color: AntiiQTheme.of(context).colorScheme.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: chaosBasePadding),
                  Text(
                    version.title,
                    style: TextStyle(
                      color: AntiiQTheme.of(context).colorScheme.onBackground,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: chaosBasePadding / 2),
                  Text(
                    version.date,
                    style: TextStyle(
                      color: AntiiQTheme.of(context)
                          .colorScheme
                          .onBackground
                          .withValues(alpha: 0.6),
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
      
            // Changes
            Padding(
              padding: const EdgeInsets.all(chaosBasePadding * 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CHANGES',
                    style: TextStyle(
                      color: AntiiQTheme.of(context)
                          .colorScheme
                          .onBackground
                          .withValues(alpha: 0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: chaosBasePadding * 1.5),
                  for (int i = 0; i < version.changes.length; i++)
                    Padding(
                      padding: EdgeInsets.only(
                          bottom: i < version.changes.length - 1
                              ? chaosBasePadding * 1.5
                              : 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color:
                                  AntiiQTheme.of(context).colorScheme.secondary,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(width: chaosBasePadding * 1.5),
                          Expanded(
                            child: Text(
                              version.changes[i],
                              style: TextStyle(
                                color: AntiiQTheme.of(context)
                                    .colorScheme
                                    .onBackground
                                    .withValues(alpha: 0.9),
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
