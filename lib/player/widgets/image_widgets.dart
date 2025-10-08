import 'dart:io';

import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:flutter/material.dart';

Widget getUriImage(uri) {
  return StreamBuilder<ArtFit>(
      stream: coverArtFitStream.stream,
      builder: (context, snapshot) {
        final coverArtFit = snapshot.data ?? currentCoverArtFit;
        return ClipRRect(
          borderRadius: BorderRadius.circular(generalRadius - 6),
          child: AspectRatio(
            aspectRatio: 1,
            child: Image.file(
              File.fromUri(uri),
              fit:
                  coverArtFit == ArtFit.contain ? BoxFit.contain : BoxFit.cover,
            ),
          ),
        );
      });
}

Widget getChaosUriImage(uri) {
  return StreamBuilder<ArtFit>(
      stream: coverArtFitStream.stream,
      builder: (context, snapshot) {
        final coverArtFit = snapshot.data ?? currentCoverArtFit;
        return AspectRatio(
          aspectRatio: 1,
          child: Image.file(
            File.fromUri(uri),
            fit: coverArtFit == ArtFit.contain ? BoxFit.contain : BoxFit.cover,
          ),
        );
      });
}
