import 'package:antiiq/chaos/chaos_global_constants.dart';
import 'package:antiiq/chaos/chaos_ui_state.dart';
import 'package:antiiq/chaos/page_manager.dart';
import 'package:antiiq/chaos/utilities/open_collection.dart';
import 'package:antiiq/chaos/widgets/chaos/collection_headers.dart';
import 'package:antiiq/chaos/widgets/track_details_sheet.dart';
import 'package:antiiq/chaos/widgets/surfaces/antiiq_surface.dart';
import 'package:antiiq/chaos/widgets/chaos/tracklist.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/widgets/image_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:remixicon/remixicon.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:antiiq/player/global_variables.dart';

class ChaosAlbumArtistsList extends StatelessWidget {
  const ChaosAlbumArtistsList({required this.scrollController, super.key});
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) => StreamBuilder<List<AlbumArtist>>(
        stream: antiiqState.music.albumArtists.flow.stream,
        builder: (context, snapshot) {
          final artists = snapshot.data ?? antiiqState.music.albumArtists.list;
          return _CollectionList(
            controller: scrollController,
            count: artists.length,
            itemBuilder: (context, index) {
              final artist = artists[index];
              return _CollectionTile(
                title: artist.name,
                subtitle:
                    '${artist.albums.length} ALBUMS · ${artist.tracks.length} TRACKS',
                art: artist.art,
                onTap: () => openAlbumArtist(
                    artist, ChaosPageManagerNavigator.of(context)),
              );
            },
          );
        },
      );
}

class ChaosFoldersList extends StatelessWidget {
  const ChaosFoldersList({required this.scrollController, super.key});
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) => StreamBuilder<List<LibraryFolder>>(
        stream: antiiqState.music.folders.flow.stream,
        builder: (context, snapshot) {
          final folders = snapshot.data ?? antiiqState.music.folders.roots;
          return _CollectionList(
            controller: scrollController,
            count: folders.length,
            itemBuilder: (context, index) =>
                _FolderTile(folder: folders[index]),
          );
        },
      );
}

class _CollectionList extends StatelessWidget {
  const _CollectionList(
      {required this.controller,
      required this.count,
      required this.itemBuilder});
  final ScrollController controller;
  final int count;
  final IndexedWidgetBuilder itemBuilder;
  @override
  Widget build(BuildContext context) => Scrollbar(
        controller: controller,
        scrollbarOrientation: ScrollbarOrientation.left,
        child: ListView.builder(
          controller: controller,
          padding: const EdgeInsets.all(chaosBasePadding),
          itemCount: count,
          itemBuilder: itemBuilder,
        ),
      );
}

class _CollectionTile extends StatelessWidget {
  const _CollectionTile(
      {required this.title,
      required this.subtitle,
      required this.onTap,
      this.art,
      this.icon});
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Uri? art;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => AntiiQSurface(
        role: AntiiQSurfaceRole.control,
        margin: const EdgeInsets.only(bottom: chaosBasePadding),
        radius: 16,
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.all(10),
          leading: SizedBox.square(
              dimension: 56,
              child: art != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: getUriImage(art))
                  : Icon(icon ?? RemixIcons.folder_music_fill,
                      color: AntiiQTheme.of(context).colorScheme.primary)),
          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle:
              Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: const Icon(RemixIcons.arrow_right_s_line),
        ),
      );
}

class _FolderTile extends StatelessWidget {
  const _FolderTile({required this.folder});
  final LibraryFolder folder;
  @override
  Widget build(BuildContext context) => _CollectionTile(
        title: folder.name,
        subtitle:
            '${folder.children.length} FOLDERS · ${folder.descendantTracks.length} TRACKS',
        icon: RemixIcons.folder_music_fill,
        onTap: () => openFolder(folder, ChaosPageManagerNavigator.of(context)),
      );
}

void openAlbumArtist(
    AlbumArtist artist, ChaosPageManagerController? controller) {
  final scroll = ScrollController();
  controller?.push(
    TrackList(
      scrollController: scroll,
      tracks: artist.tracks,
      header: _AlbumArtistHeader(artist: artist),
    ),
    id: 'albumArtist:${artist.name.toLowerCase()}',
    title: artist.name.toUpperCase(),
    scrollController: scroll,
    listToCount: artist.tracks,
    listToShuffle: artist.tracks,
    onPop: scroll.dispose,
  );
}

void openFolder(LibraryFolder folder, ChaosPageManagerController? controller) {
  final scroll = ScrollController();
  controller?.push(
    TrackList(
      scrollController: scroll,
      tracks: folder.directTracks,
      playbackContext: folder.descendantTracks,
      header: _FolderHeader(folder: folder),
    ),
    id: 'folder:${folder.id}',
    title: folder.name.toUpperCase(),
    scrollController: scroll,
    listToCount: folder.directTracks,
    listToShuffle: folder.descendantTracks,
    onPop: scroll.dispose,
  );
}

class _AlbumArtistHeader extends StatelessWidget {
  const _AlbumArtistHeader({required this.artist});
  final AlbumArtist artist;
  @override
  Widget build(BuildContext context) => Column(children: [
        if (artist.art != null)
          ArtistHeader(
            artist: Artist(
              artistName: artist.name,
              artistArt: artist.art,
              artistTracks: artist.tracks,
            ),
          )
        else
          _HeaderCard(
            label: 'ALBUM ARTIST',
            title: artist.name,
            subtitle:
                '${artist.albums.length} ALBUMS · ${artist.tracks.length} TRACKS',
            tracks: artist.tracks,
          ),
        if (artist.albums.isNotEmpty)
          _HorizontalCollectionList(
            height: 124,
            horizontalContentPadding: chaosBasePadding,
            itemCount: artist.albums.length,
            itemBuilder: (context, index) {
              final album = artist.albums[index];
              return SizedBox(
                  width: 190,
                  child: _CollectionTile(
                    title: album.albumName ?? 'Unknown Album',
                    subtitle: '${album.numOfSongs ?? 0} TRACKS',
                    art: album.albumArt,
                    onTap: () =>
                        openAlbum(album, ChaosPageManagerNavigator.of(context)),
                  ));
            },
          ),
      ]);
}

class _FolderHeader extends StatelessWidget {
  const _FolderHeader({required this.folder});
  final LibraryFolder folder;
  @override
  Widget build(BuildContext context) => _HeaderCard(
        label: 'FOLDER',
        title: folder.name,
        tracks: folder.descendantTracks,
        subtitle:
            '${folder.children.length} FOLDERS · ${folder.descendantTracks.length} TRACKS\n${folder.absolutePath}',
        child: folder.children.isEmpty
            ? null
            : _HorizontalCollectionList(
                height: 104,
                horizontalContentPadding: chaosBasePadding * 2,
                itemCount: folder.children.length,
                itemBuilder: (context, index) => SizedBox(
                    width: 220,
                    child: _FolderTile(folder: folder.children[index])),
              ),
      );
}

class _HorizontalCollectionList extends StatefulWidget {
  const _HorizontalCollectionList(
      {required this.height,
      required this.itemCount,
      required this.itemBuilder,
      this.horizontalContentPadding = 0});
  final double height;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double horizontalContentPadding;
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
          thickness: 12,
          thumbVisibility: _isScrollable,
          scrollbarOrientation: ScrollbarOrientation.bottom,
          child: NotificationListener<ScrollMetricsNotification>(
            onNotification: (notification) =>
                _updateScrollability(notification.metrics),
            child: ListView.separated(
              controller: controller,
              scrollDirection: Axis.horizontal,
              itemCount: widget.itemCount,
              padding: EdgeInsets.fromLTRB(
                widget.horizontalContentPadding,
                0,
                widget.horizontalContentPadding,
                _isScrollable ? _scrollbarClearance : 0,
              ),
              itemBuilder: widget.itemBuilder,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: chaosBasePadding),
            ),
          ),
        ),
      );
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard(
      {required this.label,
      required this.title,
      required this.subtitle,
      required this.tracks,
      this.child});
  final String label;
  final String title;
  final String subtitle;
  final List<Track> tracks;
  final Widget? child;
  @override
  Widget build(BuildContext context) {
    final outerRadius = context.watch<ChaosUIState>().chaosRadius;
    final innerRadius = outerRadius - 2;
    final colors = AntiiQTheme.of(context).colorScheme;
    return AntiiQSurface(
      role: AntiiQSurfaceRole.elevated,
      margin: const EdgeInsets.all(chaosBasePadding),
      radius: outerRadius,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.all(chaosBasePadding * 2),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: chaosBasePadding,
                    vertical: chaosBasePadding / 2),
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(innerRadius),
                ),
                child: Text(label,
                    style: TextStyle(
                        color: colors.onPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1)),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (tracks.isNotEmpty) {
                    showTrackDetailsSheet(context, tracks,
                        pageManagerController:
                            ChaosPageManagerNavigator.of(context));
                  }
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: colors.primary.withValues(alpha: .3)),
                    borderRadius: BorderRadius.circular(innerRadius),
                  ),
                  child: Icon(RemixIcons.menu_4_fill,
                      color: colors.primary, size: 20),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            TextScroll(title,
                style: TextStyle(
                    color: colors.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2),
                velocity: defaultTextScrollvelocity,
                delayBefore: delayBeforeScroll),
            const SizedBox(height: 8),
            Text(subtitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: colors.onBackground.withValues(alpha: .72))),
          ]),
        ),
        if (child != null) child!,
      ]),
    );
  }
}
