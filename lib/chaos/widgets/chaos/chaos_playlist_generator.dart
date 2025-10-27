import 'dart:math' as math;
import 'package:antiiq/chaos/chaos_global_constants.dart';
import 'package:antiiq/chaos/chaos_ui_state.dart';
import 'package:antiiq/chaos/utilities/angle.dart';
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/utilities/playlist_generator/playlist_generator.dart';
import 'package:chaos_ui/chaos_rotation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';

class ChaosSnackBar {
  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    final chaosUIState = context.read<ChaosUIState>();
    final radius = chaosUIState.chaosRadius;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message.toUpperCase(),
          style: TextStyle(
            color: AntiiQTheme.of(context).colorScheme.primary,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: AntiiQTheme.of(context).colorScheme.background,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(
            color: AntiiQTheme.of(context)
                .colorScheme
                .primary
                .withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        margin: const EdgeInsets.all(chaosBasePadding),
      ),
    );
  }
}

class ChaosPlaylistGenerator extends StatelessWidget {
  final Track? currentlyPlayingTrack;

  const ChaosPlaylistGenerator({
    super.key,
    this.currentlyPlayingTrack,
  });

  void _showSnackBar(BuildContext context, String message) {
    ChaosSnackBar.show(context, message);
  }

  Future<void> _generatePlaylist(
    BuildContext context,
    PlaylistType type, {
    String? filterValue,
    Track? seedTrack,
    List<Track>? playHistory,
  }) async {
    try {
      final playlist = await playlistGenerator.generatePlaylist(
        type: type,
        filterValue: filterValue,
        seedTrack: seedTrack,
        playHistory: playHistory,
        maxTracks: 50,
      );

      if (playlist != null && context.mounted) {
        String message;
        switch (type) {
          case PlaylistType.shuffleAll:
            message = "${playlist.length} tracks shuffled";
            break;
          case PlaylistType.likedShuffle:
            message = "${playlist.length} liked tracks";
            break;
          case PlaylistType.similarToTrack:
            message = "${playlist.length} similar tracks";
            break;
          case PlaylistType.fromHistory:
            message = "${playlist.length} from history";
            break;
          case PlaylistType.freshDiscovery:
            message = "${playlist.length} fresh tracks";
            break;
          case PlaylistType.acousticVibe:
            message = "${playlist.length} acoustic tracks";
            break;
          case PlaylistType.genre:
            message = "${playlist.length} ${filterValue ?? ''} tracks";
            break;
          case PlaylistType.mood:
            message = "${playlist.length} ${filterValue ?? ''} tracks";
            break;
          case PlaylistType.tempo:
            message = "${playlist.length} ${filterValue ?? ''} tracks";
            break;
          default:
            message = "${playlist.length} tracks";
        }
        _showSnackBar(context, message);
      } else if (context.mounted) {
        _showSnackBar(context, "No tracks found");
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, "Generation failed");
      }
    }
  }

  Future<void> _showSelectionDialog({
    required BuildContext context,
    required String title,
    required List<String> options,
    required PlaylistType playlistType,
  }) async {
    final selected = await showChaosSelectionDialog(
      context,
      title: title,
      options: options,
    );

    if (selected != null && context.mounted) {
      await _generatePlaylist(context, playlistType, filterValue: selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(chaosBasePadding),
      children: [
        ChaosGeneratorButton(
          label: 'SHUFFLE ALL',
          icon: RemixIcon.shuffle,
          index: 0,
          onPressed: () => _generatePlaylist(context, PlaylistType.shuffleAll),
        ),
        const SizedBox(height: chaosBasePadding),
        ChaosGeneratorButton(
          label: 'BY GENRE',
          icon: RemixIcon.folder_music,
          index: 1,
          onPressed: () async {
            final genres = playlistGenerator.getAvailableGenres();
            if (genres.isNotEmpty && context.mounted) {
              await _showSelectionDialog(
                context: context,
                title: 'SELECT GENRE',
                options: genres,
                playlistType: PlaylistType.genre,
              );
            } else if (context.mounted) {
              _showSnackBar(context, "No genres available");
            }
          },
        ),
        const SizedBox(height: chaosBasePadding),
        ChaosGeneratorButton(
          label: 'LIKED SHUFFLE',
          icon: RemixIcon.heart_3,
          index: 2,
          onPressed: () =>
              _generatePlaylist(context, PlaylistType.likedShuffle),
        ),
        const SizedBox(height: chaosBasePadding),
        if (currentlyPlayingTrack != null)
          ChaosGeneratorButton(
            label: 'SIMILAR TRACKS',
            icon: RemixIcon.music_2,
            index: 3,
            onPressed: () => _generatePlaylist(
              context,
              PlaylistType.similarToTrack,
              seedTrack: currentlyPlayingTrack,
            ),
          ),
        if (currentlyPlayingTrack != null)
          const SizedBox(height: chaosBasePadding),
        ChaosGeneratorButton(
          label: 'FROM HISTORY',
          icon: RemixIcon.time,
          index: 4,
          onPressed: () => _generatePlaylist(
            context,
            PlaylistType.fromHistory,
            playHistory: antiiqState.music.history.list,
          ),
        ),
        const SizedBox(height: chaosBasePadding),
        ChaosGeneratorButton(
          label: 'BY MOOD',
          icon: RemixIcon.emotion_happy,
          index: 5,
          onPressed: () async {
            final moods = playlistGenerator.getAvailableMoods();
            if (moods.isNotEmpty && context.mounted) {
              await _showSelectionDialog(
                context: context,
                title: 'SELECT MOOD',
                options: moods,
                playlistType: PlaylistType.mood,
              );
            } else if (context.mounted) {
              _showSnackBar(context, "No moods available");
            }
          },
        ),
        const SizedBox(height: chaosBasePadding),
        ChaosGeneratorButton(
          label: 'BY TEMPO',
          icon: RemixIcon.speed,
          index: 6,
          onPressed: () async {
            final tempos = playlistGenerator.getAvailableTempos();
            if (tempos.isNotEmpty && context.mounted) {
              await _showSelectionDialog(
                context: context,
                title: 'SELECT TEMPO',
                options: tempos,
                playlistType: PlaylistType.tempo,
              );
            } else if (context.mounted) {
              _showSnackBar(context, "No tempos available");
            }
          },
        ),
        const SizedBox(height: chaosBasePadding),
        ChaosGeneratorButton(
          label: 'FRESH DISCOVERY',
          icon: RemixIcon.compass_3,
          index: 7,
          onPressed: () => _generatePlaylist(
            context,
            PlaylistType.freshDiscovery,
            playHistory: antiiqState.music.history.list,
          ),
        ),
        const SizedBox(height: chaosBasePadding),
        ChaosGeneratorButton(
          label: 'ACOUSTIC VIBE',
          icon: RemixIcon.surround_sound,
          index: 8,
          onPressed: () =>
              _generatePlaylist(context, PlaylistType.acousticVibe),
        ),
      ],
    );
  }
}

class ChaosGeneratorButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final int index;
  final Future<void> Function() onPressed;

  const ChaosGeneratorButton({
    required this.label,
    required this.icon,
    required this.index,
    required this.onPressed,
    super.key,
  });

  @override
  State<ChaosGeneratorButton> createState() => _ChaosGeneratorButtonState();
}

class _ChaosGeneratorButtonState extends State<ChaosGeneratorButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _glitchController;
  bool _isGlitching = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _glitchController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _glitchController.dispose();
    super.dispose();
  }

  void _triggerGlitch() {
    if (!_isGlitching && mounted) {
      _isGlitching = true;
      _glitchController.forward().then((_) {
        if (mounted) {
          _glitchController.reverse().then((_) {
            if (mounted) _isGlitching = false;
          });
        }
      });
    }
  }

  void _handleTap() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    _triggerGlitch();
    HapticFeedback.mediumImpact();

    try {
      await widget.onPressed();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chaosUIState = context.watch<ChaosUIState>();
    final currentRadius = chaosUIState.chaosRadius;
    final chaosLevel = chaosUIState.chaosLevel;
    final innerRadius = chaosUIState.getAdjustedRadius(2);

    final rotation = (widget.index % 7 - 3) * 0.01;

    return ChaosRotatedStatefulWidget(
      angle: getAnglePercentage(rotation, chaosLevel),
      child: AnimatedBuilder(
        animation: _glitchController,
        builder: (context, child) {
          final random = math.Random(widget.index);
          final glitchOffset = _isGlitching
              ? Offset(
                  _glitchController.value * (random.nextDouble() * 4 - 2),
                  _glitchController.value * (random.nextDouble() * 3 - 1.5),
                )
              : Offset.zero;

          return Transform.translate(
            offset: glitchOffset,
            child: GestureDetector(
              onTap: _handleTap,
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AntiiQTheme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: _isLoading ? 0.15 : 0.3),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(currentRadius),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: chaosBasePadding * 2,
                  ),
                  decoration: BoxDecoration(
                    color: AntiiQTheme.of(context).colorScheme.background,
                    borderRadius: BorderRadius.circular(innerRadius),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: _isLoading ? 0.3 : 1.0,
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AntiiQTheme.of(context)
                                      .colorScheme
                                      .secondary
                                      .withValues(alpha: 0.5),
                                  width: 1,
                                ),
                                borderRadius:
                                    BorderRadius.circular(innerRadius),
                              ),
                              child: Icon(
                                widget.icon,
                                color: AntiiQTheme.of(context)
                                    .colorScheme
                                    .secondary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                widget.label,
                                style: TextStyle(
                                  color: AntiiQTheme.of(context)
                                      .colorScheme
                                      .primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            Icon(
                              RemixIcon.arrow_right_s,
                              color: AntiiQTheme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.4),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                      if (_isLoading)
                        Positioned.fill(
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  AntiiQTheme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

Future<String?> showChaosSelectionDialog(
  BuildContext context, {
  required String title,
  required List<String> options,
}) {
  final chaosUIState = context.read<ChaosUIState>();
  final radius = chaosUIState.chaosRadius;
  final innerRadius = (radius - 2);

  return showDialog<String>(
    context: context,
    builder: (context) => _ChaosSelectionDialog(
      title: title,
      options: options,
      radius: radius,
      innerRadius: innerRadius,
    ),
  );
}

class _ChaosSelectionDialog extends StatefulWidget {
  final String title;
  final List<String> options;
  final double radius;
  final double innerRadius;

  const _ChaosSelectionDialog({
    required this.title,
    required this.options,
    required this.radius,
    required this.innerRadius,
  });

  @override
  State<_ChaosSelectionDialog> createState() => _ChaosSelectionDialogState();
}

class _ChaosSelectionDialogState extends State<_ChaosSelectionDialog> {
  int? _loadingIndex;

  @override
  Widget build(BuildContext context) {
    final chaosUIState = context.watch<ChaosUIState>();
    final chaosLevel = chaosUIState.chaosLevel;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 500),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AntiiQTheme.of(context).colorScheme.background,
          border: Border.all(
            color: AntiiQTheme.of(context)
                .colorScheme
                .primary
                .withValues(alpha: 0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(chaosBasePadding * 2),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AntiiQTheme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        color: AntiiQTheme.of(context).colorScheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AntiiQTheme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.3),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(widget.innerRadius),
                      ),
                      child: Icon(
                        Icons.close,
                        color: AntiiQTheme.of(context).colorScheme.primary,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.all(chaosBasePadding),
                itemCount: widget.options.length,
                itemBuilder: (context, index) {
                  final rotation = (index % 7 - 3) * 0.008;
                  final isLoading = _loadingIndex == index;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: chaosBasePadding),
                    child: ChaosRotatedStatefulWidget(
                      angle: getAnglePercentage(rotation, chaosLevel),
                      child: GestureDetector(
                        onTap: isLoading
                            ? null
                            : () async {
                                setState(() => _loadingIndex = index);
                                HapticFeedback.selectionClick();
                                await Future.delayed(
                                    const Duration(milliseconds: 100));
                                if (mounted) {
                                  Navigator.of(context)
                                      .pop(widget.options[index]);
                                }
                              },
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(
                            horizontal: chaosBasePadding * 1.5,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AntiiQTheme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: isLoading ? 0.15 : 0.3),
                              width: 1,
                            ),
                            borderRadius:
                                BorderRadius.circular(widget.innerRadius),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Opacity(
                                opacity: isLoading ? 0.3 : 1.0,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.options[index].toUpperCase(),
                                        style: TextStyle(
                                          color: AntiiQTheme.of(context)
                                              .colorScheme
                                              .onBackground,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      RemixIcon.check,
                                      color: AntiiQTheme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.5),
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                              if (isLoading)
                                Positioned.fill(
                                  child: Center(
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                          AntiiQTheme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
