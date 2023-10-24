import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/utilities/file_handling/lists.dart';
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

SortArrangement trackSort = const SortArrangement(
  currentSort: "Track Name",
  currentDirection: "Ascending",
);
SortArrangement albumSort = const SortArrangement(
  currentSort: "Album Name",
  currentDirection: "Ascending",
);
SortArrangement artistSort = const SortArrangement(
  currentSort: "Artist Name",
  currentDirection: "Ascending",
);
SortArrangement genreSort = const SortArrangement(
  currentSort: "Genre Name",
  currentDirection: "Ascending",
);
SortArrangement albumTracksSort = const SortArrangement(
  currentSort: "Track Number",
  currentDirection: "Ascending",
);
SortArrangement artistTracksSort = const SortArrangement(
  currentSort: "Track Name",
  currentDirection: "Ascending",
);
SortArrangement genreTracksSort = const SortArrangement(
  currentSort: "Track Name",
  currentDirection: "Ascending",
);

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
    trackSort = SortArrangement(
      currentSort: sortType,
      currentDirection: sortDirection,
    );
    await sortTracks(
      sortDirections[sortDirection]!,
      sortTypes[sortType]!,
      currentTrackListSort,
    );
    allTracksStream.add(currentTrackListSort);
    await antiiqStore.put(SortBoxKeys().trackSort, [sortType, sortDirection]);
  } else if (allAlbums) {
    albumSort = SortArrangement(
      currentSort: sortType,
      currentDirection: sortDirection,
    );
    await sortAlbums(
      sortDirections[sortDirection]!,
      sortTypes[sortType]!,
      currentAlbumListSort,
    );
    allAlbumsStream.add(currentAlbumListSort);
    await antiiqStore.put(SortBoxKeys().albumSort, [sortType, sortDirection]);
  } else if (allArtists) {
    artistSort = SortArrangement(
      currentSort: sortType,
      currentDirection: sortDirection,
    );
    await sortArtists(
      sortDirections[sortDirection]!,
      sortTypes[sortType]!,
      currentArtistListSort,
    );
    allArtistsStream.add(currentArtistListSort);
    await antiiqStore.put(SortBoxKeys().artistSort, [sortType, sortDirection]);
  } else if (allGenres) {
    genreSort = SortArrangement(
      currentSort: sortType,
      currentDirection: sortDirection,
    );
    await sortGenres(
      sortDirections[sortDirection]!,
      sortTypes[sortType]!,
      currentGenreListSort,
    );
    allGenresStream.add(currentGenreListSort);
    await antiiqStore.put(SortBoxKeys().genreSort, [sortType, sortDirection]);
  } else if (allAlbumTracks) {
    albumTracksSort = SortArrangement(
      currentSort: sortType,
      currentDirection: sortDirection,
    );

    for (Album album in currentAlbumListSort) {
      await sortTracks(
        sortDirections[sortDirection]!,
        sortTypes[sortType]!,
        album.albumTracks!,
      );
    }
    allAlbumsStream.add(currentAlbumListSort);
    await antiiqStore
        .put(SortBoxKeys().albumTracksSort, [sortType, sortDirection]);
  } else if (allArtistTracks) {
    artistTracksSort = SortArrangement(
      currentSort: sortType,
      currentDirection: sortDirection,
    );

    for (Artist artist in currentArtistListSort) {
      await sortTracks(
        sortDirections[sortDirection]!,
        sortTypes[sortType]!,
        artist.artistTracks!,
      );
    }
    allArtistsStream.add(currentArtistListSort);
    await antiiqStore
        .put(SortBoxKeys().artistTracksSort, [sortType, sortDirection]);
  } else if (allGenreTracks) {
    genreTracksSort = SortArrangement(
      currentSort: sortType,
      currentDirection: sortDirection,
    );

    for (Genre genre in currentGenreListSort) {
      await sortTracks(
        sortDirections[sortDirection]!,
        sortTypes[sortType]!,
        genre.genreTracks!,
      );
    }
    allGenresStream.add(currentGenreListSort);
    await antiiqStore
        .put(SortBoxKeys().genreTracksSort, [sortType, sortDirection]);
  }
}

initSort() async {
  List<String> savedTrackSort = await antiiqStore.get(
    SortBoxKeys().trackSort,
    defaultValue: <String>[
      trackSort.currentSort,
      trackSort.currentDirection,
    ],
  );
  await beginSort(savedTrackSort[0], savedTrackSort[1], allTracks: true);

  List<String> savedAlbumSort = await antiiqStore.get(
    SortBoxKeys().albumSort,
    defaultValue: <String>[
      albumSort.currentSort,
      albumSort.currentDirection,
    ],
  );
  await beginSort(savedAlbumSort[0], savedAlbumSort[1], allAlbums: true);

  List<String> savedArtistSort = await antiiqStore.get(
    SortBoxKeys().artistSort,
    defaultValue: <String>[
      artistSort.currentSort,
      artistSort.currentDirection,
    ],
  );
  await beginSort(savedArtistSort[0], savedArtistSort[1], allArtists: true);

  List<String> savedGenreSort = await antiiqStore.get(
    SortBoxKeys().genreSort,
    defaultValue: <String>[
      genreSort.currentSort,
      genreSort.currentDirection,
    ],
  );
  await beginSort(savedGenreSort[0], savedGenreSort[1], allGenres: true);

  List<String> savedAlbumTracksSort = await antiiqStore.get(
    SortBoxKeys().albumTracksSort,
    defaultValue: <String>[
      albumTracksSort.currentSort,
      albumTracksSort.currentDirection,
    ],
  );
  await beginSort(savedAlbumTracksSort[0], savedAlbumTracksSort[1],
      allAlbumTracks: true);

  List<String> savedArtistTracksSort = await antiiqStore.get(
    SortBoxKeys().artistTracksSort,
    defaultValue: <String>[
      artistTracksSort.currentSort,
      artistTracksSort.currentDirection,
    ],
  );
  await beginSort(savedArtistTracksSort[0], savedArtistTracksSort[1],
      allArtistTracks: true);

  List<String> savedGenreTracksSort = await antiiqStore.get(
    SortBoxKeys().genreTracksSort,
    defaultValue: <String>[
      genreTracksSort.currentSort,
      genreTracksSort.currentDirection,
    ],
  );
  await beginSort(savedGenreTracksSort[0], savedGenreTracksSort[1],
      allGenreTracks: true);
}

class SortBoxKeys {
  String trackSort = "songSort";
  String albumSort = "albumSort";
  String artistSort = "artistSort";
  String genreSort = "genreSort";
  String albumTracksSort = "albumSongsSort";
  String artistTracksSort = "artistSongsSort";
  String genreTracksSort = "genreSongsSort";
}
