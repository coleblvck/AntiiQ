//Icons
import 'package:remix_icon_icons/remix_icon_icons.dart';

//Antiiq Packages
import 'package:antiiq/player/global_variables.dart';

dashboardItems(context) => {
      "songs": {
        "title": "Songs",
        "icon": RemixIcon.music,
        "function": () {
          mainPageController.jumpToPage(
            mainPageIndexes["songs"] as int,
          );
        },
      },
      "albums": {
        "title": "Albums",
        "icon": RemixIcon.album,
        "function": () {
          mainPageController.jumpToPage(
            mainPageIndexes["albums"] as int,
          );
        },
      },
      "artists": {
        "title": "Artists",
        "icon": RemixIcon.user_4,
        "function": () {
          mainPageController.jumpToPage(
            mainPageIndexes["artists"] as int,
          );
        },
      },
      "genres": {
        "title": "Genres",
        "icon": RemixIcon.keyboard,
        "function": () {
          mainPageController.jumpToPage(
            mainPageIndexes["genres"] as int,
          );
        },
      },
      "playlists": {
        "title": "Playlists",
        "icon": RemixIcon.play_list,
        "function": () {
          mainPageController.jumpToPage(
            mainPageIndexes["playlists"] as int,
          );
        },
      },
      "selection": {
        "title": "Selection",
        "icon": RemixIcon.check_double,
        "function": () {
          mainPageController.jumpToPage(
            mainPageIndexes["selection"] as int,
          );
        },
      },
    };
