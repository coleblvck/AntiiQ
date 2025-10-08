import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/screens/queue/queue_song.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/widgets/image_widgets.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';
import 'package:text_scroll/text_scroll.dart';

showQueue(context) {
  showModalBottomSheet(
    useSafeArea: true,
    isDismissible: true,
    enableDrag: true,
    elevation: 10,
    isScrollControlled: true,
    backgroundColor: AntiiQTheme.of(context).colorScheme.background,
    showDragHandle: true,
    barrierColor: AntiiQTheme.of(context).colorScheme.background.withAlpha(200),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(generalRadius),
        topRight: Radius.circular(generalRadius),
      ),
    ),
    context: context,
    builder: (context) => Padding(
      padding: const EdgeInsets.all(10.0),
      child: SizedBox(
        height: MediaQuery.of(context).size.height - 200,
        child: const QueuePage(),
      ),
    ),
  );
}

class QueuePage extends StatelessWidget {
  const QueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: QueueCard(),
        ),
        QueueBottomHeader(),
      ],
    );
  }
}

class QueueBottomHeader extends StatelessWidget {
  const QueueBottomHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MediaItem>>(
      stream: globalAntiiqAudioHandler.queue,
      builder: (context, snapshot) {
        final queueLength = snapshot.data?.length ?? 0;
        
        return SizedBox(
          height: 60,
          child: CustomCard(
            theme: AntiiQTheme.of(context).cardThemes.background,
            child: Padding(
              padding: const EdgeInsets.only(left: 15, right: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Queue",
                        style: TextStyle(
                          color: AntiiQTheme.of(context).colorScheme.onBackground,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "$queueLength track${queueLength != 1 ? 's' : ''} up next",
                        style: TextStyle(
                          color: AntiiQTheme.of(context)
                              .colorScheme
                              .onBackground
                              .withAlpha(150),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
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
      },
    );
  }
}

class QueueCard extends StatelessWidget {
  const QueueCard({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MediaItem>>(
      stream: globalAntiiqAudioHandler.queue,
      builder: (context, snapshot) {
        final thisQueue = snapshot.data ?? [];

        if (thisQueue.isEmpty) {
          return CustomCard(
            theme: AntiiQTheme.of(context).cardThemes.background,
            child: Center(
              child: Text(
                "Queue is empty",
                style: TextStyle(
                  color: AntiiQTheme.of(context)
                      .colorScheme
                      .onBackground
                      .withAlpha(150),
                  fontSize: 16,
                ),
              ),
            ),
          );
        }

        return CustomCard(
          theme: AntiiQTheme.of(context).cardThemes.background,
          child: ReorderableListView.builder(
            onReorder: (oldIndex, newIndex) async {
              if (newIndex > oldIndex) {
                newIndex -= 1;
              }
              await globalAntiiqAudioHandler.moveQueueItem(oldIndex, newIndex);
            },
            itemCount: thisQueue.length,
            itemBuilder: (context, index) {
              final MediaItem thisTrack = thisQueue[index];
              return QueueSongItem(
                key: ValueKey(thisTrack.id),
                title: TextScroll(
                  thisTrack.title,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: AntiiQTheme.of(context).colorScheme.onBackground,
                  ),
                  velocity: defaultTextScrollvelocity,
                  delayBefore: delayBeforeScroll,
                ),
                subtitle: TextScroll(
                  thisTrack.artist ?? "No Artist",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: AntiiQTheme.of(context).colorScheme.onBackground,
                  ),
                  velocity: defaultTextScrollvelocity,
                  delayBefore: delayBeforeScroll,
                ),
                leading: getUriImage(thisTrack.artUri!),
                item: thisTrack,
                index: index,
              );
            },
          ),
        );
      },
    );
  }
}