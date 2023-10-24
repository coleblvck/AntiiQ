import 'dart:io';
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/screens/selection_actions.dart';
import 'package:antiiq/player/utilities/duration_getters.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/utilities/file_handling/sort.dart';
import 'package:antiiq/player/widgets/list_header.dart';
import 'package:flutter/material.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';
import 'package:text_scroll/text_scroll.dart';

//Antiiq Packages
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/screens/albums/album_song.dart';
import 'package:antiiq/player/widgets/image_widgets.dart';

class AlbumItem extends StatelessWidget {
  final Widget title;
  final Widget subtitle;
  final Widget leading;
  final Album album;
  final int index;
  const AlbumItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.album,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: GestureDetector(
        onTap: () {
          showAlbum(context, album);
        },
        child: Container(
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background,
              backgroundBlendMode: BlendMode.colorDodge,
              image: DecorationImage(
                image: FileImage(
                  File.fromUri(album.albumArt!),
                ),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(10)),
          padding: EdgeInsets.zero,
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CustomCard(
                    theme: CardThemes().smallCardOnArtTheme,
                    child: IconButton(
                      onPressed: () {
                        doThingsWithAudioSheet(context, album.albumTracks!);
                      },
                      icon: const Icon(RemixIcon.menu_4),
                    ),
                  ),
                ],
              ),
              CustomCard(
                theme: CardThemes().smallCardOnArtTheme,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title,
                      subtitle,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

showAlbum(context, Album album) {
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
            StatefulBuilder(builder: (context, setState) {
              return Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: getUriImage(album.albumArt),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Album",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 20,
                              ),
                            ),
                            TextScroll(
                              album.albumName!,
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontSize: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              velocity: defaultTextScrollvelocity,
                              delayBefore: delayBeforeScroll,
                            ),
                            TextScroll(
                              album.albumArtistName!,
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                color:
                                    Theme.of(context).colorScheme.onBackground,
                              ),
                              velocity: defaultTextScrollvelocity,
                              delayBefore: delayBeforeScroll,
                            ),
                            (album.year != null)
                                ? Text(
                                    "${album.year}",
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onBackground,
                                    ),
                                  )
                                : Container(),
                            Card(
                              color: Theme.of(context).colorScheme.background,
                              surfaceTintColor: Colors.transparent,
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Text(
                                  "Length: ${totalDuration(album.albumTracks!)}",
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: ListHeader(
                        headerTitle: "Tracks",
                        listToCount: album.albumTracks,
                        listToShuffle: album.albumTracks!,
                        sortList: "allAlbumTracks",
                        availableSortTypes: albumTrackListSortTypes,
                        setState: setState,
                      ),
                    ),
                    SliverFixedExtentList.builder(
                      itemExtent: 100,
                      itemCount: album.albumTracks!.length,
                      itemBuilder: (context, index) {
                        final thisTrack = album.albumTracks![index];
                        return AlbumSong(
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
                          album: album,
                          index: index,
                        );
                      },
                    )
                  ],
                ),
              );
            }),
            CustomCard(
              theme: CardThemes().bottomSheetListHeaderTheme,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: TextScroll(
                        album.albumName!,
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
