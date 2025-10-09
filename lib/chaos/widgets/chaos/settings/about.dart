import 'package:antiiq/chaos/chaos_global_constants.dart';
import 'package:chaos_ui/chaos_rotation.dart';
import 'package:antiiq/chaos/chaos_ui_state.dart';
import 'package:antiiq/chaos/page_manager.dart';
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/chaos/widgets/chaos/settings/changelog.dart';
import 'package:antiiq/player/screens/settings/changelog_data.dart';
import 'package:antiiq/player/screens/settings/links.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';

class About extends StatelessWidget {
  const About({super.key});

  @override
  Widget build(BuildContext context) {
    final pageManagerController = ChaosPageManagerNavigator.of(context);
    final chaosUIState = context.watch<ChaosUIState>();
    final outerRadius = chaosUIState.getAdjustedRadius(2);
    final innerRadius = chaosUIState.getAdjustedRadius(4);

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(chaosBasePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo/branding
            Container(
              padding: const EdgeInsets.all(chaosBasePadding * 3),
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
              child: Column(
                children: [
                  Image.asset(
                    logoImage,
                    height: 120,
                    width: 120,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ANTIIQ',
                    style: TextStyle(
                      color: AntiiQTheme.of(context).colorScheme.primary,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: chaosBasePadding),

            // Description
            _SettingContainer(
              child: Text(
                'An Open Source Music Player for Music Collectors and Enthusiasts, built with Flutter.',
                style: TextStyle(
                  color: AntiiQTheme.of(context).colorScheme.onBackground,
                  fontSize: 14,
                  height: 1.5,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: chaosBasePadding),

            // Developer info
            _SettingContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DEVELOPER',
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
                  const SizedBox(height: chaosBasePadding),
                  Text(
                    'Cole Blvck',
                    style: TextStyle(
                      color: AntiiQTheme.of(context).colorScheme.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: chaosBasePadding * 1.5),
                  Row(
                    children: [
                      _SocialButton(
                        icon: RemixIcon.mail,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          openLink(emailUri);
                        },
                      ),
                      const SizedBox(width: chaosBasePadding),
                      _SocialButton(
                        icon: RemixIcon.github,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          openLink(githubUri);
                        },
                      ),
                      const SizedBox(width: chaosBasePadding),
                      _SocialButton(
                        icon: RemixIcon.twitter_x,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          openLink(twitterUri);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: chaosBasePadding * 2),

            // Changelog section
            const _SectionDivider(label: 'CHANGELOG'),

            const SizedBox(height: chaosBasePadding),

            _SettingContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
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
                      const SizedBox(width: chaosBasePadding),
                      Text(
                        versions[0].version,
                        style: TextStyle(
                          color: AntiiQTheme.of(context).colorScheme.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: chaosBasePadding),
                  Text(
                    versions[0].title,
                    style: TextStyle(
                      color: AntiiQTheme.of(context).colorScheme.onBackground,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: chaosBasePadding / 2),
                  Text(
                    versions[0].date,
                    style: TextStyle(
                      color: AntiiQTheme.of(context)
                          .colorScheme
                          .onBackground
                          .withValues(alpha: 0.6),
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: chaosBasePadding * 2),
                  Container(
                    padding: const EdgeInsets.all(chaosBasePadding * 1.5),
                    decoration: BoxDecoration(
                      color: AntiiQTheme.of(context)
                          .colorScheme
                          .surface
                          .withValues(alpha: 0.3),
                      border: Border.all(
                        color: AntiiQTheme.of(context)
                            .colorScheme
                            .surface
                            .withValues(alpha: 0.5),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(innerRadius),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < versions[0].changes.length; i++)
                          Padding(
                            padding: EdgeInsets.only(
                                bottom:
                                    i < versions[0].changes.length - 1 ? 8 : 0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: AntiiQTheme.of(context)
                                        .colorScheme
                                        .secondary,
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    versions[0].changes[i],
                                    style: TextStyle(
                                      color: AntiiQTheme.of(context)
                                          .colorScheme
                                          .onBackground
                                          .withValues(alpha: 0.8),
                                      fontSize: 12,
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
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      pageManagerController?.push(
                        const Changelog(),
                        title: "CHANGELOG",
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AntiiQTheme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.5),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(innerRadius),
                      ),
                      child: Center(
                        child: Text(
                          'VIEW ALL',
                          style: TextStyle(
                            color: AntiiQTheme.of(context).colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: chaosBasePadding),

            // Licenses button
            _SettingContainer(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  // Placeholder for licenses
                },
                child: Container(
                  padding: const EdgeInsets.all(chaosBasePadding * 1.5),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AntiiQTheme.of(context)
                          .colorScheme
                          .surface
                          .withValues(alpha: 0.5),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(innerRadius),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        RemixIcon.file_list,
                        color: AntiiQTheme.of(context)
                            .colorScheme
                            .onBackground
                            .withValues(alpha: 0.5),
                        size: 16,
                      ),
                      const SizedBox(width: chaosBasePadding),
                      Text(
                        'LICENSES',
                        style: TextStyle(
                          color: AntiiQTheme.of(context)
                              .colorScheme
                              .onBackground
                              .withValues(alpha: 0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: chaosBasePadding / 2),
                      Text(
                        '(UNAVAILABLE)',
                        style: TextStyle(
                          color: AntiiQTheme.of(context)
                              .colorScheme
                              .onBackground
                              .withValues(alpha: 0.3),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingContainer extends StatelessWidget {
  final Widget child;

  const _SettingContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    final chaosUIState = context.watch<ChaosUIState>();
    final outerRadius = chaosUIState.getAdjustedRadius(2);
    return ChaosRotatedStatefulWidget(
      child: Container(
        padding: const EdgeInsets.all(chaosBasePadding * 2),
        decoration: BoxDecoration(
          color: AntiiQTheme.of(context)
              .colorScheme
              .surface
              .withValues(alpha: 0.2),
          border: Border.all(
            color: AntiiQTheme.of(context)
                .colorScheme
                .surface
                .withValues(alpha: 0.5),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(outerRadius),
        ),
        child: child,
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  final String label;

  const _SectionDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: AntiiQTheme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: AntiiQTheme.of(context).colorScheme.primary,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            color: AntiiQTheme.of(context)
                .colorScheme
                .primary
                .withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SocialButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final chaosUIState = context.watch<ChaosUIState>();
    final innerRadius = chaosUIState.getAdjustedRadius(4);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AntiiQTheme.of(context)
              .colorScheme
              .primary
              .withValues(alpha: 0.1),
          border: Border.all(
            color: AntiiQTheme.of(context)
                .colorScheme
                .primary
                .withValues(alpha: 0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(innerRadius),
        ),
        child: Icon(
          icon,
          color: AntiiQTheme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
    );
  }
}
