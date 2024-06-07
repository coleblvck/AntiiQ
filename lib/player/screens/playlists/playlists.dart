import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/screens/playlists/playlist.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/file_handling/lists.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/utilities/pick_and_crop.dart';
import 'package:antiiq/player/widgets/image_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';
import 'package:antiiq/player/utilities/playlisting/playlisting.dart';
import 'package:text_scroll/text_scroll.dart';

class Playlists extends StatefulWidget {
  const Playlists({
    super.key,
  });
  @override
  State<Playlists> createState() => _PlaylistsState();
}

class _PlaylistsState extends State<Playlists> {
  @override
  dispose() {
    playlistTitleController.dispose();
    playlistSearchController.dispose();
    super.dispose();
  }

  playlistCreationSheet() {
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
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          search(term) {
            searchResults = [];
            if (term != "") {
              for (Track track in currentTrackListSort) {
                if (track.trackData!.trackName!
                    .toLowerCase()
                    .contains(term.toLowerCase())) {
                  searchResults.add(track);
                }
              }
            }
            setState(() {});
          }

          selectOrDeselect(Track track) {
            if (selectedTracks.contains(track)) {
              selectedTracks.remove(track);
            } else {
              selectedTracks.add(track);
            }

            setState(() {});
          }

          return Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: TextField(
                          controller: playlistTitleController,
                          decoration: const InputDecoration(
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 10.0),
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
                CustomCard(
                  theme: CardThemes().searchBoxTheme,
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            onChanged: (term) {
                              search(term);
                            },
                            controller: playlistSearchController,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: "Start Typing to Search...",
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            playlistSearchController.clear();
                            search("");
                          },
                          icon: const Icon(
                            RemixIcon.close,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text("${selectedTracks.length} Selected Songs"),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: searchResults.length,
                    itemExtent: 80,
                    itemBuilder: (context, index) {
                      final Track thisTrack = searchResults[index];
                      return GestureDetector(
                        onTap: () {
                          selectOrDeselect(thisTrack);
                        },
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  height: 60,
                                  child:
                                      getUriImage(thisTrack.mediaItem!.artUri),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        TextScroll(
                                          thisTrack.trackData!.trackName!,
                                        ),
                                        TextScroll(
                                          thisTrack
                                              .trackData!.trackArtistNames!,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 30,
                                  child: Checkbox(
                                    value: (selectedTracks.contains(thisTrack)),
                                    onChanged: null,
                                  ),
                                )
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
      ),
    );
  }

  List<Track> searchResults = [];
  List<Track> selectedTracks = [];

  TextEditingController playlistTitleController = TextEditingController();
  TextEditingController playlistSearchController = TextEditingController();

  Uint8List? art;

  getArt() async {
    art = await pickAndCrop();
  }

  playlistCreate() async {
    if (playlistTitleController.text != "") {
      final String name = playlistTitleController.text;
      await createPlaylist(name, tracks: selectedTracks, art: art);
      playlistTitleController.clear();
      playlistSearchController.clear();
      selectedTracks = [];
      if (mounted) {
        stateSet();
        Navigator.of(context).pop();
      }
    }
  }

  stateSet() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 40,
          child: CustomButton(
            style: ButtonStyles().style3,
            function: () {
              playlistCreationSheet();
            },
            child: const Text("Create Playlist"),
          ),
        ),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
            ),
            itemCount: allPlaylists.length,
            itemBuilder: (context, index) {
              final PlayList thisPlaylist = allPlaylists[index];
              return PlaylistItem(
                thisPlaylist: thisPlaylist,
                mainPageStateSet: setState,
              );
            },
          ),
        ),
      ],
    );
  }
}
