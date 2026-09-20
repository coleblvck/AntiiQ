import 'package:antiiq/player/utilities/file_handling/library_collections_index.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:flutter_test/flutter_test.dart';

Track track(String path, String title,
        {String? artist, String? albumArtist, int? albumId}) =>
    Track(
      path: path,
      trackData: TrackData(
        trackName: title,
        trackArtistNames: artist,
        albumArtistName: albumArtist,
        albumId: albumId,
      ),
    );

void main() {
  group('album artists', () {
    test('uses album artist then track artist then unknown', () {
      const builder = LibraryCollectionIndexBuilder();
      final result = builder.buildAlbumArtists([
        track('/music/a.mp3', 'A', artist: 'Guest', albumArtist: 'The Group'),
        track('/music/b.mp3', 'B', artist: 'Solo'),
        track('/music/c.mp3', 'C'),
      ], []);
      expect(result.map((artist) => artist.name),
          ['Solo', 'The Group', 'Unknown Artist']);
    });

    test('joins albums to their effective album artist', () {
      const builder = LibraryCollectionIndexBuilder();
      final tracks = [
        track('/music/a.mp3', 'A',
            artist: 'Guest', albumArtist: 'Group', albumId: 7)
      ];
      final album = Album(albumId: 7, albumName: 'Record', albumTracks: tracks);
      final result = builder.buildAlbumArtists(tracks, [album]);
      expect(result.single.albums.single, same(album));
      expect(result.single.tracks, tracks);
    });
  });

  group('folders', () {
    test('builds descendants once while keeping direct tracks distinct', () {
      const builder = LibraryCollectionIndexBuilder(selectedRoots: ['/music']);
      final rootTrack = track('/music/root.mp3', 'Root');
      final childTrack = track('/music/Artist/Album/child.flac', 'Child');
      final root = builder.buildFolders([rootTrack, childTrack]).single;
      expect(root.directTracks, [rootTrack]);
      expect(root.descendantTracks, [rootTrack, childTrack]);
      expect(root.children.single.name, 'Artist');
      expect(root.children.single.children.single.name, 'Album');
      expect(root.children.single.children.single.directTracks, [childTrack]);
    });

    test('same folder names under different parents retain unique identities',
        () {
      const builder = LibraryCollectionIndexBuilder(selectedRoots: ['/music']);
      final root = builder.buildFolders([
        track('/music/A/Live/one.mp3', 'One'),
        track('/music/B/Live/two.mp3', 'Two'),
      ]).single;
      final liveFolders =
          root.children.map((parent) => parent.children.single).toList();
      expect(liveFolders.map((folder) => folder.name), ['Live', 'Live']);
      expect(liveFolders.map((folder) => folder.id).toSet(), hasLength(2));
    });

    test('selected roots remain separate sources', () {
      const builder = LibraryCollectionIndexBuilder(
          selectedRoots: ['/internal/music', '/sd/music']);
      final roots = builder.buildFolders([
        track('/internal/music/a.mp3', 'A'),
        track('/sd/music/b.mp3', 'B'),
      ]);
      expect(roots.map((folder) => folder.sourcePath).toSet(),
          {'/internal/music', '/sd/music'});
    });
  });
}
