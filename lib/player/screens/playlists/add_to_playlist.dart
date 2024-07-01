import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/utilities/pick_and_crop.dart';
import 'package:antiiq/player/widgets/image_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';
import 'package:text_scroll/text_scroll.dart';

addSelectionToPlaylistDialog(context, List<Track> tracks) {
  final TextEditingController playlistTitleController = TextEditingController();

  Uint8List? art;

  getArt() async {
    art = await pickAndCrop();
  }

  playlistCreate() async {
    if (playlistTitleController.text != "") {
      final String name = playlistTitleController.text;
      await antiiqState.music.playlists.create(name, tracks: tracks, art: art);
      playlistTitleController.clear();
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  showModalBottomSheet(
    useSafeArea: true,
    isScrollControlled: true,
    enableDrag: true,
    showDragHandle: true,
    shape: AntiiQTheme.of(context).bottomSheetShape,
    backgroundColor: AntiiQTheme.of(context).colorScheme.surface,
    context: context,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Text(
                      "New Playlist",
                      style: TextStyle(
                        fontSize: 20,
                        color: AntiiQTheme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  CustomCard(
                    theme: AntiiQTheme.of(context).cardThemes.background,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: TextField(
                                style: AntiiQTheme.of(context)
                                    .textStyles
                                    .onBackgroundText,
                                cursorColor:
                                AntiiQTheme.of(context).colorScheme.primary,
                                controller: playlistTitleController,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10.0),
                                  border: InputBorder.none,
                                  hintText: "Playlist Title",
                                  hintStyle: AntiiQTheme.of(context)
                                      .textStyles
                                      .onBackgroundText,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              await getArt();
                            },
                            icon: Icon(
                              RemixIcon.image,
                              color:
                                  AntiiQTheme.of(context).colorScheme.primary,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              playlistCreate();
                            },
                            icon: Icon(
                              RemixIcon.check,
                              color:
                                  AntiiQTheme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Text(
                "Other Playlists",
                style: TextStyle(
                  fontSize: 20,
                  color: AntiiQTheme.of(context).colorScheme.primary,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: antiiqState.music.playlists.list.length,
                itemExtent: 100,
                itemBuilder: (context, index) {
                  final thisPlaylist = antiiqState.music.playlists.list[index];
                  return GestureDetector(
                    onTap: () async {
                      await antiiqState.music.playlists.addTracks(thisPlaylist.playlistId!, tracks);
                      if (context.mounted) {
                        Navigator.of(context).pop();
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
                              child: getUriImage(thisPlaylist.playlistArt),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextScroll(
                                      thisPlaylist.playlistName!,
                                      style: AntiiQTheme.of(context)
                                          .textStyles
                                          .onBackgroundText,
                                    ),
                                    TextScroll(
                                      "${thisPlaylist.playlistTracks!.length} ${(thisPlaylist.playlistTracks!.length > 1) ? "Songs" : "song"}",
                                      style: AntiiQTheme.of(context)
                                          .textStyles
                                          .onBackgroundText,
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
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}
