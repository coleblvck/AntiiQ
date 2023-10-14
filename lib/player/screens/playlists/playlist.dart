import 'dart:io';

import 'package:antiiq/player/screens/playlists/playlist_song.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/widgets/image_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';
import 'package:antiiq/player/utilities/playlisting/playlisting.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/widgets/list_header.dart';
import 'package:antiiq/player/utilities/pick_and_crop.dart';

class PlaylistItem extends StatelessWidget {
  const PlaylistItem({
    super.key,
    required this.thisPlaylist,
    required this.mainPageStateSet,
  });

  final PlayList thisPlaylist;
  final Function mainPageStateSet;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: GestureDetector(
        onTap: () {
          showPlaylist(context, thisPlaylist, mainPageStateSet);
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            image: DecorationImage(
              image: FileImage(
                File.fromUri(
                  thisPlaylist.playlistArt!,
                ),
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomCard(
                theme: CardThemes().smallCardOnArtTheme,
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextScroll(thisPlaylist.playlistName!),
                      TextScroll(
                          "${thisPlaylist.playlistTracks!.length} ${(thisPlaylist.playlistTracks!.length > 1) ? "Songs" : "song"}"),
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

showPlaylist(context, PlayList playlist, Function mainPageStateSet) {
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
    builder: (context) => StatefulBuilder(builder: (context, setState) {
      return Padding(
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
                        child: getUriImage(playlist.playlistArt),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextScroll(
                              playlist.playlistName!,
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontSize: 25,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              velocity: defaultTextScrollvelocity,
                              delayBefore: delayBeforeScroll,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: ListHeader(
                        headerTitle: "Tracks",
                        listToCount: playlist.playlistTracks,
                        listToShuffle: playlist.playlistTracks!,
                      ),
                    ),
                    SliverReorderableList(
                      onReorder: (oldIndex, newIndex) async {
                        setState(() {
                          if (newIndex > oldIndex) {
                            newIndex -= 1;
                          }

                          final track =
                              playlist.playlistTracks!.removeAt(oldIndex);
                          playlist.playlistTracks!.insert(newIndex, track);
                        });
                        await savePlaylistToStore(playlist.playlistId!);
                      },
                      itemExtent: 120,
                      itemCount: playlist.playlistTracks!.length,
                      itemBuilder: (context, index) {
                        final thisTrack = playlist.playlistTracks![index];
                        return PlaylistSong(
                          key: ValueKey(thisTrack),
                          setState: setState,
                          mainPageStateSet: mainPageStateSet,
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
                          playlist: playlist,
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
                          playlist.playlistName!,
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
                        showPlaylistEditDialog(
                            context, mainPageStateSet, setState, playlist);
                      },
                      icon: const Icon(RemixIcon.edit),
                    ),
                    IconButton(
                      onPressed: () async {
                        await deletePlaylist(playlist);
                        if (context.mounted) {
                          mainPageStateSet(() {});
                          Navigator.of(context).pop();
                        }
                      },
                      icon: const Icon(RemixIcon.delete_bin_2),
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
      );
    }),
  );
}

showPlaylistEditDialog(
    context, Function mainPageStateSet, Function setState, PlayList playlist) {
  TextEditingController titleController = TextEditingController();
  titleController.text = playlist.playlistName!;
  Uint8List? art;
  playlistUpdate() async {
    await updatePlaylist(playlist.playlistId!,
        name: titleController.text, art: art);

    setState(() {});
    mainPageStateSet(() {});
    Navigator.of(context).pop();
  }

  selectArt() async {
    art = await pickAndCrop();
  }

  showModalBottomSheet(
    isScrollControlled: true,
    context: context,
    builder: (context) {
      return SizedBox(
        height: 220 + MediaQuery.of(context).viewInsets.bottom,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: TextField(
                    controller: titleController,
                  ),
                ),
                CustomButton(
                  style: ButtonStyles().style2,
                  function: () async {
                    await selectArt();
                  },
                  child: const Text("Select Image"),
                ),
                const Text("Note: Changes to art may not reflect until restart."),
                CustomButton(
                  style: ButtonStyles().style3,
                  function: () async {
                    await playlistUpdate();
                  },
                  child: const Text("Update Playlist"),
                ),
                SizedBox(
                  height: MediaQuery.of(context).viewInsets.bottom,
                ),
              ]),
        ),
      );
    },
  );
}
