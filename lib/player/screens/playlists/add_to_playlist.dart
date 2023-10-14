import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/utilities/playlisting/playlisting.dart';
import 'package:flutter/material.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/files/metadata.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:antiiq/player/widgets/image_widgets.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';
import 'package:flutter/services.dart';
import 'package:antiiq/player/utilities/pick_and_crop.dart';

addSelectionToPlaylistDialog(context, List<Track> tracks) {
  final TextEditingController playlistTitleController = TextEditingController();

  Uint8List? art;

  getArt() async {
    art = await pickAndCrop();
  }

  playlistCreate() async {
    if (playlistTitleController.text != "") {
      final String name = playlistTitleController.text;
      await createPlaylist(name, tracks: tracks, art: art);
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
    shape: bottomSheetShape,
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
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  CustomCard(
                    theme: CardThemes().bgColor,
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: TextField(
                              controller: playlistTitleController,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(horizontal: 10.0),
                                  hintText: "Playlist Title"),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            await getArt();
                          },
                          icon: const Icon(
                            RemixIcon.image,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            playlistCreate();
                          },
                          icon: const Icon(
                            RemixIcon.check,
                          ),
                        ),
                      ],
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
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: allPlaylists.length,
                itemExtent: 100,
                itemBuilder: (context, index) {
                  final thisPlaylist = allPlaylists[index];
                  return GestureDetector(
                    onTap: () async {
                      await addToPlaylist(thisPlaylist.playlistId!, tracks);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: CustomCard(
                      theme: CardThemes().songsItemTheme,
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
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
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}
