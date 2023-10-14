//Flutter Packages
import 'package:antiiq/player/screens/selection_actions.dart';
import 'package:antiiq/player/utilities/files/metadata.dart';
import 'package:antiiq/player/utilities/playlisting/playlisting.dart';
import 'package:flutter/material.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';

//Antiiq Packages
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/activity_handlers.dart';

class PlaylistSong extends StatelessWidget {
  final Widget title;
  final Widget subtitle;
  final Widget leading;
  final Track track;
  final PlayList playlist;
  final Function setState;
  final Function mainPageStateSet;
  final int index;
  PlaylistSong({
    super.key,
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.track,
    required this.playlist,
    required this.setState,
    required this.mainPageStateSet,
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
          ReorderableDelayedDragStartListener(
            index: index,
            enabled: true,
            child: GestureDetector(
              onTap: () {
                playTrack(index, "album",
                    albumToPlay: playlist.playlistTracks!
                        .map((e) => e.mediaItem!)
                        .toList());
              },
              child: CustomCard(
                theme: CardThemes().albumSongsItemTheme,
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
                      SizedBox(
                        width: 40,
                        child: IconButton(
                          color: Colors.red,
                          onPressed: () async {
                            await removeFromPlaylist(
                                playlist.playlistId!, index);
                            setState(() {});
                            mainPageStateSet(() {});
                          },
                          icon: const Icon(RemixIcon.delete_bin_2),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
          CustomCard(
            theme: CardThemes().songsItemSwipedTheme,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        CustomButton(
                          function: () {
                            playOnlyThis(track.mediaItem!);
                            controller.jumpToPage(0);
                          },
                          style: ButtonStyles().style1,
                          child: const Text("Play Only"),
                        ),
                        const Padding(
                            padding: EdgeInsetsDirectional.only(end: 3)),
                        CustomButton(
                          function: () {
                            playTrackNext(track.mediaItem!);
                            controller.jumpToPage(0);
                          },
                          style: ButtonStyles().style2,
                          child: const Text("Play Next"),
                        ),
                        const Padding(
                            padding: EdgeInsetsDirectional.only(end: 3)),
                        CustomButton(
                          function: () {
                            addToQueue(track.mediaItem);
                            controller.jumpToPage(0);
                          },
                          style: ButtonStyles().style3,
                          child: const Text("Play Later"),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: CustomCard(
                      theme: CardThemes().albumSongsItemTheme,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: title,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
