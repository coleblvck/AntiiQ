//Flutter Packages
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

//Antiiq Packages
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/activity_handlers.dart';

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
      child: GestureDetector(
        onTap: () {
          playTrack(index, "queue");
        },
        child: CustomCard(
          theme: AntiiQTheme.of(context).cardThemes.background,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: leading,
                  ),
                ),
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
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
