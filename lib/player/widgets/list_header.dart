//Flutter Packages
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/screens/selection_actions.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:flutter/material.dart';

//Icon Pack
import 'package:remix_icon_icons/remix_icon_icons.dart';
import 'package:antiiq/player/utilities/activity_handlers.dart';

class ListHeader extends StatelessWidget {
  const ListHeader({
    super.key,
    required this.headerTitle,
    required this.listToCount,
    required this.listToShuffle,
  });

  final String headerTitle;
  final dynamic listToCount;
  final List<Track> listToShuffle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Text(
              "$headerTitle: ${listToCount.length}",
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontSize: 15,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              children: [
                StreamBuilder<List<Track>>(
                    stream: globalSelectionStream.stream,
                    builder: (context, snapshot) {
                      final List<Track> selectionSituation =
                          snapshot.data ?? globalSelection;
                      return selectionSituation.isNotEmpty
                          ? IconButton(
                              padding: EdgeInsets.zero,
                              color: Theme.of(context).colorScheme.secondary,
                              iconSize: 15,
                              onPressed: () {
                                doThingsWithAudioSheet(
                                  context,
                                  selectionSituation,
                                  thisGlobalSelection: true,
                                );
                              },
                              icon: const Icon(
                                RemixIcon.list_check_3,
                              ),
                            )
                          : Container();
                    }),
                listToShuffle.length > 1
                    ? IconButton(
                        padding: EdgeInsets.zero,
                        color: Theme.of(context).colorScheme.secondary,
                        iconSize: 15,
                        onPressed: () {
                          shuffleTracks(listToShuffle);
                        },
                        icon: const Icon(
                          RemixIcon.shuffle,
                        ),
                      )
                    : Container(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
