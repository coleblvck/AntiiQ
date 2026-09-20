import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/screens/dashboard/dashboard_item_data.dart';
import 'package:remixicon/remixicon.dart';

List<DashboardItemData> generateDashboardItemData() {
  return [
    DashboardItemData(
      key: 'songs',
      title: "Songs",
      icon: RemixIcons.music_fill,
      function: () {
        mainPageController.jumpToPage(
          mainPageIndexes["songs"] as int,
        );
      },
    ),
    DashboardItemData(
      key: 'albums',
      title: "Albums",
      icon: RemixIcons.album_fill,
      function: () {
        mainPageController.jumpToPage(
          mainPageIndexes["albums"] as int,
        );
      },
    ),
    DashboardItemData(
      key: 'artists',
      title: "Artists",
      icon: RemixIcons.user_4_fill,
      function: () {
        mainPageController.jumpToPage(
          mainPageIndexes["artists"] as int,
        );
      },
    ),
    DashboardItemData(
      key: 'albumArtists',
      title: "Album Artists",
      icon: RemixIcons.user_star_fill,
      function: () =>
          mainPageController.jumpToPage(mainPageIndexes["albumArtists"] as int),
    ),
    DashboardItemData(
      key: 'folders',
      title: "Folders",
      icon: RemixIcons.folder_music_fill,
      function: () =>
          mainPageController.jumpToPage(mainPageIndexes["folders"] as int),
    ),
    DashboardItemData(
      key: 'genres',
      title: "Genres",
      icon: RemixIcons.keyboard_fill,
      function: () {
        mainPageController.jumpToPage(
          mainPageIndexes["genres"] as int,
        );
      },
    ),
    DashboardItemData(
      key: 'playlists',
      title: "Playlists",
      icon: RemixIcons.play_list_fill,
      function: () {
        mainPageController.jumpToPage(
          mainPageIndexes["playlists"] as int,
        );
      },
    ),
    DashboardItemData(
      key: 'favourites',
      title: "Favourites",
      icon: RemixIcons.heart_pulse_fill,
      function: () {
        mainPageController.jumpToPage(
          mainPageIndexes["favourites"] as int,
        );
      },
    ),
    DashboardItemData(
      key: 'selection',
      title: "Selection",
      icon: RemixIcons.check_double_fill,
      function: () {
        mainPageController.jumpToPage(
          mainPageIndexes["selection"] as int,
        );
      },
    ),
    DashboardItemData(
      key: 'history',
      title: "History",
      icon: RemixIcons.history_fill,
      function: () {
        mainPageController.jumpToPage(
          mainPageIndexes["history"] as int,
        );
      },
    ),
    DashboardItemData(
      key: 'smartMix',
      title: "Smart Mix",
      icon: RemixIcons.radio_fill,
      function: () {
        mainPageController.jumpToPage(
          mainPageIndexes["smartMix"] as int,
        );
      },
    ),
  ];
}
