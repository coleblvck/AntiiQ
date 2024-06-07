import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/screens/albums/album.dart';
import 'package:antiiq/player/screens/artists/artist.dart';
import 'package:antiiq/player/widgets/song_cards/song_card.dart';
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
  List<Album> albumResults = [];
  List<Artist> artistResults = [];
  TextEditingController searchController = TextEditingController();
  search(term) {
    searchResults = [];
    albumResults = [];
    artistResults = [];
    if (term != "") {
      for (Track track in currentTrackListSort) {
        if (track.trackData!.trackName!
            .toLowerCase()
            .contains(term.toLowerCase())) {
          searchResults.add(track);
        }
      }
      for (Album album in currentAlbumListSort) {
        if (album.albumName!.toLowerCase().contains(term.toLowerCase())) {
          albumResults.add(album);
        }
      }

      for (Artist artist in currentArtistListSort) {
        if (artist.artistName!.toLowerCase().contains(term.toLowerCase())) {
          artistResults.add(artist);
        }
      }
    }
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
                      textAlignVertical: TextAlignVertical.center,
                      style: TextStyles().onSurfaceText,
                      autofocus: false,
                      controller: searchController,
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          RemixIcon.search,
                          color: AntiiQTheme.of(context).colorScheme.primary,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                        hintText: "Start Typing to Search...",
                        hintStyle: TextStyles().onSurfaceText,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      searchController.clear();
                      search("");
                    },
                    icon: Icon(
                      RemixIcon.close,
                      color: AntiiQTheme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                searchResults.isNotEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Text(
                            "Tracks:",
                            style: TextStyle(
                              color:
                                  AntiiQTheme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      )
                    : SliverToBoxAdapter(child: Container()),
                SliverFixedExtentList.builder(
                  itemExtent: 100,
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final Track thisTrack = searchResults[index];
                    final PageController controller = PageController();
                    return SongCard(
                      controller: controller,
                      title: TextScroll(
                        thisTrack.trackData!.trackName!,
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: AntiiQTheme.of(context).colorScheme.onSurface,
                        ),
                        velocity: defaultTextScrollvelocity,
                        delayBefore: delayBeforeScroll,
                      ),
                      subtitle: TextScroll(
                        thisTrack.mediaItem!.artist!,
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: AntiiQTheme.of(context).colorScheme.onSurface,
                        ),
                        velocity: defaultTextScrollvelocity,
                        delayBefore: delayBeforeScroll,
                      ),
                      leading: getUriImage(thisTrack.mediaItem!.artUri),
                      track: thisTrack,
                      selectionList: "album",
                      albumToPlay:
                          searchResults.map((e) => e.mediaItem!).toList(),
                      index: index,
                    );
                  },
                ),
                albumResults.isNotEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Text(
                            "Albums:",
                            style: TextStyle(
                              color:
                                  AntiiQTheme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      )
                    : SliverToBoxAdapter(child: Container()),
                SliverFixedExtentList.builder(
                    itemExtent: 100,
                    itemCount: albumResults.length,
                    itemBuilder: (context, index) {
                      final Album thisAlbum = albumResults[index];

                      return GestureDetector(
                        onTap: () {
                          showAlbum(context, thisAlbum);
                        },
                        child: CustomCard(
                            theme: CardThemes().surfaceColor,
                            child: Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 80,
                                    child: AspectRatio(
                                      aspectRatio: 1,
                                      child: getUriImage(thisAlbum.albumArt),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          TextScroll(
                                            thisAlbum.albumName!,
                                            style: TextStyle(
                                              color: AntiiQTheme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                            ),
                                          ),
                                          TextScroll(
                                            "${thisAlbum.numOfSongs!} Songs",
                                            style: TextStyle(
                                              color: AntiiQTheme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      );
                    }),
                artistResults.isNotEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Text(
                            "Artists:",
                            style: TextStyle(
                              color:
                                  AntiiQTheme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      )
                    : SliverToBoxAdapter(child: Container()),
                SliverFixedExtentList.builder(
                    itemExtent: 100,
                    itemCount: artistResults.length,
                    itemBuilder: (context, index) {
                      final Artist thisArtist = artistResults[index];

                      return GestureDetector(
                        onTap: () {
                          showArtist(context, thisArtist);
                        },
                        child: CustomCard(
                            theme: CardThemes().primaryColor,
                            child: Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 80,
                                    child: AspectRatio(
                                      aspectRatio: 1,
                                      child: getUriImage(thisArtist.artistArt),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          TextScroll(
                                            thisArtist.artistName!,
                                            style: TextStyle(
                                              color: AntiiQTheme.of(context)
                                                  .colorScheme
                                                  .onPrimary,
                                            ),
                                          ),
                                          TextScroll(
                                            "${thisArtist.artistTracks!.length} Songs",
                                            style: TextStyle(
                                              color: AntiiQTheme.of(context)
                                                  .colorScheme
                                                  .onPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      );
                    }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
