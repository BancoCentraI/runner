import 'package:akillisletme/product/const/app_paddings.dart';
import 'package:akillisletme/product/const/app_radius.dart';
import 'package:akillisletme/product/utils/extension/context_extension.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Yukleme sirasinda icerigin seklini taklit eden iskelet placeholder.
///
/// Ortalanmis spinner yerine bunu kullanmak algilanan hizi belirgin sekilde
/// artirir — kullanici ne gelecegini onceden gorur.
///
/// ```dart
/// AppStateView(
///   state: ...,
///   loadingPlaceholder: const AppShimmerList(),
///   builder: () => ...,
/// )
/// ```
class AppShimmer extends StatelessWidget {
  const AppShimmer({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return Shimmer.fromColors(
      baseColor: cs.surfaceContainerHighest,
      highlightColor: cs.surface,
      child: child,
    );
  }
}

/// Tek bir dolgu bloku — kart, satir ya da gorsel yerine gecer.
class AppShimmerBox extends StatelessWidget {
  const AppShimmerBox({
    required this.height,
    super.key,
    this.width = double.infinity,
    this.borderRadius = AppRadius.allM,
  });

  final double height;
  final double width;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHighest,
        borderRadius: borderRadius,
      ),
      child: SizedBox(height: height, width: width),
    );
  }
}

/// Liste ekranlari icin hazir iskelet — [itemCount] kadar kart cizer.
class AppShimmerList extends StatelessWidget {
  const AppShimmerList({super.key, this.itemCount = 6, this.itemHeight = 76});

  final int itemCount;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.separated(
        padding: AppPaddings.page,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: AppPaddings.m),
        itemBuilder: (_, _) => AppShimmerBox(height: itemHeight),
      ),
    );
  }
}
