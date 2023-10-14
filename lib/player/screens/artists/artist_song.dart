//Flutter Packages
import 'package:antiiq/player/screens/selection_actions.dart';
import 'package:antiiq/player/utilities/files/metadata.dart';
import 'package:flutter/material.dart';

//Antiiq Packages
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/activity_handlers.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';

class ArtistSong extends StatelessWidget {
  final Widget title;
  final Widget subtitle;
  final Widget leading;
  final Track track;
  final Artist artist;
  final int index;
  ArtistSong({
    super.key,
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.track,
    required this.artist,
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
          GestureDetector(
            onTap: () {
              playTrack(index, "album",
                  albumToPlay: artist.artistTracks!.map((e) => e.mediaItem!).toList());
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
                  ],
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
