import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/screens/albums/album.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/activity_handlers.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/widgets/image_widgets.dart';
import 'package:antiiq/player/widgets/collection_widgets/collection_heading.dart';
import 'package:antiiq/player/widgets/song_cards/song_card.dart';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:remixicon/remixicon.dart';
import 'package:text_scroll/text_scroll.dart';

class AlbumArtistsList extends StatelessWidget {
  const AlbumArtistsList({super.key});

  @override
  Widget build(BuildContext context) => _CollectionScaffold(
        title: 'Album Artists',
        count: antiiqState.music.albumArtists.list.length,
        child: StreamBuilder<List<AlbumArtist>>(
          stream: antiiqState.music.albumArtists.flow.stream,
          builder: (context, snapshot) {
            final artists =
                snapshot.data ?? antiiqState.music.albumArtists.list;
            return ListView.builder(
              itemExtent: 92,
              itemCount: artists.length,
              itemBuilder: (context, index) {
                final artist = artists[index];
                return _CollectionTile(
                  title: artist.name,
                  subtitle:
                      '${artist.albums.length} ALBUMS · ${artist.tracks.length} TRACKS',
                  art: artist.art,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => _AlbumArtistPage(artist: artist),
                  )),
                );
              },
            );
          },
        ),
      );
}

class FoldersList extends StatelessWidget {
  const FoldersList({super.key});

  @override
  Widget build(BuildContext context) => _CollectionScaffold(
        title: 'Folders',
        count: antiiqState.music.folders.roots.length,
        child: StreamBuilder<List<LibraryFolder>>(
          stream: antiiqState.music.folders.flow.stream,
          builder: (context, snapshot) {
            final folders = snapshot.data ?? antiiqState.music.folders.roots;
            return _FolderList(folders: folders);
          },
        ),
      );
}

class _CollectionScaffold extends StatelessWidget {
  const _CollectionScaffold(
      {required this.title, required this.count, required this.child});
  final String title;
  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            Expanded(
                child: Text(title,
                    style:
                        AntiiQTheme.of(context).textStyles.onBackgroundText)),
            Text('$count',
                style: TextStyle(
                    color: AntiiQTheme.of(context).colorScheme.primary)),
          ]),
        ),
        Expanded(
            child: CustomCard(
                theme: AntiiQTheme.of(context).cardThemes.background,
                child: child)),
      ]);
}

class _CollectionTile extends StatelessWidget {
  const _CollectionTile(
      {required this.title,
      required this.subtitle,
      required this.onTap,
      this.art,
      this.icon,
      this.inRail = false});
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Uri? art;
  final IconData? icon;
  final bool inRail;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(horizontal: inRail ? 0 : 5, vertical: 3),
        child: CustomCard(
          theme: AntiiQTheme.of(context).cardThemes.background,
          child: ListTile(
            onTap: onTap,
            leading: SizedBox.square(
              dimension: 58,
              child: art != null
                  ? getUriImage(art)
                  : Icon(icon ?? RemixIcons.folder_music_fill,
                      color: AntiiQTheme.of(context).colorScheme.primary),
            ),
            title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle:
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: const Icon(RemixIcons.arrow_right_s_line),
          ),
        ),
      );
}

class _AlbumArtistPage extends StatelessWidget {
  const _AlbumArtistPage({required this.artist});
  final AlbumArtist artist;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AntiiQTheme.of(context).colorScheme.background,
        appBar: AppBar(
            title: Text(artist.name),
            backgroundColor: AntiiQTheme.of(context).colorScheme.background),
        body: _TracksAndCollections(
          title: artist.name,
          collectionType: 'Album artist',
          subtitle: '${artist.albums.length} ALBUMS',
          tracks: artist.tracks,
          art: artist.art,
          albums: artist.albums,
        ),
      );
}

class _FolderPage extends StatelessWidget {
  const _FolderPage({required this.folder});
  final LibraryFolder folder;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AntiiQTheme.of(context).colorScheme.background,
        appBar: AppBar(
            title: Text(folder.name),
            backgroundColor: AntiiQTheme.of(context).colorScheme.background),
        body: _TracksAndCollections(
          title: folder.name,
          collectionType: 'Folder',
          detail: folder.absolutePath,
          subtitle: '${folder.children.length} FOLDERS',
          tracks: folder.directTracks,
          playbackTracks: folder.descendantTracks,
          folders: folder.children,
        ),
      );
}

class _FolderList extends StatelessWidget {
  const _FolderList({required this.folders});
  final List<LibraryFolder> folders;
  @override
  Widget build(BuildContext context) => ListView.builder(
        itemExtent: 92,
        itemCount: folders.length,
        itemBuilder: (context, index) {
          final folder = folders[index];
          return _CollectionTile(
            title: folder.name,
            subtitle:
                '${folder.children.length} FOLDERS · ${folder.descendantTracks.length} TRACKS',
            icon: RemixIcons.folder_music_fill,
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => _FolderPage(folder: folder))),
          );
        },
      );
}

class _TracksAndCollections extends StatelessWidget {
  const _TracksAndCollections(
      {required this.title,
      required this.collectionType,
      required this.subtitle,
      required this.tracks,
      this.playbackTracks,
      this.art,
      this.albums = const [],
      this.folders = const [],
      this.detail});
  final String title;
  final String collectionType;
  final String subtitle;
  final String? detail;
  final List<Track> tracks;
  final List<Track>? playbackTracks;
  final Uri? art;
  final List<Album> albums;
  final List<LibraryFolder> folders;

  @override
  Widget build(BuildContext context) {
    final contextTracks = playbackTracks ?? tracks;
    final List<MediaItem> media = contextTracks
        .map((track) => track.mediaItem)
        .whereType<MediaItem>()
        .toList();
    return CustomScrollView(slivers: [
      SliverToBoxAdapter(
          child: Padding(
        padding: const EdgeInsets.all(10),
        child: CustomCard(
          theme: AntiiQTheme.of(context).cardThemes.background,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (art != null) ...[
                Center(child: SizedBox(height: 180, child: getUriImage(art))),
                const SizedBox(height: 12),
              ] else ...[
                Container(
                  height: 88,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AntiiQTheme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(generalRadius - 4),
                  ),
                  child: Icon(RemixIcons.folder_music_fill,
                      size: 42,
                      color: AntiiQTheme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 12),
              ],
              CollectionHeading(
                headings: [
                  '$collectionType: $title',
                  detail,
                ],
                tracks: contextTracks,
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(subtitle,
                    style: TextStyle(
                        color: AntiiQTheme.of(context).colorScheme.secondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1)),
              ],
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: FilledButton.icon(
                      onPressed:
                          media.isEmpty ? null : () => playFromList(0, media),
                      icon: const Icon(RemixIcons.play_fill),
                      label: const Text('Play all')),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                      onPressed: media.isEmpty
                          ? null
                          : () {
                              final shuffled = [...media]..shuffle();
                              playFromList(0, shuffled);
                            },
                      icon: const Icon(RemixIcons.shuffle_fill),
                      label: const Text('Shuffle')),
                ),
              ]),
            ]),
          ),
        ),
      )),
      if (albums.isNotEmpty)
        SliverToBoxAdapter(
          child: _HorizontalCollectionList(
            height: 130,
            itemCount: albums.length,
            itemBuilder: (context, index) {
              final album = albums[index];
              return SizedBox(
                  width: 220,
                  child: _CollectionTile(
                    title: album.albumName ?? 'Unknown Album',
                    subtitle: '${album.numOfSongs ?? 0} TRACKS',
                    art: album.albumArt,
                    inRail: true,
                    onTap: () => showAlbum(context, album),
                  ));
            },
          ),
        ),
      if (folders.isNotEmpty)
        SliverToBoxAdapter(
          child: _HorizontalCollectionList(
            height: 104,
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];
              return SizedBox(
                width: 220,
                child: _CollectionTile(
                  title: folder.name,
                  subtitle: '${folder.descendantTracks.length} TRACKS',
                  inRail: true,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => _FolderPage(folder: folder)),
                  ),
                ),
              );
            },
          ),
        ),
      SliverFixedExtentList.builder(
          itemExtent: 100,
          itemCount: tracks.length,
          itemBuilder: (context, index) {
            final track = tracks[index];
            final playbackIndex = contextTracks.indexOf(track);
            return _CollectionSong(
              key: ValueKey(track.mediaItem?.id ?? track.path ?? index),
              track: track,
              playbackIndex: playbackIndex < 0 ? 0 : playbackIndex,
              playbackItems: media,
            );
          }),
    ]);
  }
}

class _HorizontalCollectionList extends StatefulWidget {
  const _HorizontalCollectionList(
      {required this.height,
      required this.itemCount,
      required this.itemBuilder});
  final double height;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  State<_HorizontalCollectionList> createState() =>
      _HorizontalCollectionListState();
}

class _HorizontalCollectionListState extends State<_HorizontalCollectionList> {
  static const double _scrollbarClearance = 14;
  final ScrollController controller = ScrollController();
  bool _isScrollable = false;

  bool _updateScrollability(ScrollMetrics metrics) {
    final next = metrics.maxScrollExtent > 0;
    if (next != _isScrollable) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && next != _isScrollable) {
          setState(() => _isScrollable = next);
        }
      });
    }
    return false;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        height: widget.height - (_isScrollable ? 0 : _scrollbarClearance),
        child: Scrollbar(
          controller: controller,
          interactive: true,
          thumbVisibility: _isScrollable,
          thickness: 12,
          radius: const Radius.circular(8),
          scrollbarOrientation: ScrollbarOrientation.bottom,
          child: NotificationListener<ScrollMetricsNotification>(
            onNotification: (notification) =>
                _updateScrollability(notification.metrics),
            child: ListView.separated(
              controller: controller,
              scrollDirection: Axis.horizontal,
              itemCount: widget.itemCount,
              padding: EdgeInsets.fromLTRB(
                  10, 0, 10, _isScrollable ? _scrollbarClearance : 0),
              itemBuilder: widget.itemBuilder,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
            ),
          ),
        ),
      );
}

class _CollectionSong extends StatefulWidget {
  const _CollectionSong({
    required this.track,
    required this.playbackIndex,
    required this.playbackItems,
    super.key,
  });

  final Track track;
  final int playbackIndex;
  final List<MediaItem> playbackItems;

  @override
  State<_CollectionSong> createState() => _CollectionSongState();
}

class _CollectionSongState extends State<_CollectionSong> {
  final PageController _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.track.mediaItem;
    return SongCard(
      controller: _controller,
      index: widget.playbackIndex,
      leading: item?.artUri != null
          ? getUriImage(item!.artUri)
          : Icon(RemixIcons.music_2_fill,
              color: AntiiQTheme.of(context).colorScheme.primary),
      title: TextScroll(
        widget.track.trackData?.trackName ?? item?.title ?? 'Unknown track',
        textAlign: TextAlign.left,
        style:
            TextStyle(color: AntiiQTheme.of(context).colorScheme.onBackground),
        velocity: defaultTextScrollvelocity,
        delayBefore: delayBeforeScroll,
      ),
      subtitle: TextScroll(
        widget.track.trackData?.trackArtistNames ??
            item?.artist ??
            'Unknown artist',
        textAlign: TextAlign.left,
        style:
            TextStyle(color: AntiiQTheme.of(context).colorScheme.onBackground),
        velocity: defaultTextScrollvelocity,
        delayBefore: delayBeforeScroll,
      ),
      track: widget.track,
      albumToPlay: widget.playbackItems,
    );
  }
}
