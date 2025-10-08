import 'dart:io';

import 'package:antiiq/chaos/chaos_global_constants.dart';
import 'package:antiiq/chaos/chaos_ui_state.dart';
import 'package:antiiq/chaos/chaos_ui/chaos_rotation.dart';
import 'package:antiiq/chaos/utilities/folder_picker.dart';
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/settings/user_settings.dart';
import 'package:antiiq/player/widgets/ui/antiiq_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';
import 'package:restart_app/restart_app.dart';
import 'package:text_scroll/text_scroll.dart';

class Library extends StatefulWidget {
  const Library({super.key});

  @override
  State<Library> createState() => _LibraryState();
}

class _LibraryState extends State<Library> {
  List<String> directoryList = [];

  clearDirectoryList() {
    setState(() {
      directoryList = [];
    });
  }

  selectRootDirectory() async {
    directoryList = [];
    final List<Directory>? rootList = await getExternalStorageDirectories();
    if (rootList != null) {
      for (Directory place in rootList) {
        directoryList.add(place.path.split("Android")[0]);
      }
      setState(() {});
    }
  }

  directoryAdd(String path) async {
    Directory? newPath = await pickChaosFolder(path, context);
    if (newPath != null && !specificPathsToQuery.contains(newPath.path)) {
      specificPathsToQuery.add(newPath.path);
      await updateDirectories();
      setState(() {});
    }
  }

  directoryRemove(index) async {
    specificPathsToQuery.removeAt(index);
    await updateDirectories();
    setState(() {});
  }

  fullRescan() async {
    antiiqState.dataIsInitialized = false;
    await antiiqState.store.put("dataInit", false);
    Restart.restartApp();
  }

  rescan() async {
    Restart.restartApp();
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
            // Scan actions
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'RE-SCAN',
                    icon: RemixIcon.refresh,
                    color: AntiiQTheme.of(context).colorScheme.primary,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      rescan();
                    },
                  ),
                ),
                const SizedBox(width: chaosBasePadding),
                Expanded(
                  child: _ActionButton(
                    label: 'FULL RESCAN',
                    icon: RemixIcon.refresh,
                    color: AntiiQTheme.of(context).colorScheme.error,
                    onTap: () {
                      HapticFeedback.heavyImpact();
                      _showFullRescanWarning(context);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: chaosBasePadding),

            // Minimum track length
            _SettingContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'MIN TRACK LENGTH',
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: chaosBasePadding,
                            vertical: chaosBasePadding / 2),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AntiiQTheme.of(context)
                                .colorScheme
                                .secondary
                                .withValues(alpha: 0.5),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(innerRadius),
                        ),
                        child: Text(
                          '${minimumTrackLength}S',
                          style: TextStyle(
                            color:
                                AntiiQTheme.of(context).colorScheme.secondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 24,
                    child: AntiiQSlider(
                      activeTrackColor:
                          AntiiQTheme.of(context).colorScheme.secondary,
                      inactiveTrackColor:
                          AntiiQTheme.of(context).colorScheme.surface,
                      thumbColor:
                          AntiiQTheme.of(context).colorScheme.onBackground,
                      thumbWidth: 24.0,
                      thumbHeight: 24.0,
                      thumbBorderRadius: innerRadius,
                      trackHeight: 24.0,
                      trackBorderRadius: innerRadius,
                      orientation: Axis.horizontal,
                      selectByTap: true,
                      value: minimumTrackLength.toDouble(),
                      min: 5,
                      max: 120,
                      step: 1,
                      onChanged: (value) {
                        HapticFeedback.selectionClick();
                        setState(() {
                          setMinimumTrackLength(value.round());
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Directories section
            const _SectionDivider(label: 'DIRECTORIES'),

            const SizedBox(height: 8),

            _SettingContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(chaosBasePadding),
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
                    child: Text(
                      'Adding directories excludes all other locations from scanning',
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
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      selectRootDirectory();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(chaosBasePadding * 1.5),
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
                            RemixIcon.folder_add,
                            color: AntiiQTheme.of(context).colorScheme.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ADD FROM STORAGE',
                            style: TextStyle(
                              color:
                                  AntiiQTheme.of(context).colorScheme.primary,
                              fontSize: 12,
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
            if (directoryList.isNotEmpty) ...[
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
                            clearDirectoryList();
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
                              borderRadius: BorderRadius.circular(innerRadius),
                            ),
                            child: Icon(
                              RemixIcon.close,
                              color: AntiiQTheme.of(context).colorScheme.error,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: chaosBasePadding),
                    for (String path in directoryList)
                      Padding(
                        padding: const EdgeInsets.only(top: chaosBasePadding),
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            directoryAdd(path);
                          },
                          child: Container(
                            padding:
                                const EdgeInsets.all(chaosBasePadding * 1.5),
                            decoration: BoxDecoration(
                              color: AntiiQTheme.of(context)
                                  .colorScheme
                                  .surface
                                  .withValues(alpha: 0.3),
                              border: Border.all(
                                color:
                                    AntiiQTheme.of(context).colorScheme.surface,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(innerRadius),
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

            // Active directories
            if (specificPathsToQuery.isNotEmpty) ...[
              const SizedBox(height: 16),
              const _SectionDivider(label: 'ACTIVE DIRECTORIES'),
              const SizedBox(height: 8),
              for (String directory in specificPathsToQuery)
                Padding(
                  padding: const EdgeInsets.only(bottom: chaosBasePadding),
                  child: _DirectoryCard(
                    path: directory,
                    onRemove: () {
                      HapticFeedback.mediumImpact();
                      directoryRemove(specificPathsToQuery.indexOf(directory));
                    },
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _showFullRescanWarning(BuildContext context) {
    final chaosUIState = context.read<ChaosUIState>();
    final outerRadius = chaosUIState.getAdjustedRadius(2);
    final innerRadius = chaosUIState.getAdjustedRadius(4);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AntiiQTheme.of(context).colorScheme.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(outerRadius),
          side: BorderSide(
            color: AntiiQTheme.of(context).colorScheme.error,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(chaosBasePadding * 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                RemixIcon.alert,
                color: AntiiQTheme.of(context).colorScheme.error,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'FULL RESCAN',
                style: TextStyle(
                  color: AntiiQTheme.of(context).colorScheme.error,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This will clear all library data and rescan from scratch. Continue?',
                style: TextStyle(
                  color: AntiiQTheme.of(context).colorScheme.onBackground,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(chaosBasePadding * 1.5),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AntiiQTheme.of(context).colorScheme.surface,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(innerRadius),
                        ),
                        child: Center(
                          child: Text(
                            'CANCEL',
                            style: TextStyle(
                              color: AntiiQTheme.of(context)
                                  .colorScheme
                                  .onBackground,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.heavyImpact();
                        Navigator.of(context).pop();
                        fullRescan();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(chaosBasePadding * 1.5),
                        decoration: BoxDecoration(
                          color: AntiiQTheme.of(context).colorScheme.error,
                          border: Border.all(
                            color: AntiiQTheme.of(context)
                                .colorScheme
                                .onError
                                .withValues(alpha: 0.3),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(innerRadius),
                        ),
                        child: Center(
                          child: Text(
                            'RESCAN',
                            style: TextStyle(
                              color:
                                  AntiiQTheme.of(context).colorScheme.onError,
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
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chaosUIState = context.watch<ChaosUIState>();
    final outerRadius = chaosUIState.getAdjustedRadius(2);
    return ChaosRotatedStatefulWidget(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(chaosBasePadding * 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color, width: 1),
            borderRadius: BorderRadius.circular(outerRadius),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
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

class _DirectoryCard extends StatelessWidget {
  final String path;
  final VoidCallback onRemove;

  const _DirectoryCard({required this.path, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final chaosUIState = context.watch<ChaosUIState>();
    final innerRadius = chaosUIState.getAdjustedRadius(4);
    return Container(
      padding: const EdgeInsets.all(chaosBasePadding * 1.5),
      decoration: BoxDecoration(
        color:
            AntiiQTheme.of(context).colorScheme.surface.withValues(alpha: 0.3),
        border: Border.all(
          color: AntiiQTheme.of(context).colorScheme.surface,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(innerRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                RemixIcon.folder_open,
                color: AntiiQTheme.of(context).colorScheme.secondary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextScroll(
                  path,
                  style: TextStyle(
                    color: AntiiQTheme.of(context).colorScheme.onBackground,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                  velocity: const Velocity(pixelsPerSecond: Offset(30, 0)),
                  pauseBetween: const Duration(seconds: 2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: chaosBasePadding),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AntiiQTheme.of(context)
                      .colorScheme
                      .error
                      .withValues(alpha: 0.5),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(innerRadius),
              ),
              child: Center(
                child: Text(
                  'REMOVE',
                  style: TextStyle(
                    color: AntiiQTheme.of(context).colorScheme.error,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
