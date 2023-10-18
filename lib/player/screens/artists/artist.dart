import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/screens/artists/artist_song.dart';
import 'package:antiiq/player/screens/selection_actions.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/widgets/list_header.dart';
import 'package:flutter/material.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';
import 'package:text_scroll/text_scroll.dart';

//Antiiq Packages
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/widgets/image_widgets.dart';

class ArtistItem extends StatelessWidget {
  final Widget title;
  final Widget subtitle;
  final Widget leading;
  final Artist artist;
  final int index;
  const ArtistItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.artist,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showArtist(context, artist);
      },
      child: CustomCard(
        theme: CardThemes().songsItemTheme,
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Row(
            children: [
              SizedBox(
                height: 80,
                child: getUriImage(artist.artistArt),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
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
                    doThingsWithAudioSheet(context, artist.artistTracks!);
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

showArtist(context, Artist artist) {
  showModalBottomSheet(
    useSafeArea: true,
    isDismissible: true,
    enableDrag: true,
    elevation: 10,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.background,
    showDragHandle: true,
    barrierColor: Theme.of(context).colorScheme.background.withAlpha(200),
    shape: bottomSheetShape,
    context: context,
    builder: (context) => Padding(
      padding: const EdgeInsets.all(10.0),
      child: SizedBox(
        height: MediaQuery.of(context).size.height - 200,
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: getUriImage(artist.artistArt),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: TextScroll(
                        artist.artistName!,
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                        velocity: defaultTextScrollvelocity,
                        delayBefore: delayBeforeScroll,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: ListHeader(
                      headerTitle: "Tracks",
                      listToCount: artist.artistTracks,
                      listToShuffle: artist.artistTracks!,
                    ),
                  ),
                  SliverFixedExtentList.builder(
                    itemExtent: 100,
                    itemCount: artist.artistTracks!.length,
                    itemBuilder: (context, index) {
                      final thisTrack = artist.artistTracks![index];
                      return ArtistSong(
                        title: TextScroll(
                          thisTrack.trackData!.trackName!,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          velocity: defaultTextScrollvelocity,
                          delayBefore: delayBeforeScroll,
                        ),
                        subtitle: TextScroll(
                          thisTrack.mediaItem!.artist!,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          velocity: defaultTextScrollvelocity,
                          delayBefore: delayBeforeScroll,
                        ),
                        leading: getUriImage(thisTrack.mediaItem!.artUri),
                        track: thisTrack,
                        artist: artist,
                        index: index,
                      );
                    },
                  )
                ],
              ),
            ),
            CustomCard(
              theme: CardThemes().bottomSheetListHeaderTheme,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: TextScroll(
                        artist.artistName!,
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                        velocity: defaultTextScrollvelocity,
                        delayBefore: delayBeforeScroll,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(RemixIcon.arrow_down_double),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
