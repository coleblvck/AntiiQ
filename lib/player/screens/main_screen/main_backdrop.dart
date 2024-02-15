//Flutter Packages
import 'package:antiiq/player/screens/artists/artists.dart';
import 'package:antiiq/player/screens/equalizer/equalizer.dart';
import 'package:antiiq/player/screens/favourites/favourites.dart';
import 'package:antiiq/player/screens/genres/genres.dart';
import 'package:antiiq/player/screens/playlists/playlists.dart';
import 'package:antiiq/player/screens/search/search.dart';
import 'package:antiiq/player/screens/selection/selection.dart';
import 'package:flutter/material.dart';

//Antiiq Packages
import 'package:antiiq/player/screens/dashboard/dashboard.dart';
import 'package:antiiq/player/screens/songs/songs.dart';
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/screens/albums/albums.dart';

Widget mainBackdrop() {
  return Padding(
    padding: const EdgeInsets.only(bottom: 35),
    child: Padding(
      padding: const EdgeInsets.all(5.0),
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
  );
}
