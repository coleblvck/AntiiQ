import 'dart:io';

import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/screens/playlists/playlist_song.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/duration_getters.dart';
import 'package:antiiq/player/utilities/pick_and_crop.dart';
import 'package:antiiq/player/state/list_states/playlists_state.dart';
import 'package:antiiq/player/widgets/image_widgets.dart';
import 'package:antiiq/player/widgets/list_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:antiiq/player/state/antiiq_state.dart';

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
            borderRadius: BorderRadius.circular(generalRadius),
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
                theme: AntiiQTheme.of(context).cardThemes.background,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 5.0, horizontal: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextScroll(
                        thisPlaylist.playlistName!,
                        style:
                            AntiiQTheme.of(context).textStyles.onBackgroundText,
                      ),
                      TextScroll(
                        "${thisPlaylist.playlistTracks!.length} ${(thisPlaylist.playlistTracks!.length > 1) ? "Songs" : "song"}",
                        style:
                            AntiiQTheme.of(context).textStyles.onBackgroundText,
                      ),
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
    backgroundColor: AntiiQTheme.of(context).colorScheme.background,
    showDragHandle: true,
    barrierColor: AntiiQTheme.of(context).colorScheme.background.withAlpha(200),
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
                        padding: const EdgeInsets.all(5.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextScroll(
                              playlist.playlistName!,
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontSize: 25,
                                color:
                                    AntiiQTheme.of(context).colorScheme.primary,
                              ),
                              velocity: defaultTextScrollvelocity,
                              delayBefore: delayBeforeScroll,
                            ),
                            Card(
                              color: AntiiQTheme.of(context)
                                  .colorScheme
                                  .background,
                              surfaceTintColor: Colors.transparent,
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Text(
                                  "Length: ${totalDuration(playlist.playlistTracks!)}",
                                  style: TextStyle(
                                    color: AntiiQTheme.of(context)
                                        .colorScheme
                                        .primary,
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
                        listToCount: playlist.playlistTracks,
                        listToShuffle: playlist.playlistTracks!,
                        sortList: "none",
                        availableSortTypes: const [],
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
                        await state.music.playlists.savePlaylist(playlist.playlistId!);
                      },
                      itemExtent: 100,
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
                              color:
                                  AntiiQTheme.of(context).colorScheme.onSurface,
                            ),
                            velocity: defaultTextScrollvelocity,
                            delayBefore: delayBeforeScroll,
                          ),
                          subtitle: TextScroll(
                            thisTrack.mediaItem!.artist!,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color:
                                  AntiiQTheme.of(context).colorScheme.onSurface,
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
                theme: AntiiQTheme.of(context).cardThemes.background,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: TextScroll(
                          playlist.playlistName!,
                          textAlign: TextAlign.left,
                          style: AntiiQTheme.of(context)
                              .textStyles
                              .onBackgroundText,
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
                      icon: Icon(
                        RemixIcon.edit,
                        color: AntiiQTheme.of(context).colorScheme.primary,
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        await state.music.playlists.deletePlaylist(playlist);
                        if (context.mounted) {
                          mainPageStateSet(() {});
                          Navigator.of(context).pop();
                        }
                      },
                      icon: const Icon(
                        RemixIcon.delete_bin_2,
                        color: Colors.red,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: Icon(
                        RemixIcon.arrow_down_double,
                        color: AntiiQTheme.of(context).colorScheme.onBackground,
                      ),
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
    await state.music.playlists.updatePlaylist(playlist.playlistId!,
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
    backgroundColor: AntiiQTheme.of(context).colorScheme.surface,
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
                    style: AntiiQTheme.of(context).textStyles.onSurfaceText,
                    decoration: InputDecoration(
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: AntiiQTheme.of(context).colorScheme.primary),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: AntiiQTheme.of(context).colorScheme.primary),
                      ),
                    ),
                    controller: titleController,
                  ),
                ),
                CustomButton(
                  style: AntiiQTheme.of(context).buttonStyles.style2,
                  function: () async {
                    await selectArt();
                  },
                  child: const Text("Select Image"),
                ),
                Text(
                  "Note: Changes to art may not reflect until restart.",
                  style: AntiiQTheme.of(context).textStyles.onSurfaceText,
                ),
                CustomButton(
                  style: AntiiQTheme.of(context).buttonStyles.style3,
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
