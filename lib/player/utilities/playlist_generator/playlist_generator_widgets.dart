import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:flutter/material.dart';
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/utilities/playlist_generator/playlist_generator.dart';

class StyleSnackBar {
  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    final theme = AntiiQTheme.of(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        backgroundColor: theme.colorScheme.surface,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        action: action,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: theme.colorScheme.primary, width: 1),
        ),
      ),
    );
  }
}

class LoadingButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final ButtonStyle style;
  final bool externalLoading;

  const LoadingButton({
    super.key,
    required this.onPressed,
    required this.child,
    required this.style,
    this.externalLoading = false,
  });

  @override
  State<LoadingButton> createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<LoadingButton>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(LoadingButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.externalLoading != oldWidget.externalLoading) {
      _setLoading(widget.externalLoading);
    }
  }

  void _setLoading(bool loading) {
    setState(() {
      _isLoading = loading;
    });

    if (loading) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AntiiQTheme.of(context);
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomButton(
          function: _isLoading
              ? () {}
              : () {
                  _setLoading(true);
                  widget.onPressed();
                },
          style: widget.style.copyWith(
            backgroundColor: _isLoading
                ? WidgetStatePropertyAll(
                    theme.colorScheme.surface.withAlpha(178))
                : null,
          ),
          child: Opacity(
            opacity: _isLoading ? 0.3 : 1.0,
            child: widget.child,
          ),
        ),
        if (_isLoading)
          FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 120),
              height: 2,
              child: LinearProgressIndicator(
                backgroundColor: theme.colorScheme.surface,
                valueColor:
                    AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
            ),
          ),
      ],
    );
  }
}

class PlaylistButtonBase extends StatefulWidget {
  final String label;
  final IconData icon;
  final Future<void> Function() onGeneratePlaylist;

  const PlaylistButtonBase({
    super.key,
    required this.label,
    required this.icon,
    required this.onGeneratePlaylist,
  });

  @override
  State<PlaylistButtonBase> createState() => _PlaylistButtonBaseState();
}

class _PlaylistButtonBaseState extends State<PlaylistButtonBase> {
  bool _isLoading = false;

  void setLoading(bool loading) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingButton(
      externalLoading: _isLoading,
      onPressed: () async {
        setLoading(true);
        try {
          await widget.onGeneratePlaylist();
        } finally {
          if (mounted) {
            setLoading(false);
          }
        }
      },
      style: AntiiQTheme.of(context).buttonStyles.style1,
      child: Row(
        children: [
          Icon(widget.icon),
          const SizedBox(width: 8),
          Text(widget.label),
        ],
      ),
    );
  }
}

class ShuffleAllButton extends PlaylistButtonBase {
  const ShuffleAllButton({
    super.key,
    required Future<void> Function() onGeneratePlaylist,
  }) : super(
          label: "Shuffle All",
          icon: Icons.shuffle,
          onGeneratePlaylist: onGeneratePlaylist,
        );
}

class LikedShuffleButton extends PlaylistButtonBase {
  const LikedShuffleButton({
    super.key,
    required Future<void> Function() onGeneratePlaylist,
  }) : super(
          label: "Shuffle Liked",
          icon: Icons.favorite,
          onGeneratePlaylist: onGeneratePlaylist,
        );
}

class SimilarToTrackButton extends PlaylistButtonBase {
  final Track track;

  SimilarToTrackButton({
    super.key,
    required this.track,
    required Future<void> Function(Track track) onGenerate,
  }) : super(
          label:
              "Similar to ${track.mediaItem?.title.split(' ').take(3).join(' ') ?? 'This Track'}...",
          icon: Icons.audiotrack,
          onGeneratePlaylist: () => onGenerate(track),
        );
}

class FromHistoryButton extends PlaylistButtonBase {
  const FromHistoryButton({
    super.key,
    required Future<void> Function() onGeneratePlaylist,
  }) : super(
          label: "From History",
          icon: Icons.history,
          onGeneratePlaylist: onGeneratePlaylist,
        );
}

class FreshDiscoveryButton extends PlaylistButtonBase {
  const FreshDiscoveryButton({
    super.key,
    required Future<void> Function() onGeneratePlaylist,
  }) : super(
          label: "Fresh Discovery",
          icon: Icons.explore,
          onGeneratePlaylist: onGeneratePlaylist,
        );
}

class DecadesMixButton extends PlaylistButtonBase {
  const DecadesMixButton({
    super.key,
    required Future<void> Function() onGeneratePlaylist,
  }) : super(
          label: "Decades Mix",
          icon: Icons.timeline,
          onGeneratePlaylist: onGeneratePlaylist,
        );
}

class AcousticVibeButton extends PlaylistButtonBase {
  const AcousticVibeButton({
    super.key,
    required Future<void> Function() onGeneratePlaylist,
  }) : super(
          label: "Acoustic Vibe",
          icon: Icons.piano,
          onGeneratePlaylist: onGeneratePlaylist,
        );
}

class FilterPlaylistButton extends PlaylistButtonBase {
  const FilterPlaylistButton({
    super.key,
    required String label,
    required IconData icon,
    required Future<void> Function() onGeneratePlaylist,
  }) : super(
          label: label,
          icon: icon,
          onGeneratePlaylist: onGeneratePlaylist,
        );
}

class DialogLoadingButton extends StatefulWidget {
  final String label;
  final Future<void> Function() onPressed;
  final ButtonStyle style;

  const DialogLoadingButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.style,
  });

  @override
  State<DialogLoadingButton> createState() => _DialogLoadingButtonState();
}

class _DialogLoadingButtonState extends State<DialogLoadingButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return LoadingButton(
      externalLoading: _isLoading,
      onPressed: () async {
        setState(() {
          _isLoading = true;
        });
        try {
          await widget.onPressed();
        } finally {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      },
      style: widget.style,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Text(widget.label),
      ),
    );
  }
}

class PlaylistGenerationScreen extends StatefulWidget {
  final Track? currentlyPlayingTrack;

  const PlaylistGenerationScreen({
    super.key,
    this.currentlyPlayingTrack,
  });

  @override
  State<PlaylistGenerationScreen> createState() =>
      _PlaylistGenerationScreenState();
}

class _PlaylistGenerationScreenState extends State<PlaylistGenerationScreen> {
  void _showSnackBar(String message) {
    if (mounted) {
      StyleSnackBar.show(context, message);
    }
  }

  Future<void> _generatePlaylist(PlaylistType type,
      {String? filterValue, Track? seedTrack, List<Track>? playHistory}) async {
    try {
      final playlist = await playlistGenerator.generatePlaylist(
        type: type,
        filterValue: filterValue,
        seedTrack: seedTrack,
        playHistory: playHistory,
        maxTracks: 50,
      );

      if (playlist != null && mounted) {
        String message;
        switch (type) {
          case PlaylistType.shuffleAll:
            message = "Shuffling all tracks with ${playlist.length} tracks.";
            break;
          case PlaylistType.likedShuffle:
            message = "Shuffling liked tracks with ${playlist.length} tracks.";
            break;
          case PlaylistType.similarToTrack:
            message =
                "Playing playlist similar to '${seedTrack?.mediaItem?.title ?? 'the current track'}' with ${playlist.length} tracks.";
            break;
          case PlaylistType.fromHistory:
            message =
                "Playing playlist from history with ${playlist.length} tracks.";
            break;
          case PlaylistType.freshDiscovery:
            message =
                "Playing Fresh Discovery playlist with ${playlist.length} tracks.";
            break;
          case PlaylistType.acousticVibe:
            message =
                "Playing Acoustic Vibe playlist with ${playlist.length} tracks.";
            break;
          case PlaylistType.genre:
            message =
                "Playing ${filterValue ?? 'selected'} genre playlist with ${playlist.length} tracks.";
            break;
          case PlaylistType.mood:
            message =
                "Playing ${filterValue ?? 'selected'} mood playlist with ${playlist.length} tracks.";
            break;
          case PlaylistType.tempo:
            message =
                "Playing ${filterValue ?? 'selected'} tempo playlist with ${playlist.length} tracks.";
            break;
          default:
            message = "Playing playlist with ${playlist.length} tracks.";
        }
        _showSnackBar(message);
      } else if (mounted) {
        String message = "Could not generate playlist.";
        if (filterValue != null) {
          message = "No tracks found for $filterValue.";
        } else if (type == PlaylistType.similarToTrack && seedTrack != null) {
          message =
              "No tracks found similar to '${seedTrack.mediaItem?.title}'.";
        } else if (type == PlaylistType.fromHistory) {
          message = "Could not generate playlist from history.";
        } else if (type == PlaylistType.freshDiscovery) {
          message = "Could not generate Fresh Discovery playlist.";
        } else {
          message = "Could not generate playlist.";
        }
        _showSnackBar(message);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("Error generating playlist: $e");
      }
    }
  }

  Future<void> _showSelectionDialog({
    required BuildContext context,
    required String title,
    required List<String> options,
    required PlaylistType playlistType,
  }) async {
    final theme = AntiiQTheme.of(context);

    final selectedValue = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          title: Text(
            title,
            style: TextStyle(color: theme.colorScheme.primary),
          ),
          content: Container(
            width: 300,
            constraints: const BoxConstraints(
              maxHeight: 400,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: options.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: DialogLoadingButton(
                    label: options[index],
                    style: theme.buttonStyles.style2.copyWith(
                      minimumSize: const WidgetStatePropertyAll(
                        Size.fromHeight(40),
                      ),
                    ),
                    onPressed: () async {
                      await Future.delayed(const Duration(milliseconds: 300));
                      if (context.mounted) {
                        Navigator.of(context).pop(options[index]);
                      }
                    },
                  ),
                );
              },
            ),
          ),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: DialogLoadingButton(
                label: 'Cancel',
                style: theme.buttonStyles.style3.copyWith(
                  minimumSize: const WidgetStatePropertyAll(
                    Size.fromHeight(40),
                  ),
                ),
                onPressed: () async {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        );
      },
    );

    if (selectedValue != null && mounted) {
      await _generatePlaylist(playlistType, filterValue: selectedValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AntiiQTheme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("Generate Queues"),
        foregroundColor: theme.colorScheme.secondary,
        shadowColor: theme.colorScheme.primary,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ShuffleAllButton(
            onGeneratePlaylist: () =>
                _generatePlaylist(PlaylistType.shuffleAll),
          ),
          const SizedBox(height: 16),
          FilterPlaylistButton(
            label: "Play by Genre",
            icon: Icons.category,
            onGeneratePlaylist: () async {
              final genres = playlistGenerator.getAvailableGenres();
              if (genres.isNotEmpty && mounted) {
                await _showSelectionDialog(
                  context: context,
                  title: 'Select Genre',
                  options: genres,
                  playlistType: PlaylistType.genre,
                );
              } else if (mounted) {
                _showSnackBar("No genres available");
              }
            },
          ),
          const SizedBox(height: 16),
          LikedShuffleButton(
            onGeneratePlaylist: () =>
                _generatePlaylist(PlaylistType.likedShuffle),
          ),
          const SizedBox(height: 16),
          if (widget.currentlyPlayingTrack != null)
            SimilarToTrackButton(
              track: widget.currentlyPlayingTrack!,
              onGenerate: (track) async {
                await _generatePlaylist(
                  PlaylistType.similarToTrack,
                  seedTrack: track,
                );
              },
            ),
          if (widget.currentlyPlayingTrack != null) const SizedBox(height: 16),
          FromHistoryButton(
            onGeneratePlaylist: () => _generatePlaylist(
              PlaylistType.fromHistory,
              playHistory: antiiqState.music.history.list,
            ),
          ),
          const SizedBox(height: 16),
          FilterPlaylistButton(
            label: "Play by Mood",
            icon: Icons.mood,
            onGeneratePlaylist: () async {
              final moods = playlistGenerator.getAvailableMoods();
              if (moods.isNotEmpty && mounted) {
                await _showSelectionDialog(
                  context: context,
                  title: 'Select Mood',
                  options: moods,
                  playlistType: PlaylistType.mood,
                );
              } else if (mounted) {
                _showSnackBar("No moods available");
              }
            },
          ),
          const SizedBox(height: 16),
          FilterPlaylistButton(
            label: "Play by Tempo",
            icon: Icons.speed,
            onGeneratePlaylist: () async {
              final tempos = playlistGenerator.getAvailableTempos();
              if (tempos.isNotEmpty && mounted) {
                await _showSelectionDialog(
                  context: context,
                  title: 'Select Tempo',
                  options: tempos,
                  playlistType: PlaylistType.tempo,
                );
              } else if (mounted) {
                _showSnackBar("No tempos available");
              }
            },
          ),
          const SizedBox(height: 16),
          FreshDiscoveryButton(
            onGeneratePlaylist: () => _generatePlaylist(
              PlaylistType.freshDiscovery,
              playHistory: antiiqState.music.history.list,
            ),
          ),
          const SizedBox(height: 16),
          AcousticVibeButton(
            onGeneratePlaylist: () => _generatePlaylist(
              PlaylistType.acousticVibe,
            ),
          ),
        ],
      ),
    );
  }
}
