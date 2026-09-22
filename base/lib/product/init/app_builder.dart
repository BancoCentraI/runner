import 'package:akillisletme/feature/home/widget/home_background.dart';
import 'package:flutter/material.dart';

/// MaterialApp builder — global background + overlay katmani.
class AppBuilder {
  const AppBuilder._();

  static Widget call(BuildContext context, Widget? child) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Stack(
        children: [
          const Positioned.fill(
            child: RepaintBoundary(child: HomeBackground()),
          ),
          Positioned.fill(child: child!),
        ],
      ),
    );
  }
}
