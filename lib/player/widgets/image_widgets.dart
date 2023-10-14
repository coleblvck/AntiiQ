import 'dart:io';
import 'package:flutter/material.dart';

Widget getUriImage(uri) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: AspectRatio(
      aspectRatio: 1,
      child: Image.file(
        File.fromUri(uri),
        fit: BoxFit.cover,
      ),
    ),
  );
}
