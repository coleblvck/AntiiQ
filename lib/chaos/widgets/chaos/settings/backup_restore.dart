import 'dart:async';
import 'package:antiiq/chaos/chaos_global_constants.dart';
import 'package:antiiq/chaos/utilities/angle.dart';
import 'package:chaos_ui/chaos_rotation.dart';
import 'package:antiiq/chaos/chaos_ui_state.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/app_restart.dart';
import 'package:antiiq/player/utilities/file_handling/backup_and_restore.dart';
import 'package:antiiq/player/utilities/file_handling/backup_storage_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:remixicon/remixicon.dart';

class BackupRestore extends StatefulWidget {
  const BackupRestore({super.key});

  @override
  State<BackupRestore> createState() => _BackupRestoreState();
}

class _BackupRestoreState extends State<BackupRestore> {
  BackupDirectory? _backupDirectory;

  Future<void> selectBackupRestoreDirectory() async {
    try {
      final directory = await BackupStorageBridge.pickDirectory();
      if (directory != null && mounted) {
        setState(() => _backupDirectory = directory);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open folder picker: $error')),
      );
    }
  }

  Future<void> backupOrRestore(bool toBackUp) async {
    final backupDirectory = _backupDirectory;
    if (backupDirectory == null) return;

    unawaited(
      showDialog<void>(
        useSafeArea: true,
        barrierDismissible: false,
        context: context,
        builder: (context) {
          final chaosUIState = context.watch<ChaosUIState>();
          final outerRadius = chaosUIState.getAdjustedRadius(2);
          return PopScope(
            canPop: false,
            child: Dialog(
              backgroundColor: AntiiQTheme.of(context).colorScheme.background,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(outerRadius),
                side: BorderSide(
                  color: AntiiQTheme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      toBackUp ? 'CREATING BACKUP...' : 'RESTORING...',
                      style: TextStyle(
                        color: AntiiQTheme.of(context).colorScheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const CustomInfiniteProgressIndicator(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    Object? failure;
    try {
      if (toBackUp) {
        await backup(backupDirectory.uri);
      } else {
        await restore(backupDirectory.uri);
      }
    } catch (error) {
      failure = error;
    }

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    if (failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Operation failed: $failure')),
      );
      return;
    }

    setState(() {
      _backupDirectory = null;
    });

    if (!toBackUp) {
      try {
        await restartAntiiQ();
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Restore finished, but restart failed: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chaosUIState = context.watch<ChaosUIState>();
    final innerRadius = chaosUIState.getAdjustedRadius(4);
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(chaosBasePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_backupDirectory == null) ...[
              // Select directory flow
              _SettingContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                              .onBackground
                              .withValues(alpha: 0.2),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(innerRadius),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            RemixIcons.information_fill,
                            color: AntiiQTheme.of(context).colorScheme.primary,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Choose a folder and grant AntiiQ access to create or restore backup files.',
                              style: TextStyle(
                                color: AntiiQTheme.of(context)
                                    .colorScheme
                                    .onBackground
                                    .withValues(alpha: 0.7),
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        selectBackupRestoreDirectory();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(chaosBasePadding * 2),
                        decoration: BoxDecoration(
                          color: AntiiQTheme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.1),
                          border: Border.all(
                            color: AntiiQTheme.of(context).colorScheme.primary,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(innerRadius),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              RemixIcons.folder_open_fill,
                              color:
                                  AntiiQTheme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: chaosBasePadding * 1.5),
                            Text(
                              'SELECT DIRECTORY',
                              style: TextStyle(
                                color:
                                    AntiiQTheme.of(context).colorScheme.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Action selection (backup or restore)
              _SettingContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: selectBackupRestoreDirectory,
                      child: Row(
                        children: [
                          Icon(
                            RemixIcons.folder_2_fill,
                            color:
                                AntiiQTheme.of(context).colorScheme.secondary,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _backupDirectory!.name,
                              style: TextStyle(
                                color: AntiiQTheme.of(context)
                                    .colorScheme
                                    .onBackground,
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            RemixIcons.folder_transfer_fill,
                            color:
                                AntiiQTheme.of(context).colorScheme.secondary,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'SELECT ACTION',
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              backupOrRestore(true);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AntiiQTheme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.1),
                                border: Border.all(
                                  color: AntiiQTheme.of(context)
                                      .colorScheme
                                      .primary,
                                  width: 1,
                                ),
                                borderRadius:
                                    BorderRadius.circular(innerRadius),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    RemixIcons.save_3_fill,
                                    color: AntiiQTheme.of(context)
                                        .colorScheme
                                        .primary,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'BACKUP',
                                    style: TextStyle(
                                      color: AntiiQTheme.of(context)
                                          .colorScheme
                                          .primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              backupOrRestore(false);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AntiiQTheme.of(context)
                                    .colorScheme
                                    .secondary
                                    .withValues(alpha: 0.1),
                                border: Border.all(
                                  color: AntiiQTheme.of(context)
                                      .colorScheme
                                      .secondary,
                                  width: 1,
                                ),
                                borderRadius:
                                    BorderRadius.circular(innerRadius),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    RemixIcons.restart_fill,
                                    color: AntiiQTheme.of(context)
                                        .colorScheme
                                        .secondary,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'RESTORE',
                                    style: TextStyle(
                                      color: AntiiQTheme.of(context)
                                          .colorScheme
                                          .secondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
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
    final chaosLevel = chaosUIState.chaosLevel;
    final outerRadius = chaosUIState.getAdjustedRadius(2);
    return ChaosRotatedStatefulWidget(
      maxAngle: getAnglePercentage(0.1, chaosLevel),
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
