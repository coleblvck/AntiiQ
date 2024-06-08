import 'dart:io';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:flutter/material.dart';

Widget getUriImage(uri) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(generalRadius),
    child: AspectRatio(
      aspectRatio: 1,
      child: Image.file(
        File.fromUri(uri),
        fit: BoxFit.cover,
      ),
    ),
  );
}
