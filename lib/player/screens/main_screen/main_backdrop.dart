//Flutter Packages
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/screens/albums/albums.dart';
import 'package:antiiq/player/screens/artists/artists.dart';
//Antiiq Packages
import 'package:antiiq/player/screens/dashboard/dashboard.dart';
import 'package:antiiq/player/screens/equalizer/equalizer.dart';
import 'package:antiiq/player/screens/favourites/favourites.dart';
import 'package:antiiq/player/screens/genres/genres.dart';
import 'package:antiiq/player/screens/playlists/playlists.dart';
import 'package:antiiq/player/screens/search/search.dart';
import 'package:antiiq/player/screens/selection/selection.dart';
import 'package:antiiq/player/screens/songs/songs.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:flutter/material.dart';

class MainBackdrop extends StatelessWidget {
  const MainBackdrop({
    super.key,
  });

@override
Widget build(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 25),
    child: Padding(
      padding: const EdgeInsets.all(2.0),
      child: Card(
        color: AntiiQTheme.of(context).colorScheme.background,
        clipBehavior: Clip.hardEdge,
        margin: EdgeInsets.zero,
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
          ],
        ),
      ),
    ),
  );
}
}