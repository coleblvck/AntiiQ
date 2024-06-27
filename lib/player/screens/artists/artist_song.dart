import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/widgets/song_cards/song_card.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

class ArtistSong extends StatelessWidget {
  final Widget title;
  final Widget subtitle;
  final Widget leading;
  final Track track;
  final Artist artist;
  final int index;
  ArtistSong({
    super.key,
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.track,
    required this.artist,
    required this.index,
  });

  final PageController controller = PageController();
  final String selectionList = "album";
  late final List<MediaItem> albumToPlay =
      artist.artistTracks!.map((e) => e.mediaItem!).toList();

  
  @override
  Widget build(BuildContext context) {
    return SongCard(
      controller: controller,
      index: index,
      selectionList: selectionList,
      leading: leading,
      title: title,
      subtitle: subtitle,
      track: track,
      albumToPlay: albumToPlay,
    );
  }
}
