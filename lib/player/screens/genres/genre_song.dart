import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/widgets/song_cards/song_card.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

class GenreSong extends StatelessWidget {
  final Widget title;
  final Widget subtitle;
  final Widget leading;
  final Track track;
  final Genre genre;
  final int index;
  GenreSong({
    super.key,
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.track,
    required this.genre,
    required this.index,
  });

  final PageController controller = PageController();
  late final List<MediaItem> albumToPlay =
      genre.genreTracks!.map((e) => e.mediaItem!).toList();


  @override
  Widget build(BuildContext context) {
    return SongCard(
      controller: controller,
      index: index,
      leading: leading,
      title: title,
      subtitle: subtitle,
      track: track,
      albumToPlay: albumToPlay,
    );
  }
}
