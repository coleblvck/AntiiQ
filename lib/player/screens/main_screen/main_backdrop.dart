//Flutter Packages
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/screens/albums/albums.dart';
import 'package:antiiq/player/screens/artists/artists.dart';
//Antiiq Packages
import 'package:antiiq/player/screens/dashboard/dashboard.dart';
import 'package:antiiq/player/screens/equalizer/equalizer.dart';
import 'package:antiiq/player/screens/favourites/favourites.dart';
import 'package:antiiq/player/screens/genres/genres.dart';
import 'package:antiiq/player/screens/history/history.dart';
import 'package:antiiq/player/screens/main_screen/main_box.dart';
import 'package:antiiq/player/screens/playlists/playlists.dart';
import 'package:antiiq/player/screens/search/search.dart';
import 'package:antiiq/player/screens/selection/selection.dart';
import 'package:antiiq/player/screens/songs/songs.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/playlist_generator/playlist_generator_widgets.dart';
import 'package:flutter/material.dart';

class MainBackdrop extends StatelessWidget {
  const MainBackdrop({
    super.key,
  });

@override
Widget build(BuildContext context) {
  return Card(
    elevation: 0,
    color: AntiiQTheme.of(context).colorScheme.background,
    clipBehavior: Clip.hardEdge,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
    margin: EdgeInsets.zero,
    child: Column(
      children: [
        Expanded(
          child: PageView(
            controller: mainPageController,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              Dashboard(),
              Equalizer(),
              Search(),
              SongsList(),
              AlbumsGrid(),
              ArtistsList(),
              GenresGrid(),
              Playlists(),
              FavouritesList(),
              SelectionList(),
              HistoryList(),
              PlaylistGenerationScreen(),
            ],
          ),
        ),
        SizedBox(height: MainBoxMetrics.minHeightBox,)
      ],
    ),
  );
}
}