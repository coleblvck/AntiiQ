import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/screens/dashboard/dashboard_item_data.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';


List<DashboardItemData> generateDashboardItemData() {
  return [
    DashboardItemData(
      key: 'songs',
      title: "Songs",
      icon: RemixIcon.music,
      function: () {
        mainPageController.jumpToPage(
          mainPageIndexes["songs"] as int,
        );
      },
    ),
    DashboardItemData(
      key: 'albums',
      title: "Albums",
      icon: RemixIcon.album,
      function: () {
        mainPageController.jumpToPage(
          mainPageIndexes["albums"] as int,
        );
      },
    ),
    DashboardItemData(
      key: 'artists',
      title: "Artists",
      icon: RemixIcon.user_4,
      function: () {
        mainPageController.jumpToPage(
          mainPageIndexes["artists"] as int,
        );
      },
    ),
    DashboardItemData(
      key: 'genres',
      title: "Genres",
      icon: RemixIcon.keyboard,
      function: () {
        mainPageController.jumpToPage(
          mainPageIndexes["genres"] as int,
        );
      },
    ),
    DashboardItemData(
      key: 'playlists',
      title: "Playlists",
      icon: RemixIcon.play_list,
      function: () {
        mainPageController.jumpToPage(
          mainPageIndexes["playlists"] as int,
        );
      },
    ),
    DashboardItemData(
      key: 'favourites',
      title: "Favourites",
      icon: RemixIcon.heart_pulse,
      function: () {
        mainPageController.jumpToPage(
          mainPageIndexes["favourites"] as int,
        );
      },
    ),
    DashboardItemData(
      key: 'selection',
      title: "Selection",
      icon: RemixIcon.check_double,
      function: () {
        mainPageController.jumpToPage(
          mainPageIndexes["selection"] as int,
        );
      },
    ),
    DashboardItemData(
      key: 'history',
      title: "History",
      icon: RemixIcon.history,
      function: () {
        mainPageController.jumpToPage(
          mainPageIndexes["history"] as int,
        );
      },
    ),
    DashboardItemData(
      key: 'smartMix',
      title: "Smart Mix",
      icon: RemixIcon.radio,
      function: () {
        mainPageController.jumpToPage(
          mainPageIndexes["smartMix"] as int,
        );
      },
    ),
  ];
}
