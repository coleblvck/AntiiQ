import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:antiiq/chaos/chaos_global_constants.dart';
import 'package:antiiq/chaos/chaos_ui_state.dart';
import 'package:antiiq/chaos/utilities/angle.dart';
import 'package:chaos_ui/chaos_rotation.dart';
import 'package:provider/provider.dart';

/// Model for update information
class AntiiQUpdate {
  final String title;
  final String? subtitle;
  final List<String> updates;
  final String version;

  const AntiiQUpdate({
    required this.title,
    this.subtitle,
    required this.updates,
    required this.version,
  });
}

class AntiiQUpdateDialog extends StatelessWidget {
  final AntiiQUpdate update;
  final VoidCallback onDismiss;

  const AntiiQUpdateDialog({
    Key? key,
    required this.update,
    required this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final chaosUIState = context.read<ChaosUIState>();
    final radius = chaosUIState.chaosRadius;
    final innerRadius = chaosUIState.getAdjustedRadius(2);

    return Dialog(
      backgroundColor: AntiiQTheme.of(context).colorScheme.background,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(
          color: AntiiQTheme.of(context).colorScheme.secondary,
          width: 2,
        ),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 500),
        padding: const EdgeInsets.all(chaosBasePadding * 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            ChaosRotatedStatefulWidget(
              angle: getAnglePercentage(-0.01, chaosUIState.chaosLevel),
              child: Text(
                update.title.toUpperCase(),
                style: TextStyle(
                  color: AntiiQTheme.of(context).colorScheme.secondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
            ),
            
            if (update.subtitle != null) ...[
              const SizedBox(height: 8),
              ChaosRotatedStatefulWidget(
                angle: getAnglePercentage(0.008, chaosUIState.chaosLevel),
                child: Text(
                  update.subtitle!,
                  style: TextStyle(
                    color: AntiiQTheme.of(context)
                        .colorScheme
                        .onBackground
                        .withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Version badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AntiiQTheme.of(context)
                    .colorScheme
                    .secondary
                    .withValues(alpha: 0.2),
                border: Border.all(
                  color: AntiiQTheme.of(context)
                      .colorScheme
                      .secondary
                      .withValues(alpha: 0.4),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(innerRadius),
              ),
              child: Text(
                'VERSION ${update.version}',
                style: TextStyle(
                  color: AntiiQTheme.of(context).colorScheme.secondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  fontFamily: 'monospace',
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Updates list
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AntiiQTheme.of(context)
                        .colorScheme
                        .onBackground
                        .withValues(alpha: 0.2),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(innerRadius),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: update.updates.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index < update.updates.length - 1 ? 12 : 0,
                        ),
                        child: ChaosRotatedStatefulWidget(
                          angle: getAnglePercentage(
                            0.005 * (index % 2 == 0 ? 1 : -1),
                            chaosUIState.chaosLevel,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(right: 8, top: 4),
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AntiiQTheme.of(context)
                                      .colorScheme
                                      .secondary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  item,
                                  style: TextStyle(
                                    color: AntiiQTheme.of(context)
                                        .colorScheme
                                        .onBackground,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Dismiss button
            ChaosRotatedStatefulWidget(
              angle: getAnglePercentage(0.012, chaosUIState.chaosLevel),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop();
                  onDismiss();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AntiiQTheme.of(context).colorScheme.secondary,
                    border: Border.all(
                      color: AntiiQTheme.of(context).colorScheme.secondary,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(innerRadius),
                  ),
                  child: Center(
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
            ),
          ],
        ),
      ),
    );
  }

  /// Show the update dialog
  static Future<void> show(
    BuildContext context,
    AntiiQUpdate update,
    VoidCallback onDismiss,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (context) => AntiiQUpdateDialog(
        update: update,
        onDismiss: onDismiss,
      ),
    );
  }
}


class AntiiQUpdateDialogClassic extends StatelessWidget {
  final AntiiQUpdate update;
  final VoidCallback onDismiss;

  const AntiiQUpdateDialogClassic({
    Key? key,
    required this.update,
    required this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AntiiQTheme.of(context).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(generalRadius),
      ),
      elevation: 5,
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      title: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AntiiQTheme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(generalRadius),
            topRight: Radius.circular(generalRadius),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              update.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AntiiQTheme.of(context).colorScheme.primary,
              ),
            ),
            if (update.subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                update.subtitle!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: AntiiQTheme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AntiiQTheme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(generalRadius / 2),
              ),
              child: Text(
                'Version ${update.version}',
                style: TextStyle(
                  color: AntiiQTheme.of(context).colorScheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      content: Container(
        constraints: const BoxConstraints(
          maxHeight: 400,
          minWidth: 280,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              ...update.updates.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 12, top: 6),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AntiiQTheme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item,
                          style: AntiiQTheme.of(context).textStyles.onSurfaceText.copyWith(
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: CustomButton(
            style: AntiiQTheme.of(context).buttonStyles.style2,
            function: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
              onDismiss();
            },
            child: const Text('Got it'),
          ),
        ),
      ],
    );
  }

  /// Show the update dialog
  static Future<void> show(
    BuildContext context,
    AntiiQUpdate update,
    VoidCallback onDismiss,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AntiiQUpdateDialogClassic(
        update: update,
        onDismiss: onDismiss,
      ),
    );
  }
}