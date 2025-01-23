
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/duration_getters.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:flutter/material.dart';

class CollectionLengthCard extends StatelessWidget {
  const CollectionLengthCard({
    required this.tracks,
    super.key,
  });

  final List<Track> tracks;

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      theme: AntiiQTheme.of(context).cardThemes.primary.copyWith(
        margin: const EdgeInsets.all(0)
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Text(
          "Length: ${totalDuration(tracks)}",
          style: TextStyle(
            color: AntiiQTheme.of(context)
                .colorScheme
                .onPrimary,
          ),
        ),
      ),
    );
  }
}
