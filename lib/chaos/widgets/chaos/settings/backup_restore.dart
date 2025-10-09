import 'dart:io';
import 'package:antiiq/chaos/chaos_global_constants.dart';
import 'package:chaos_ui/chaos_rotation.dart';
import 'package:antiiq/chaos/chaos_ui_state.dart';
import 'package:antiiq/chaos/utilities/folder_picker.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/file_handling/backup_and_restore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';

class BackupRestore extends StatefulWidget {
  const BackupRestore({super.key});

  @override
  State<BackupRestore> createState() => _BackupRestoreState();
}

class _BackupRestoreState extends State<BackupRestore> {
  String backupRestorePath = "";
  List<String> backupRestoreDirectoryList = [];

  showBackUpRestoreDirectoryList() async {
    backupRestoreDirectoryList = [];
    final List<Directory>? rootList = await getExternalStorageDirectories();
    if (rootList != null) {
      for (Directory place in rootList) {
        backupRestoreDirectoryList.add(place.path.split("Android")[0]);
      }
      setState(() {});
    }
  }

  clearBackupRestoreDirectoryList() {
    setState(() {
      backupRestoreDirectoryList = [];
    });
  }

  selectBackupRestorePath(String path) async {
    Directory? newPath = await pickChaosFolder(path, context);
    if (newPath != null) {
      backupRestorePath = newPath.path;
      setState(() {});
    }
  }

  backupOrRestore(bool toBackUp) async {
    showDialog(
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
    );

    if (backupRestorePath != "") {
      if (toBackUp) {
        await backup(backupRestorePath);
      } else {
        await restore(backupRestorePath);
      }
    }

    if (mounted) {
      setState(() {
        backupRestorePath = "";
        backupRestoreDirectoryList = [];
      });
      Navigator.of(context).pop();
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
            if (backupRestorePath == "") ...[
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
                            RemixIcon.information,
                            color: AntiiQTheme.of(context).colorScheme.primary,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Select a directory to backup or restore data',
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
                        showBackUpRestoreDirectoryList();
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
                              RemixIcon.folder_open,
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

              // Storage selector
              if (backupRestoreDirectoryList.isNotEmpty) ...[
                const SizedBox(height: 8),
                _SettingContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'SELECT STORAGE',
                            style: TextStyle(
                              color: AntiiQTheme.of(context)
                                  .colorScheme
                                  .onBackground,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              clearBackupRestoreDirectoryList();
                            },
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AntiiQTheme.of(context)
                                      .colorScheme
                                      .error
                                      .withValues(alpha: 0.5),
                                  width: 1,
                                ),
                                borderRadius:
                                    BorderRadius.circular(innerRadius),
                              ),
                              child: Icon(
                                RemixIcon.close,
                                color:
                                    AntiiQTheme.of(context).colorScheme.error,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      for (String path in backupRestoreDirectoryList)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              selectBackupRestorePath(path);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AntiiQTheme.of(context)
                                    .colorScheme
                                    .surface
                                    .withValues(alpha: 0.3),
                                border: Border.all(
                                  color: AntiiQTheme.of(context)
                                      .colorScheme
                                      .surface,
                                  width: 1,
                                ),
                                borderRadius:
                                    BorderRadius.circular(innerRadius),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    RemixIcon.hard_drive,
                                    color: AntiiQTheme.of(context)
                                        .colorScheme
                                        .secondary,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      path,
                                      style: TextStyle(
                                        color: AntiiQTheme.of(context)
                                            .colorScheme
                                            .onBackground,
                                        fontSize: 12,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    RemixIcon.arrow_right_s,
                                    color: AntiiQTheme.of(context)
                                        .colorScheme
                                        .onBackground
                                        .withValues(alpha: 0.5),
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ] else ...[
              // Action selection (backup or restore)
              _SettingContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          RemixIcon.folder_2,
                          color: AntiiQTheme.of(context).colorScheme.secondary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            backupRestorePath,
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
                      ],
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
                                    RemixIcon.save_3,
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
                                    RemixIcon.restart,
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
    final outerRadius = chaosUIState.getAdjustedRadius(2);
    return ChaosRotatedStatefulWidget(
      child: Container(
        padding: const EdgeInsets.all(chaosBasePadding * 2),
        decoration: BoxDecoration(
          color:
              AntiiQTheme.of(context).colorScheme.surface.withValues(alpha: 0.2),
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
