import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';

enum AntiiqSortType {
  trackName,
  artistName,
  albumName,
  genreName,
  trackList,
  duration,
  trackNumber;
}

enum SortDirection {
  ascending,
  descending;
}

final List<String> trackListSortTypes = [
  "Track Name",
  "Artist Name",
  "Album Name",
  "Duration",
];

sortTracks(
  SortDirection direction,
  AntiiqSortType sortType,
  List<Track> trackListToSort,
) async {
  if (sortType == AntiiqSortType.trackName) {
    if (direction == SortDirection.ascending) {
      trackListToSort.sort(
        (a, b) => a.trackData!.trackName!
            .toLowerCase()
            .compareTo(b.trackData!.trackName!.toLowerCase()),
      );
    } else {
      trackListToSort.sort(
        (a, b) => b.trackData!.trackName!
            .toLowerCase()
            .compareTo(a.trackData!.trackName!.toLowerCase()),
      );
    }
  } else if (sortType == AntiiqSortType.artistName) {
    if (direction == SortDirection.ascending) {
      trackListToSort.sort(
        (a, b) => a.trackData!.trackArtistNames!
            .toLowerCase()
            .compareTo(b.trackData!.trackArtistNames!.toLowerCase()),
      );
    } else {
      trackListToSort.sort(
        (a, b) => b.trackData!.trackArtistNames!
            .toLowerCase()
            .compareTo(a.trackData!.trackArtistNames!.toLowerCase()),
      );
    }
  } else if (sortType == AntiiqSortType.albumName) {
    if (direction == SortDirection.ascending) {
      trackListToSort.sort(
        (a, b) => a.trackData!.albumName!
            .toLowerCase()
            .compareTo(b.trackData!.albumName!.toLowerCase()),
      );
    } else {
      trackListToSort.sort(
        (a, b) => b.trackData!.albumName!
            .toLowerCase()
            .compareTo(a.trackData!.albumName!.toLowerCase()),
      );
    }
  } else if (sortType == AntiiqSortType.duration) {
    if (direction == SortDirection.ascending) {
      trackListToSort.sort(
        (a, b) =>
            a.trackData!.trackDuration!.compareTo(b.trackData!.trackDuration!),
      );
    } else {
      trackListToSort.sort(
        (a, b) =>
            b.trackData!.trackDuration!.compareTo(a.trackData!.trackDuration!),
      );
    }
  } else if (sortType == AntiiqSortType.trackNumber) {
    if (direction == SortDirection.ascending) {
      trackListToSort.sort(
        (a, b) =>
            a.trackData!.trackNumber!.compareTo(b.trackData!.trackNumber!),
      );
    } else {
      trackListToSort.sort(
        (a, b) =>
            b.trackData!.trackNumber!.compareTo(a.trackData!.trackNumber!),
      );
    }
  }
}

final List<String> albumListSortTypes = [
  "Album Name",
  "Artist Name",
  "Track List",
  "Duration",
];

sortAlbums(
  SortDirection direction,
  AntiiqSortType sortType,
  List<Album> albumListToSort,
) async {
  if (sortType == AntiiqSortType.albumName) {
    if (direction == SortDirection.ascending) {
      albumListToSort.sort(
        (a, b) =>
            a.albumName!.toLowerCase().compareTo(b.albumName!.toLowerCase()),
      );
    } else {
      albumListToSort.sort(
        (a, b) =>
            b.albumName!.toLowerCase().compareTo(a.albumName!.toLowerCase()),
      );
    }
  } else if (sortType == AntiiqSortType.artistName) {
    if (direction == SortDirection.ascending) {
      albumListToSort.sort(
        (a, b) => a.albumArtistName!
            .toLowerCase()
            .compareTo(b.albumArtistName!.toLowerCase()),
      );
    } else {
      albumListToSort.sort(
        (a, b) => b.albumArtistName!
            .toLowerCase()
            .compareTo(a.albumArtistName!.toLowerCase()),
      );
    }
  } else if (sortType == AntiiqSortType.trackList) {
    if (direction == SortDirection.ascending) {
      albumListToSort.sort(
        (a, b) => a.albumTracks!.length.compareTo(b.albumTracks!.length),
      );
    } else {
      albumListToSort.sort(
        (a, b) => b.albumTracks!.length.compareTo(a.albumTracks!.length),
      );
    }
  } else if (sortType == AntiiqSortType.duration) {
    if (direction == SortDirection.ascending) {
      albumListToSort.sort(
        (a, b) => durationSum(
                a.albumTracks!.map((e) => e.trackData!.trackDuration!).toList())
            .compareTo(durationSum(b.albumTracks!
                .map((e) => e.trackData!.trackDuration!)
                .toList())),
      );
    } else {
      albumListToSort.sort(
        (a, b) => durationSum(
                b.albumTracks!.map((e) => e.trackData!.trackDuration!).toList())
            .compareTo(durationSum(a.albumTracks!
                .map((e) => e.trackData!.trackDuration!)
                .toList())),
      );
    }
  }
}

final List<String> artistListSortTypes = [
  "Artist Name",
  "Track List",
  "Duration",
];

sortArtists(
  SortDirection direction,
  AntiiqSortType sortType,
  List<Artist> artistListToSort,
) async {
  if (sortType == AntiiqSortType.artistName) {
    if (direction == SortDirection.ascending) {
      artistListToSort.sort(
        (a, b) =>
            a.artistName!.toLowerCase().compareTo(b.artistName!.toLowerCase()),
      );
    } else {
      artistListToSort.sort(
        (a, b) =>
            b.artistName!.toLowerCase().compareTo(a.artistName!.toLowerCase()),
      );
    }
  } else if (sortType == AntiiqSortType.trackList) {
    if (direction == SortDirection.ascending) {
      artistListToSort.sort(
        (a, b) => a.artistTracks!.length.compareTo(b.artistTracks!.length),
      );
    } else {
      artistListToSort.sort(
        (a, b) => b.artistTracks!.length.compareTo(a.artistTracks!.length),
      );
    }
  } else if (sortType == AntiiqSortType.duration) {
    if (direction == SortDirection.ascending) {
      artistListToSort.sort(
        (a, b) => durationSum(a.artistTracks!
                .map((e) => e.trackData!.trackDuration!)
                .toList())
            .compareTo(durationSum(b.artistTracks!
                .map((e) => e.trackData!.trackDuration!)
                .toList())),
      );
    } else {
      artistListToSort.sort(
        (a, b) => durationSum(b.artistTracks!
                .map((e) => e.trackData!.trackDuration!)
                .toList())
            .compareTo(durationSum(a.artistTracks!
                .map((e) => e.trackData!.trackDuration!)
                .toList())),
      );
    }
  }
}

final List<String> genreListSortTypes = [
  "Genre Name",
  "Track List",
  "Duration",
];

sortGenres(
  SortDirection direction,
  AntiiqSortType sortType,
  List<Genre> genreListToSort,
) async {
  if (sortType == AntiiqSortType.genreName) {
    if (direction == SortDirection.ascending) {
      genreListToSort.sort(
        (a, b) =>
            a.genreName!.toLowerCase().compareTo(b.genreName!.toLowerCase()),
      );
    } else {
      genreListToSort.sort(
        (a, b) =>
            b.genreName!.toLowerCase().compareTo(a.genreName!.toLowerCase()),
      );
    }
  } else if (sortType == AntiiqSortType.trackList) {
    if (direction == SortDirection.ascending) {
      genreListToSort.sort(
        (a, b) => a.genreTracks!.length.compareTo(b.genreTracks!.length),
      );
    } else {
      genreListToSort.sort(
        (a, b) => b.genreTracks!.length.compareTo(a.genreTracks!.length),
      );
    }
  } else if (sortType == AntiiqSortType.duration) {
    if (direction == SortDirection.ascending) {
      genreListToSort.sort(
        (a, b) => durationSum(
                a.genreTracks!.map((e) => e.trackData!.trackDuration!).toList())
            .compareTo(durationSum(b.genreTracks!
                .map((e) => e.trackData!.trackDuration!)
                .toList())),
      );
    } else {
      genreListToSort.sort(
        (a, b) => durationSum(
                b.genreTracks!.map((e) => e.trackData!.trackDuration!).toList())
            .compareTo(durationSum(a.genreTracks!
                .map((e) => e.trackData!.trackDuration!)
                .toList())),
      );
    }
  }
}

int durationSum(List<int> collection) {
  int sum = 0;
  for (int i in collection) {
    sum += i;
  }
  return sum;
}

class SortArrangement {
  const SortArrangement({
    required this.currentSort,
    required this.currentDirection,
  });
  final String currentSort;
  final String currentDirection;
}

Map<String, AntiiqSortType> sortTypes = {
  "Track Name": AntiiqSortType.trackName,
  "Artist Name": AntiiqSortType.artistName,
  "Album Name": AntiiqSortType.albumName,
  "Genre Name": AntiiqSortType.genreName,
  "Track List": AntiiqSortType.trackList,
  "Duration": AntiiqSortType.duration,
  "Track Number": AntiiqSortType.trackNumber,
};

Map<String, SortDirection> sortDirections = {
  "Ascending": SortDirection.ascending,
  "Descending": SortDirection.descending,
};

final List<String> albumTrackListSortTypes = [
  "Track Number",
  "Track Name",
  "Duration",
];

final List<String> artistTrackListSortTypes = [
  "Track Name",
  "Track Number",
  "Duration",
];

final List<String> genreTrackListSortTypes = [
  "Track Name",
  "Track Number",
  "Duration",
];

beginSort(
  String sortType,
  String sortDirection, {
  bool allTracks = false,
  bool allAlbums = false,
  bool allArtists = false,
  bool allGenres = false,
  bool allAlbumTracks = false,
  bool allArtistTracks = false,
  bool allGenreTracks = false,
}) async {
  if (allTracks) {
    state.music.tracks.sort = SortArrangement(
      currentSort: sortType,
      currentDirection: sortDirection,
    );
    await sortTracks(
      sortDirections[sortDirection]!,
      sortTypes[sortType]!,
      state.music.tracks.list,
    );
    state.music.tracks.updateFlow();
    await antiiqStore.put(SortBoxKeys.trackSort, [sortType, sortDirection]);
  } else if (allAlbums) {
    state.music.albums.sort = SortArrangement(
      currentSort: sortType,
      currentDirection: sortDirection,
    );
    await sortAlbums(
      sortDirections[sortDirection]!,
      sortTypes[sortType]!,
      state.music.albums.list,
    );
    state.music.albums.updateFlow();
    await antiiqStore.put(SortBoxKeys.albumSort, [sortType, sortDirection]);
  } else if (allArtists) {
    state.music.artists.sort = SortArrangement(
      currentSort: sortType,
      currentDirection: sortDirection,
    );
    await sortArtists(
      sortDirections[sortDirection]!,
      sortTypes[sortType]!,
      state.music.artists.list,
    );
    state.music.artists.updateFlow();
    await antiiqStore.put(SortBoxKeys.artistSort, [sortType, sortDirection]);
  } else if (allGenres) {
    state.music.genres.sort = SortArrangement(
      currentSort: sortType,
      currentDirection: sortDirection,
    );
    await sortGenres(
      sortDirections[sortDirection]!,
      sortTypes[sortType]!,
      state.music.genres.list,
    );
    state.music.genres.updateFlow();
    await antiiqStore.put(SortBoxKeys.genreSort, [sortType, sortDirection]);
  } else if (allAlbumTracks) {
    state.music.albums.tracksSort = SortArrangement(
      currentSort: sortType,
      currentDirection: sortDirection,
    );

    for (Album album in state.music.albums.list) {
      await sortTracks(
        sortDirections[sortDirection]!,
        sortTypes[sortType]!,
        album.albumTracks!,
      );
    }
    state.music.albums.updateFlow();
    await antiiqStore
        .put(SortBoxKeys.albumTracksSort, [sortType, sortDirection]);
  } else if (allArtistTracks) {
    state.music.artists.tracksSort = SortArrangement(
      currentSort: sortType,
      currentDirection: sortDirection,
    );

    for (Artist artist in state.music.artists.list) {
      await sortTracks(
        sortDirections[sortDirection]!,
        sortTypes[sortType]!,
        artist.artistTracks!,
      );
    }
    state.music.artists.updateFlow();
    await antiiqStore
        .put(SortBoxKeys.artistTracksSort, [sortType, sortDirection]);
  } else if (allGenreTracks) {
    state.music.genres.tracksSort = SortArrangement(
      currentSort: sortType,
      currentDirection: sortDirection,
    );

    for (Genre genre in state.music.genres.list) {
      await sortTracks(
        sortDirections[sortDirection]!,
        sortTypes[sortType]!,
        genre.genreTracks!,
      );
    }
    state.music.genres.updateFlow();
    await antiiqStore
        .put(SortBoxKeys.genreTracksSort, [sortType, sortDirection]);
  }
}



class SortBoxKeys {
  static const String trackSort = "songSort";
  static const String albumSort = "albumSort";
  static const String artistSort = "artistSort";
  static const String genreSort = "genreSort";
  static const String albumTracksSort = "albumSongsSort";
  static const String artistTracksSort = "artistSongsSort";
  static const String genreTracksSort = "genreSongsSort";
}
