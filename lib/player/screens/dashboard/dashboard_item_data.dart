import 'package:flutter/material.dart';

class DashboardItemData {
  final String key;
  final String title;
  final IconData icon;
  final VoidCallback function;
  bool isVisible;

  DashboardItemData({
    required this.key,
    required this.title,
    required this.icon,
    required this.function,
    this.isVisible = true,
  });
}
