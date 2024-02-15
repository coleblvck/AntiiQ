import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import 'package:antiiq/player/widgets/song_cards/song_card.dart';

class FavouritesSong extends StatelessWidget {
  final Widget title;
  final Widget subtitle;
  final Widget leading;
  final Track track;
  final List<Track> album;
  final int index;
  FavouritesSong({
    super.key,
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.track,
    required this.album,
    required this.index,
  });

  final PageController controller = PageController();
  final String selectionList = "album";
  late final List<MediaItem> albumToPlay =
      album.map((e) => e.mediaItem!).toList();

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
