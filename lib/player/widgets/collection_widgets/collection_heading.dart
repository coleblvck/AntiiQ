
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/widgets/collection_widgets/collection_length_card.dart';
import 'package:flutter/material.dart';
import 'package:text_scroll/text_scroll.dart';

class CollectionHeading extends StatelessWidget {
  const CollectionHeading({
    required this.headings,
    required this.tracks,
    super.key,
  });

  final List<String?> headings;
  final List<Track> tracks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (String? headingItem in headings)
        if (headingItem != null)
        TextScroll(
          headingItem,
          textAlign: TextAlign.left,
          style: TextStyle(
            fontSize: 20,
            color: AntiiQTheme.of(context).colorScheme.primary,
          ),
          velocity: defaultTextScrollvelocity,
          delayBefore: delayBeforeScroll,
        ),
        const SizedBox(
          height: 5,
        ),
        CollectionLengthCard(tracks: tracks),
      ],
    );
  }
}
