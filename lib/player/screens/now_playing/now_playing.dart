import 'dart:io';

import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/screens/selection_actions.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
//Antiiq Packages
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/activity_handlers.dart';
import 'package:antiiq/player/widgets/seekbar.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sliding_box/flutter_sliding_box.dart';
import 'package:just_audio/just_audio.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';
import 'package:text_scroll/text_scroll.dart';

class NowPlaying extends StatelessWidget {
  final double pageHeight;
  final BoxController boxController;
  NowPlaying({
    super.key,
    required this.pageHeight,
    required this.boxController,
  });

  final MediaItem nowPlayingSong = currentDefaultSong;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: pageHeight,
      child:
          NowPlayingPage(pageHeight: pageHeight, boxController: boxController),
    );
  }
}

class NowPlayingPage extends StatelessWidget {
  final double pageHeight;
  final BoxController boxController;
  NowPlayingPage({
    super.key,
    required this.pageHeight,
    required this.boxController,
  });

  final MediaItem nowPlayingSong = currentDefaultSong;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: NowPlayingFullCard(boxController: boxController),
        ),
        NowPlayingBottomHeader(boxController: boxController),
      ],
    );
  }
}

class NowPlayingBottomHeader extends StatelessWidget {
  const NowPlayingBottomHeader({
    super.key,
    required this.boxController,
  });

  final BoxController boxController;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: CustomCard(
        theme: AntiiQTheme.of(context).cardThemes.background.copyWith(
          margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 4)
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 15, right: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Now Playing",
                style: TextStyle(
                  color: AntiiQTheme.of(context).colorScheme.onBackground,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () {
                  boxController.closeBox();
                },
                icon: Icon(
                  RemixIcon.arrow_down_double,
                  color: AntiiQTheme.of(context).colorScheme.onBackground,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class NowPlayingFullCard extends StatelessWidget {
  const NowPlayingFullCard({
    super.key,
    required this.boxController,
  });

  final BoxController boxController;

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      theme: AntiiQTheme.of(context).cardThemes.background,
      child: StreamBuilder(
        stream: currentPlaying(),
        builder: (context, snapshot) {
          MediaItem? currentTrack = snapshot.data;
          currentTrack ??= currentDefaultSong;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(generalRadius),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: GestureDetector(
                        onVerticalDragEnd: (details) {
                          if (swipeGestures) {
                            if (details.primaryVelocity! > 100) {
                              boxController.closeBox();
                            }
                          }
                        },
                        onHorizontalDragEnd: (details) {
                          if (swipeGestures) {
                            if (details.primaryVelocity! < -100) {
                              next();
                            }
                            if (details.primaryVelocity! > 100) {
                              previous();
                            }
                          }
                        },
                        child: StreamBuilder<ArtFit>(
                          stream: coverArtFitStream.stream,
                          builder: (context, snapshot) {
                            final coverArtFit =  snapshot.data ?? currentCoverArtFit;
                            return Container(
                              decoration: BoxDecoration(
                                color:
                                    AntiiQTheme.of(context).colorScheme.background,
                                backgroundBlendMode: BlendMode.colorDodge,
                                image: DecorationImage(
                                  image: FileImage(
                                    File.fromUri(currentTrack!.artUri!),
                                  ),
                                  fit: coverArtFit == ArtFit.contain? BoxFit.contain: BoxFit.cover,
                                ),
                              ),
                              child: CustomCard(
                                theme: AntiiQTheme.of(context)
                                    .cardThemes
                                    .backgroundOverlay,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        CustomCard(
                                          theme: AntiiQTheme.of(context)
                                              .cardThemes
                                              .surfaceOverlay,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              StreamBuilder<LoopMode>(
                                                  stream: audioHandler
                                                      .audioPlayer.loopModeStream,
                                                  builder: (context, snapshot) {
                                                    if (!snapshot.hasData) {
                                                      return Container();
                                                    }
                                                    final LoopMode mode =
                                                        snapshot.data!;
                                                    return mode == LoopMode.all
                                                        ? IconButton(
                                                            color: AntiiQTheme.of(
                                                                    context)
                                                                .colorScheme
                                                                .primary,
                                                            padding:
                                                                EdgeInsets.zero,
                                                            onPressed: () {
                                                              antiiqState.audioSetup
                                                                  .preferences
                                                                  .updateLoopMode(
                                                                      LoopMode.off);
                                                            },
                                                            iconSize: 30,
                                                            icon: const Icon(
                                                                RemixIcon.repeat_2),
                                                          )
                                                        : mode == LoopMode.one
                                                            ? IconButton(
                                                                color:
                                                                    AntiiQTheme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .primary,
                                                                padding:
                                                                    EdgeInsets.zero,
                                                                onPressed: () {
                                                                  antiiqState
                                                                      .audioSetup
                                                                      .preferences
                                                                      .updateLoopMode(
                                                                          LoopMode
                                                                              .all);
                                                                },
                                                                iconSize: 30,
                                                                icon: const Icon(
                                                                    RemixIcon
                                                                        .repeat_one),
                                                              )
                                                            : IconButton(
                                                                color:
                                                                    AntiiQTheme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .onSurface,
                                                                padding:
                                                                    EdgeInsets.zero,
                                                                onPressed: () {
                                                                  antiiqState
                                                                      .audioSetup
                                                                      .preferences
                                                                      .updateLoopMode(
                                                                          LoopMode
                                                                              .one);
                                                                },
                                                                iconSize: 30,
                                                                icon: const Icon(
                                                                    RemixIcon
                                                                        .repeat_2),
                                                              );
                                                  }),
                                              StreamBuilder<bool>(
                                                  stream: audioHandler.audioPlayer
                                                      .shuffleModeEnabledStream,
                                                  builder: (context, snapshot) {
                                                    final bool enabled =
                                                        snapshot.data ?? false;
                                                    return enabled
                                                        ? IconButton(
                                                            color: AntiiQTheme.of(
                                                                    context)
                                                                .colorScheme
                                                                .primary,
                                                            padding:
                                                                EdgeInsets.zero,
                                                            onPressed: () {
                                                              antiiqState.audioSetup
                                                                  .preferences
                                                                  .updateShuffleMode(
                                                                      false);
                                                            },
                                                            iconSize: 30,
                                                            icon: const Icon(
                                                                RemixIcon.shuffle),
                                                          )
                                                        : IconButton(
                                                            color: AntiiQTheme.of(
                                                                    context)
                                                                .colorScheme
                                                                .onSurface,
                                                            padding:
                                                                EdgeInsets.zero,
                                                            onPressed: () {
                                                              antiiqState.audioSetup
                                                                  .preferences
                                                                  .updateShuffleMode(
                                                                      true);
                                                            },
                                                            iconSize: 30,
                                                            icon: const Icon(
                                                                RemixIcon.shuffle),
                                                          );
                                                  }),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          color: AntiiQTheme.of(context)
                                              .colorScheme
                                              .onBackground,
                                          padding: EdgeInsets.zero,
                                          onPressed: () {
                                            if (audioHandler
                                                    .antiiqQueue.isNotEmpty &&
                                                audioHandler
                                                        .antiiqQueue[audioHandler
                                                            .audioPlayer
                                                            .currentIndex!]
                                                        .extras!["id"] !=
                                                    "no-id") {
                                              findTrackAndOpenSheet(
                                                context,
                                                audioHandler.antiiqQueue[
                                                    audioHandler
                                                        .audioPlayer.currentIndex!],
                                              );
                                            }
                                          },
                                          iconSize: 30,
                                          icon: const Icon(RemixIcon.menu_4),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        TrackDurationDisplayWidget(
                                            currentTrack: currentTrack),
                                        SeekBarBuilder(currentTrack: currentTrack),
                                        StreamBuilder<PlaybackState>(
                                          stream: currentPlaybackState(),
                                          builder: (context, state) {
                                            bool? playState = state.data?.playing;
                                            playState ??= false;
                                            return Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceAround,
                                              children: [
                                                IconButton(
                                                  color: AntiiQTheme.of(context)
                                                      .colorScheme
                                                      .onBackground,
                                                  onPressed: () {
                                                    rewind();
                                                  },
                                                  iconSize: 40,
                                                  icon: const Icon(
                                                      RemixIcon.arrow_left_double),
                                                ),
                                                IconButton(
                                                  color: AntiiQTheme.of(context)
                                                      .colorScheme
                                                      .onBackground,
                                                  onPressed: () {
                                                    previous();
                                                  },
                                                  iconSize: 40,
                                                  icon: const Icon(
                                                      RemixIcon.arrow_left_circle),
                                                ),
                                                IconButton(
                                                  color: AntiiQTheme.of(context)
                                                      .colorScheme
                                                      .onBackground,
                                                  onPressed: () {
                                                    playState! ? pause() : resume();
                                                  },
                                                  iconSize: 40,
                                                  icon: playState
                                                      ? const Icon(
                                                          RemixIcon.pause_circle)
                                                      : const Icon(
                                                          RemixIcon.play_circle),
                                                ),
                                                IconButton(
                                                  color: AntiiQTheme.of(context)
                                                      .colorScheme
                                                      .onBackground,
                                                  onPressed: () {
                                                    next();
                                                  },
                                                  iconSize: 40,
                                                  icon: const Icon(
                                                      RemixIcon.arrow_right_circle),
                                                ),
                                                IconButton(
                                                  color: AntiiQTheme.of(context)
                                                      .colorScheme
                                                      .onBackground,
                                                  onPressed: () {
                                                    forward();
                                                  },
                                                  iconSize: 40,
                                                  icon: const Icon(
                                                      RemixIcon.arrow_right_double),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 15.0, vertical: 15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextScroll(
                      currentTrack.title,
                      textAlign: TextAlign.right,
                      style:
                          AntiiQTheme.of(context).textStyles.onBackgroundText,
                      velocity: defaultTextScrollvelocity,
                      delayBefore: delayBeforeScroll,
                    ),
                    TextScroll(
                      currentTrack.artist!,
                      textAlign: TextAlign.right,
                      style:
                          AntiiQTheme.of(context).textStyles.onBackgroundText,
                      velocity: defaultTextScrollvelocity,
                      delayBefore: delayBeforeScroll,
                    ),
                    TextScroll(
                      currentTrack.album!,
                      textAlign: TextAlign.right,
                      style:
                          AntiiQTheme.of(context).textStyles.onBackgroundText,
                      velocity: defaultTextScrollvelocity,
                      delayBefore: delayBeforeScroll,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class TrackDurationDisplayWidget extends StatelessWidget {
  const TrackDurationDisplayWidget({
    super.key,
    required this.currentTrack,
  });

  final MediaItem? currentTrack;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: trackDurationDisplayStream.stream,
      builder: (context, snapshot) {
        bool displayDuration = snapshot.data ?? showTrackDuration;
        return displayDuration
            ? Center(
                child: CustomCard(
                  theme: AntiiQTheme.of(context).cardThemes.surface,
                  child: StreamBuilder<Duration>(
                    stream: currentPosition(),
                    builder: (context, data) {
                      int? position = data.data?.abs().inSeconds;
                      int? duration = currentTrack?.duration?.abs().inSeconds;
                      position ??= 0;
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "${toMinuteSeconds(position)} / ${toMinuteSeconds(duration)}",
                          style: TextStyles().onSurfaceText,
                        ),
                      );
                    },
                  ),
                ),
              )
            : Container();
      },
    );
  }
}

String toMinuteSeconds(secondsToConvert) {
  int minutes = secondsToConvert ~/ 60;
  int seconds = secondsToConvert % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}
