import 'package:antiiq/player/screens/playlists/playlist.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/state/list_states/playlists_state.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/utilities/pick_and_crop.dart';
import 'package:antiiq/player/widgets/image_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';
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
      barrierColor:
          AntiiQTheme.of(context).colorScheme.background.withAlpha(200),
      shape: AntiiQTheme.of(context).bottomSheetShape,
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          search(term) {
            searchResults = [];
            if (term != "") {
              for (Track track in antiiqState.music.tracks.list) {
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
                          style: AntiiQTheme.of(context)
                              .textStyles
                              .onBackgroundText,
                          cursorColor:
                              AntiiQTheme.of(context).colorScheme.primary,
                          controller: playlistTitleController,
                          decoration: InputDecoration(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 10.0),
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
                CustomCard(
                  theme: AntiiQTheme.of(context).cardThemes.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            onChanged: (term) {
                              search(term);
                            },
                            style: AntiiQTheme.of(context)
                                .textStyles
                                .onSurfaceText,
                            autofocus: false,
                            cursorColor:
                                AntiiQTheme.of(context).colorScheme.primary,
                            controller: playlistSearchController,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              hintText: "Start Typing to Add Music...",
                              hintStyle: AntiiQTheme.of(context)
                                  .textStyles
                                  .onSurfaceText,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            playlistSearchController.clear();
                            search("");
                          },
                          icon: Icon(
                            RemixIcon.close,
                            color:
                                AntiiQTheme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    "${selectedTracks.length} Selected Songs",
                    style: AntiiQTheme.of(context).textStyles.onBackgroundText,
                  ),
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
                        child: CustomCard(
                          theme: AntiiQTheme.of(context).cardThemes.surface,
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
                                          style: AntiiQTheme.of(context).textStyles.onSurfaceText,
                                        ),
                                        TextScroll(
                                          thisTrack
                                              .trackData!.trackArtistNames!,
                                          style: AntiiQTheme.of(context).textStyles.onSurfaceText,
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
                                    checkColor: AntiiQTheme.of(context).colorScheme.primary,
                                    fillColor: WidgetStatePropertyAll(AntiiQTheme.of(context).colorScheme.surface),
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
      await antiiqState.music.playlists.create(name, tracks: selectedTracks, art: art);
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
            itemCount: antiiqState.music.playlists.list.length,
            itemBuilder: (context, index) {
              final PlayList thisPlaylist = antiiqState.music.playlists.list[index];
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
