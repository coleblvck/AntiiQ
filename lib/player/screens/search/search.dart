import 'package:antiiq/player/utilities/activity_handlers.dart';
import 'package:antiiq/player/screens/playlists/add_to_playlist.dart';
import 'package:flutter/material.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/utilities/file_handling/lists.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:antiiq/player/widgets/image_widgets.dart';

class Search extends StatefulWidget {
  const Search({
    super.key,
  });

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  List<Track> searchResults = [];
  List<Track> selectedTracks = [];
  TextEditingController searchController = TextEditingController();
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

  clearSelection() {
    selectedTracks = [];
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                      controller: searchController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Start Typing to Search...",
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      searchController.clear();
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
            child: selectedTracks.isNotEmpty
                ? SizedBox(
                  height: 25,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text("${selectedTracks.length} Selected Songs"),
                        IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            clearSelection();
                          },
                          icon: const Icon(RemixIcon.close_circle),
                        )
                      ],
                    ),
                )
                : Container(),
          ),
          selectedTracks.isNotEmpty
              ? SizedBox(
                height: 30,
                child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: CustomButton(
                            style: ButtonStyles().style1,
                            function: () {
                              addSelectionToPlaylistDialog(
                                  context, selectedTracks);
                            },
                            child: const Text("Add Selection to Playlist"),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: CustomButton(
                            style: ButtonStyles().style2,
                            function: () {
                              shuffleTracks(selectedTracks);
                            },
                            child: const Text("Shuffle Selection"),
                          ),
                        ),
                      ],
                    ),
                  ),
              )
              : Container(),
          Expanded(
            child: ListView.builder(
              itemCount: searchResults.length,
              itemExtent: 80,
              itemBuilder: (context, index) {
                final Track thisTrack = searchResults[index];
                return GestureDetector(
                  onLongPress: () {
                    selectedTracks.isEmpty ? selectOrDeselect(thisTrack) : null;
                  },
                  onTap: () {
                    selectedTracks.isNotEmpty
                        ? selectOrDeselect(thisTrack)
                        : playOnlyThis(thisTrack.mediaItem!);
                  },
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Row(
                        children: [
                          SizedBox(
                            height: 80,
                            child: getUriImage(thisTrack.mediaItem!.artUri),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextScroll(
                                    thisTrack.trackData!.trackName!,
                                  ),
                                  TextScroll(
                                    thisTrack.trackData!.trackArtistNames!,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 30,
                            child: selectedTracks.isNotEmpty
                                ? Checkbox(
                                    value: (selectedTracks.contains(thisTrack)),
                                    onChanged: null,
                                  )
                                : Container(),
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
  }
}
