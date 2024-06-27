import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/widgets/song_cards/swiped_card.dart';
import 'package:antiiq/player/widgets/song_cards/unswiped_card.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

class SongCard extends StatelessWidget {
  const SongCard({
    super.key,
    required this.controller,
    required this.index,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.track,
    required this.albumToPlay,
  });

  final PageController controller;
  final int index;
  final Widget leading;
  final Widget title;
  final Widget subtitle;
  final Track track;
  final List<MediaItem> albumToPlay;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: PageView(
        controller: controller,
        children: [
          UnSwipedCard(
            index: index,
            leading: leading,
            title: title,
            subtitle: subtitle,
            track: track,
            albumToPlay: albumToPlay,
          ),
          SwipedCard(
            track: track,
            controller: controller,
            title: title,
          ),
        ],
      ),
    );
  }
}
