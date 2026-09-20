import 'dart:io';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:path/path.dart' as p;

class LibraryCollectionIndexBuilder {
  const LibraryCollectionIndexBuilder({this.selectedRoots = const []});
  final List<String> selectedRoots;

  List<AlbumArtist> buildAlbumArtists(List<Track> tracks, List<Album> albums) {
    final grouped = <String, List<Track>>{};
    for (final track in tracks) {
      final name = effectiveAlbumArtist(track);
      (grouped[name.toLowerCase()] ??= []).add(track);
    }
    return grouped.values.map((artistTracks) {
      final displayName = effectiveAlbumArtist(artistTracks.first);
      final ids = artistTracks.map((track) => track.trackData?.albumId).toSet();
      final artistAlbums = albums
          .where((album) => ids.contains(album.albumId))
          .toList()
        ..sort((a, b) => (a.albumName ?? '')
            .toLowerCase()
            .compareTo((b.albumName ?? '').toLowerCase()));
      final sortedTracks = [...artistTracks]..sort((a, b) =>
          (a.trackData?.trackName ?? '')
              .toLowerCase()
              .compareTo((b.trackData?.trackName ?? '').toLowerCase()));
      return AlbumArtist(
        name: displayName,
        albums: List.unmodifiable(artistAlbums),
        tracks: List.unmodifiable(sortedTracks),
        art: artistAlbums.isNotEmpty
            ? artistAlbums.first.albumArt
            : sortedTracks.first.mediaItem?.artUri,
      );
    }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  String effectiveAlbumArtist(Track track) {
    final albumArtist = track.trackData?.albumArtistName?.trim();
    final trackArtist = track.trackData?.trackArtistNames?.trim();
    if (albumArtist?.isNotEmpty == true) return albumArtist!;
    if (trackArtist?.isNotEmpty == true) return trackArtist!;
    return 'Unknown Artist';
  }

  List<LibraryFolder> buildFolders(List<Track> tracks) {
    final roots = <String, _MutableFolder>{};
    for (final track in tracks) {
      final path = track.path;
      if (path == null || path.isEmpty) continue;
      final file = File(path);
      final source = sourceForPath(path);
      final relativeDirectory = p.relative(file.parent.path, from: source);
      var node = roots.putIfAbsent(source,
          () => _MutableFolder(source, _sourceName(source), source, ''));
      if (relativeDirectory != '.') {
        var currentPath = source;
        var relativePath = '';
        for (final segment in p
            .split(relativeDirectory)
            .where((part) => part.isNotEmpty && part != '.')) {
          currentPath = p.join(currentPath, segment);
          relativePath =
              relativePath.isEmpty ? segment : p.join(relativePath, segment);
          node = node.children.putIfAbsent(segment,
              () => _MutableFolder(currentPath, segment, source, relativePath));
        }
      }
      node.directTracks.add(track);
    }
    return roots.values.map((root) => root.freeze()).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  String sourceForPath(String filePath) {
    final selected = selectedRoots
        .map(p.normalize)
        .where((root) =>
            p.isWithin(root, filePath) || p.equals(root, p.dirname(filePath)))
        .toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    if (selected.isNotEmpty) return selected.first;
    final parts = p.split(p.normalize(filePath));
    if (parts.length >= 4 && parts[1] == 'storage') {
      return p.joinAll(parts.take(parts[2] == 'emulated' ? 4 : 3));
    }
    return p.dirname(filePath);
  }

  String _sourceName(String source) {
    final parts = p.split(source);
    if (parts.length >= 4 && parts[1] == 'storage' && parts[2] == 'emulated') {
      return 'Internal storage';
    }
    final name = p.basename(source);
    return name.isEmpty ? source : name;
  }
}

class _MutableFolder {
  _MutableFolder(
      this.absolutePath, this.name, this.sourcePath, this.relativePath);
  final String absolutePath;
  final String name;
  final String sourcePath;
  final String relativePath;
  final Map<String, _MutableFolder> children = {};
  final List<Track> directTracks = [];

  LibraryFolder freeze() {
    final frozenChildren = children.values
        .map((child) => child.freeze())
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    directTracks.sort((a, b) => (a.trackData?.trackName ?? '')
        .toLowerCase()
        .compareTo((b.trackData?.trackName ?? '').toLowerCase()));
    final descendants = <Track>[...directTracks];
    for (final child in frozenChildren) {
      descendants.addAll(child.descendantTracks);
    }
    return LibraryFolder(
      id: '$sourcePath|$relativePath',
      name: name.isEmpty ? absolutePath : name,
      absolutePath: absolutePath,
      sourcePath: sourcePath,
      relativePath: relativePath,
      children: List.unmodifiable(frozenChildren),
      directTracks: List.unmodifiable(directTracks),
      descendantTracks: List.unmodifiable(descendants),
    );
  }
}
