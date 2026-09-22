import 'package:flutter/material.dart';

@immutable
class AndroidModuleInfo {
  const AndroidModuleInfo({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.features,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final List<String> features;
}
