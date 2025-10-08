import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/screens/selection_actions.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/utilities/playlist_generator/playlist_generator.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';

class QueueSongItem extends StatelessWidget {
  final Widget title;
  final Widget subtitle;
  final Widget leading;
  final MediaItem item;
  final int index;

  QueueSongItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.item,
    required this.index,
  });

  final PageController controller = PageController();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: PageView(
        controller: controller,
        children: [
          _buildUnswipedCard(context, item),
          _buildSwipedCard(context, item),
        ],
      ),
    );
  }

  Widget _buildUnswipedCard(BuildContext context, MediaItem item) {
    return GestureDetector(
      onTap: () {
        globalAntiiqAudioHandler.skipToQueueItem(index);
      },
      child: CustomCard(
        theme: AntiiQTheme.of(context).cardThemes.background,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              // Position indicator
              Container(
                width: 30,
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: AntiiQTheme.of(context)
                        .colorScheme
                        .onBackground
                        .withAlpha(150),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Album art
              SizedBox(
                width: 70,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: leading,
                ),
              ),
              // Track info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 15.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title,
                      subtitle,
                    ],
                  ),
                ),
              ),
              // Menu button (if track available)
              SizedBox(
                width: 40,
                child: IconButton(
                  color: AntiiQTheme.of(context).colorScheme.primary,
                  onPressed: () {
                    findTrackAndOpenSheet(context, item);
                  },
                  icon: const Icon(RemixIcon.menu_4),
                ),
              ),
              // Remove button
              SizedBox(
                width: 40,
                child: IconButton(
                  color: Colors.red,
                  onPressed: () {
                    globalAntiiqAudioHandler.removeQueueItemAt(index);
                  },
                  icon: const Icon(RemixIcon.close_circle),
                ),
              ),
              // Drag handle
              SizedBox(
                width: 40,
                child: ReorderableDragStartListener(
                  index: index,
                  child: Icon(
                    RemixIcon.draggable,
                    color: AntiiQTheme.of(context)
                        .colorScheme
                        .onBackground
                        .withAlpha(150),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwipedCard(BuildContext context, MediaItem item) {
    return CustomCard(
      theme: AntiiQTheme.of(context).cardThemes.primary,
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(generalRadius),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        CustomButton(
                          function: () {
                            globalAntiiqAudioHandler.skipToQueueItem(index);
                            controller.jumpToPage(0);
                          },
                          style: ButtonStyles().style1,
                          child: const Text("Play Now"),
                        ),
                        const SizedBox(width: 4),
                        CustomButton(
                          function: () {
                            globalAntiiqAudioHandler.moveQueueItem(index, 0);
                            controller.jumpToPage(0);
                          },
                          style: ButtonStyles().style2,
                          child: const Text("Move to Top"),
                        ),
                        const SizedBox(width: 4),
                        CustomButton(
                          function: () async {
                            final queueLength =
                                globalAntiiqAudioHandler.queueLength;
                            if (queueLength > 0) {
                              await globalAntiiqAudioHandler.moveQueueItem(
                                index,
                                queueLength - 1,
                              );
                            }
                            controller.jumpToPage(0);
                          },
                          style: ButtonStyles().style3,
                          child: const Text("Move to End"),
                        ),
                        const SizedBox(width: 4),
                        CustomButton(
                          function: () async {
                            final Track? track = findTrackFromMediaItem(item);

                            if (track != null) {
                              playlistGenerator.generatePlaylist(
                                type: PlaylistType.similarToTrack,
                                seedTrack: track,
                                similarityThreshold: 0.3,
                                maxTracks: 50,
                              );
                            }
                            controller.jumpToPage(0);
                          },
                          style: ButtonStyles().style4,
                          child: const Text("Similar"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: CustomCard(
                theme: AntiiQTheme.of(context).cardThemes.background,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: Align(alignment: Alignment.centerLeft, child: title),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
