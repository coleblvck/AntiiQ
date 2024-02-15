import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/utilities/file_handling/lists.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/utilities/user_settings.dart';

addOrRemoveFavourite(Track track) async {
  if (favourites.contains(track)) {
    await removeFromFavourites(track);
  } else {
    await addToFavourites(track);
  }
}

addToFavourites(Track track) async {
  favourites.add(track);
  favouritesStream.add(favourites);
  await saveFavourites();
}

removeFromFavourites(Track track) async {
  favourites.remove(track);
  favouritesStream.add(favourites);
  await saveFavourites();
}

clearFavourites() async {
  favourites = [];
  favouritesStream.add(favourites);
  await saveFavourites();
}

saveFavourites() async {
  final List<int> favouriteIds =
      favourites.map((track) => track.trackData!.trackId!).toList();
  await antiiqStore.put(BoxKeys().favourites, favouriteIds);
}

initFavourites() async {
  final List<int> favouriteIds =
      await antiiqStore.get(BoxKeys().favourites, defaultValue: <int>[]);
  favourites = [];
  for (int id in favouriteIds) {
    for (Track track in currentTrackListSort) {
      if (track.trackData!.trackId == id) {
        favourites.add(track);
      }
    }
  }
  favouritesStream.add(favourites);
}
