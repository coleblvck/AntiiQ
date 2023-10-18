import 'package:antiiq/player/screens/selection_actions.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

//Antiiq Packages
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/activity_handlers.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';



class UnswipedCard extends StatelessWidget {
  const UnswipedCard({
    super.key,
    required this.index,
    required this.selectionList,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.track,
    this.albumToPlay,
  });

  final int index;
  final String selectionList;
  final Widget leading;
  final Widget title;
  final Widget subtitle;
  final Track track;
  final List<MediaItem>? albumToPlay;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        playTrack(index, selectionList, albumToPlay: albumToPlay);
      },
      child: CustomCard(
        theme: CardThemes().songsItemTheme,
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Row(
            children: [
              SizedBox(
                height: 80,
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
              ),
              SizedBox(
                width: 40,
                child: IconButton(
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: () {
                    openSheetFromTrack(context, track);
                  },
                  icon: const Icon(RemixIcon.menu_4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
