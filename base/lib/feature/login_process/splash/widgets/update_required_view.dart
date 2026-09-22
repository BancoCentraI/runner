part of '../splash_view.dart';

/// Zorunlu guncelleme ekrani — kullanici magazaya yonlendirilir, uygulamaya
/// devam edemez.
class _UpdateRequiredView extends StatelessWidget {
  const _UpdateRequiredView({
    required this.currentVersion,
    required this.minimumVersion,
  });

  final String currentVersion;
  final String minimumVersion;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: AppPaddings.allXxl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AppPaddings.l,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: AppRadius.allXl,
              ),
              child: Padding(
                padding: AppPaddings.allXl,
                child: Icon(
                  Icons.upgrade_rounded,
                  size: AppIconSizes.l,
                  color: cs.error,
                ),
              ),
            ),
            Text(
              LocaleKeys.update_required.tr(),
              textAlign: TextAlign.center,
              style: context.textTheme.headlineSmall,
            ),
            Text(
              LocaleKeys.update_message.tr(),
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            Text(
              'v$currentVersion → v$minimumVersion',
              style: context.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            AppPrimaryButton(
              label: LocaleKeys.update_button.tr(),
              onPressed: _openStore,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openStore() async {
    final isApple =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    final url = isApple ? AppString.appStoreUrl : AppString.playStoreUrl;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
