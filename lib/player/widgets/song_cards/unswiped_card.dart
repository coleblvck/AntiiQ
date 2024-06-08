import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/screens/selection_actions.dart';
import 'package:antiiq/player/utilities/file_handling/global_selection.dart';
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
    return StreamBuilder<List<Track>>(
        stream: globalSelectionStream.stream,
        builder: (context, snapshot) {
          final List<Track> selectionSituation =
              snapshot.data ?? globalSelection;
          return GestureDetector(
            onTap: () {
              playTrack(index, selectionList, albumToPlay: albumToPlay);
            },
            onLongPress: () {
              if (selectionSituation.isEmpty) {
                globalSelectOrDeselect(track);
              }
            },
            child: CustomCard(
              theme: AntiiQTheme.of(context).cardThemes.background,
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
                    selectionSituation.isNotEmpty
                        ? SizedBox(
                            width: 40,
                            child: Checkbox(
                              checkColor: AntiiQTheme.of(context).colorScheme.primary,
                              fillColor: WidgetStatePropertyAll(AntiiQTheme.of(context).colorScheme.surface),
                              value: selectionSituation.contains(track),
                              onChanged: (value) {
                                globalSelectOrDeselect(track);
                              },
                            ),
                          )
                        : Container(),
                    SizedBox(
                      width: 40,
                      child: IconButton(
                        color: AntiiQTheme.of(context).colorScheme.primary,
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
        });
  }
}
