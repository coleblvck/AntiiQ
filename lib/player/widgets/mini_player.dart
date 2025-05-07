import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/screens/main_screen/sliding_box.dart';
//Antiiq Packages
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/activity_handlers.dart';
import 'package:antiiq/player/widgets/image_widgets.dart';
import 'package:antiiq/player/widgets/seekbar.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';
import 'package:text_scroll/text_scroll.dart';

class MiniPlayer extends StatelessWidget {
  final AntiiQBoxController boxController;
  const MiniPlayer({
    super.key,
    required this.boxController,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      theme: AntiiQTheme.of(context).cardThemes.background.copyWith(
          margin: const EdgeInsets.only(left: 4.0, right: 4.0, top: 4.0)),
      child: StreamBuilder<MediaItem?>(
        stream: currentPlaying(),
        builder: (context, snapshot) {
          MediaItem? currentTrack = snapshot.data ?? currentDefaultSong;
          return Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragEnd: (details) {
                      if (swipeGestures) {
                        if (details.primaryVelocity! > 100) {
                          previous();
                        } else if (details.primaryVelocity! < -100) {
                          next();
                        }
                      }
                    },
                    onTap: () {
                      boxController.openBox();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final imageSize = constraints.maxHeight;
                            return Container(
                              width: imageSize <= 160
                                  ? imageSize
                                  : 160,
                              height: imageSize <= 160
                                  ? imageSize
                                  : 160,
                              margin: const EdgeInsets.only(right: 12.0),
                              child: getUriImage(currentTrack.artUri!),
                            );
                          },
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextScroll(
                                  currentTrack.title,
                                  textAlign: TextAlign.left,
                                  style: AntiiQTheme.of(context)
                                      .textStyles
                                      .onBackgroundText,
                                  velocity: defaultTextScrollvelocity,
                                  delayBefore: delayBeforeScroll,
                                ),
                                TextScroll(
                                  currentTrack.artist as String,
                                  textAlign: TextAlign.left,
                                  style: AntiiQTheme.of(context)
                                      .textStyles
                                      .onBackgroundText,
                                  velocity: defaultTextScrollvelocity,
                                  delayBefore: delayBeforeScroll,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 4.0,
                        ),
                        StreamBuilder<bool>(
                            stream: additionalMiniPlayerControlsStream.stream,
                            builder: (context, snapshot) {
                              final miniPlayerControlsEnabled =
                                  snapshot.data ?? additionalMiniPlayerControls;
                              return StreamBuilder<PlaybackState>(
                                  stream: currentPlaybackState(),
                                  builder: (context, state) {
                                    bool? playState = state.data?.playing;
                                    playState ??= false;
                                    return Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        miniPlayerControlsEnabled
                                            ? GestureDetector(
                                                onTap: () {
                                                  previous();
                                                },
                                                child: Icon(
                                                  RemixIcon
                                                      .arrow_left_s_outline,
                                                  color: AntiiQTheme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                  size: 44,
                                                ),
                                              )
                                            : Container(),
                                        GestureDetector(
                                          onTap: () {
                                            playState! ? pause() : resume();
                                          },
                                          child: playState
                                              ? Icon(
                                                  RemixIcon.pause,
                                                  size: 44,
                                                  color: AntiiQTheme.of(context)
                                                      .colorScheme
                                                      .secondary,
                                                )
                                              : Icon(
                                                  RemixIcon.play,
                                                  size: 44,
                                                  color: AntiiQTheme.of(context)
                                                      .colorScheme
                                                      .secondary,
                                                ),
                                        ),
                                        miniPlayerControlsEnabled
                                            ? GestureDetector(
                                                onTap: () {
                                                  next();
                                                },
                                                child: Icon(
                                                  RemixIcon
                                                      .arrow_right_s_outline,
                                                  color: AntiiQTheme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                  size: 44,
                                                ),
                                              )
                                            : Container(),
                                      ],
                                    );
                                  });
                            })
                      ],
                    ),
                  ),
                ),
              ),
              StreamBuilder<bool>(
                  stream: interactiveSeekbarStream.stream,
                  builder: (context, snapshot) {
                    bool seekbarIsInteractive =
                        snapshot.data ?? interactiveMiniPlayerSeekbar;
                    return seekbarIsInteractive
                        ? SeekBarBuilder(
                            currentTrack: currentTrack,
                            activeTrackColor:
                                AntiiQTheme.of(context).colorScheme.secondary,
                            inactiveTrackColor:
                                AntiiQTheme.of(context).colorScheme.surface,
                            thumbColor:
                                AntiiQTheme.of(context).colorScheme.primary,
                          )
                        : ProgressBarBuilder(
                            currentTrack: currentTrack,
                            activeColor:
                                AntiiQTheme.of(context).colorScheme.secondary,
                            backgroundColor:
                                AntiiQTheme.of(context).colorScheme.primary,
                          );
                  }),
            ],
          );
        },
      ),
    );
  }
}
