import 'package:antiiq/chaos/chaos_ui_state.dart';
import 'package:chaos_ui/chaos_rotation.dart';
import 'package:antiiq/chaos/widgets/chaos/settings/antiiq_settings.dart';
import 'package:antiiq/chaos/page_manager.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class ChaosHeader extends StatelessWidget {
  final ChaosPageManagerController pageManagerController;
  const ChaosHeader({required this.pageManagerController, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ANTIIQ',
              style: TextStyle(
                color: AntiiQTheme.of(context).colorScheme.primary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 25,
                  height: 2,
                  color: AntiiQTheme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 10,
                  height: 2,
                  color: AntiiQTheme.of(context)
                      .colorScheme
                      .secondary
                      .withValues(alpha: 0.6),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            _buildHelpButton(context),
            const SizedBox(width: 12),
            _buildHeaderButton(Icons.settings_outlined, context, () {
              pageManagerController.push(
                const AntiiQSettings(),
                title: "Settings",
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildHelpButton(BuildContext context) {
    final currentRadius = context.watch<ChaosUIState>().chaosRadius;
    return ChaosRotatedStatefulWidget(
      maxAngle: 0.25,
      child: InkWell(
        borderRadius: BorderRadius.circular(currentRadius),
        splashColor: AntiiQTheme.of(context).colorScheme.primary,
        onTap: () {
          HapticFeedback.mediumImpact();
          _showChaosGuide(context);
        },
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AntiiQTheme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(currentRadius),
          ),
          child: Icon(
            Icons.question_mark,
            size: 18,
            color: AntiiQTheme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderButton(
      IconData icon, BuildContext context, void Function() onTap) {
    final currentRadius = context.watch<ChaosUIState>().chaosRadius;
    return ChaosRotatedStatefulWidget(
      maxAngle: 0.25,
      child: InkWell(
        borderRadius: BorderRadius.circular(currentRadius),
        splashColor: AntiiQTheme.of(context).colorScheme.primary,
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            border: Border.all(
                color: AntiiQTheme.of(context)
                    .colorScheme
                    .onBackground
                    .withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(currentRadius),
          ),
          child: Icon(
            icon,
            size: 16,
            color: AntiiQTheme.of(context)
                .colorScheme
                .onBackground
                .withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  void _showChaosGuide(BuildContext context) {
    final chaosUIState = context.read<ChaosUIState>();
    final radius = chaosUIState.chaosRadius;
    final innerRadius = chaosUIState.getAdjustedRadius(2);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AntiiQTheme.of(context).colorScheme.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(
            color: AntiiQTheme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CHAOS GESTURES',
                style: TextStyle(
                  color: AntiiQTheme.of(context).colorScheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 16),
              _buildGuideItem(
                context,
                'Canvas',
                'Drag/swipe to pan around. Long press to edit. Tap items to rotate or hide them.',
                innerRadius,
              ),
              _buildGuideItem(
                context,
                'Mini Player',
                'Tap to expand/collapse. Drag up/down also to expand/collapse. Drag left/right to skip tracks. Long press for track details.',
                innerRadius,
              ),
              _buildGuideItem(
                context,
                'Track List',
                'Swipe left on any track to reveal quick actions the AntiiQ way.',
                innerRadius,
              ),
              _buildGuideItem(
                context,
                'Track List/Collection List',
                'Tap on page heading to go to start/top of list.',
                innerRadius,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    HapticFeedback.mediumImpact();
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AntiiQTheme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(innerRadius),
                    ),
                    child: Text(
                      'GOT IT',
                      style: TextStyle(
                        color: AntiiQTheme.of(context).colorScheme.onSecondary,
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
      ),
    );
  }

  Widget _buildGuideItem(
      BuildContext context, String title, String description, double radius) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: AntiiQTheme.of(context)
                .colorScheme
                .surface
                .withValues(alpha: 0.5),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: TextStyle(
                color: AntiiQTheme.of(context).colorScheme.secondary,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                color: AntiiQTheme.of(context).colorScheme.onBackground,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
