import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/widgets/song_cards/song_card.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

class SongItem extends StatelessWidget {
  final Widget title;
  final Widget subtitle;
  final Widget leading;
  final Track track;
  final int index;
  final List<MediaItem> allSongItems;
  SongItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.track,
    required this.index,
    required this.allSongItems,
  });

  final PageController controller = PageController();

  @override
  Widget build(BuildContext context) {
    return SongCard(
      controller: controller,
      index: index,
      leading: leading,
      title: title,
      subtitle: subtitle,
      track: track,
      albumToPlay: allSongItems,
    );
  }
}
