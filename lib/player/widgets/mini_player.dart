import 'package:flutter/material.dart';

import 'package:flutter_sliding_box/flutter_sliding_box.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';
import 'package:audio_service/audio_service.dart';
import 'package:text_scroll/text_scroll.dart';

//Antiiq Packages
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/widgets/seekbar.dart';
import 'package:antiiq/player/utilities/activity_handlers.dart';
import 'package:antiiq/player/widgets/image_widgets.dart';

class MiniPlayer extends StatelessWidget {
  final BoxController boxController;
  const MiniPlayer({
    super.key,
    required this.boxController,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      theme: AntiiQTheme.of(context).cardThemes.background,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: StreamBuilder<MediaItem?>(
          stream: currentPlaying(),
          builder: (context, snapshot) {
            MediaItem? currentTrack = snapshot.data;
            currentTrack ??= currentDefaultSong;
            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
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
                  onVerticalDragEnd: (details) {
                    if (swipeGestures) {
                      if (details.primaryVelocity! < -200) {
                        boxController.openBox();
                      }
                    }
                  },
                  onTap: () {
                    boxController.openBox();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 5.0),
                          child: SizedBox(
                            height: 45,
                            child: getUriImage(currentTrack.artUri!),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextScroll(
                                currentTrack.title,
                                textAlign: TextAlign.left,
                                style: AntiiQTheme.of(context).textStyles.onBackgroundText,
                                velocity: defaultTextScrollvelocity,
                                delayBefore: delayBeforeScroll,
                              ),
                              TextScroll(
                                currentTrack.artist as String,
                                textAlign: TextAlign.left,
                                style: AntiiQTheme.of(context).textStyles.onBackgroundText,
                                velocity: defaultTextScrollvelocity,
                                delayBefore: delayBeforeScroll,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 5.0,
                          ),
                          child: StreamBuilder<PlaybackState>(
                              stream: currentPlaybackState(),
                              builder: (context, state) {
                                bool? playState = state.data?.playing;
                                playState ??= false;
                                return GestureDetector(
                                  onTap: () {
                                    playState! ? pause() : resume();
                                  },
                                  child: playState
                                      ? Icon(
                                          RemixIcon.pause,
                                          size: 40,
                                          color: AntiiQTheme.of(context)
                                              .colorScheme
                                              .secondary,
                                        )
                                      : Icon(
                                          RemixIcon.play,
                                          size: 40,
                                          color: AntiiQTheme.of(context)
                                              .colorScheme
                                              .secondary,
                                        ),
                                );
                              }),
                        )
                      ],
                    ),
                  ),
                ),
                StreamBuilder<bool>(
                    stream: interactiveSeekbarStream.stream,
                    builder: (context, snapshot) {
                      bool seekbarIsInteractive =
                          snapshot.data ?? interactiveMiniPlayerSeekbar;
                      return seekbarIsInteractive
                          ? SeekBarBuilder(currentTrack: currentTrack)
                          : ProgressBarBuilder(currentTrack: currentTrack);
                    }),
              ],
            );
          },
        ),
      ),
    );
  }
}
