import 'dart:io';

import 'package:akillisletme/product/const/app_paddings.dart';
import 'package:akillisletme/product/const/method_channels.dart';
import 'package:akillisletme/product/init/language/locale_keys.g.dart';
import 'package:akillisletme/product/model/android_module_info.dart';
import 'package:akillisletme/product/widget/app_primary_button.dart';
import 'package:akillisletme/product/widget/app_secondary_button.dart';
import 'package:akillisletme/product/widget/app_text_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AndroidModulesView extends StatefulWidget {
  const AndroidModulesView({super.key});

  @override
  State<AndroidModulesView> createState() => _AndroidModulesViewState();
}

class _AndroidModulesViewState extends State<AndroidModulesView>
    with WidgetsBindingObserver {
  static const _overlayChannel = MethodChannel(
    MethodChannels.overlayPermission,
  );
  static const _counterChannel = MethodChannel(MethodChannels.counter);

  bool _overlayGranted = false;
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      WidgetsBinding.instance.addObserver(this);
      _checkPermission();
      _loadCounter();
    }
  }

  @override
  void dispose() {
    if (Platform.isAndroid) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
      _loadCounter();
    }
  }

  Future<void> _checkPermission() async {
    final granted =
        await _overlayChannel.invokeMethod<bool>('isGranted') ?? false;
    if (mounted) setState(() => _overlayGranted = granted);
  }

  Future<void> _requestPermission() async {
    await _overlayChannel.invokeMethod<void>('request');
  }

  Future<void> _loadCounter() async {
    final value = await _counterChannel.invokeMethod<int>('get') ?? 0;
    if (mounted) setState(() => _counter = value);
  }

  Future<void> _increment() async {
    final value = await _counterChannel.invokeMethod<int>('increment') ?? 0;
    if (mounted) setState(() => _counter = value);
  }

  Future<void> _decrement() async {
    final value = await _counterChannel.invokeMethod<int>('decrement') ?? 0;
    if (mounted) setState(() => _counter = value);
  }

  Future<void> _reset() async {
    final value = await _counterChannel.invokeMethod<int>('reset') ?? 0;
    if (mounted) setState(() => _counter = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.androidModules_title.tr())),
      body: Platform.isAndroid
          ? _AndroidBody(
              overlayGranted: _overlayGranted,
              counter: _counter,
              onRequestPermission: _requestPermission,
              onIncrement: _increment,
              onDecrement: _decrement,
              onReset: _reset,
            )
          : const _NotSupportedBody(),
    );
  }
}

// ── Android body ──────────────────────────────────────────────────────────────

class _AndroidBody extends StatelessWidget {
  const _AndroidBody({
    required this.overlayGranted,
    required this.counter,
    required this.onRequestPermission,
    required this.onIncrement,
    required this.onDecrement,
    required this.onReset,
  });

  final bool overlayGranted;
  final int counter;
  final VoidCallback onRequestPermission;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final modules = [
      AndroidModuleInfo(
        icon: Icons.widgets_outlined,
        iconColor: cs.primary,
        title: LocaleKeys.androidModules_homeWidgetTitle.tr(),
        description: LocaleKeys.androidModules_homeWidgetDesc.tr(),
        features: [
          LocaleKeys.androidModules_homeWidgetFeature1.tr(),
          LocaleKeys.androidModules_homeWidgetFeature2.tr(),
          LocaleKeys.androidModules_homeWidgetFeature3.tr(),
        ],
      ),
      AndroidModuleInfo(
        icon: Icons.picture_in_picture_alt_rounded,
        iconColor: cs.secondary,
        title: LocaleKeys.androidModules_overlayTitle.tr(),
        description: LocaleKeys.androidModules_overlayDesc.tr(),
        features: [
          LocaleKeys.androidModules_overlayFeature1.tr(),
          LocaleKeys.androidModules_overlayFeature2.tr(),
          LocaleKeys.androidModules_overlayFeature3.tr(),
          LocaleKeys.androidModules_overlayFeature4.tr(),
        ],
      ),
    ];

    return ListView(
      padding: AppPaddings.page,
      children: [
        const SizedBox(height: AppPaddings.s),

        // ── Modül kartları ──
        ...modules.map(
          (m) => Padding(
            padding: const EdgeInsets.only(bottom: AppPaddings.l),
            child: _ModuleCard(module: m),
          ),
        ),

        const SizedBox(height: AppPaddings.s),

        // ── Sayaç Simülasyonu ──
        Text(
          LocaleKeys.androidModules_counterSection.tr(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppPaddings.s),
        Card(
          child: Padding(
            padding: AppPaddings.allL,
            child: Column(
              children: [
                Text(
                  '$counter',
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: AppPaddings.l),
                Row(
                  children: [
                    Expanded(
                      child: AppSecondaryButton(
                        label: '−',
                        onPressed: onDecrement,
                        isExpanded: false,
                      ),
                    ),
                    Expanded(
                      child: AppTextButton(
                        label: LocaleKeys.androidModules_counterReset.tr(),
                        onPressed: onReset,
                      ),
                    ),
                    Expanded(
                      child: AppPrimaryButton(
                        label: '+',
                        onPressed: onIncrement,
                        isExpanded: false,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppPaddings.xl),

        // ── İzin Durumu ──
        Text(
          LocaleKeys.androidModules_permissionSection.tr(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppPaddings.s),
        Card(
          child: Padding(
            padding: AppPaddings.allL,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      overlayGranted
                          ? Icons.check_circle_rounded
                          : Icons.warning_amber_rounded,
                      color: overlayGranted ? Colors.green : cs.error,
                    ),
                    const SizedBox(width: AppPaddings.s),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            LocaleKeys.androidModules_permissionName.tr(),
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            LocaleKeys.androidModules_permissionDesc.tr(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppPaddings.m),
                if (overlayGranted)
                  Text(
                    LocaleKeys.androidModules_permissionGranted.tr(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.green,
                    ),
                  )
                else
                  AppPrimaryButton(
                    label: LocaleKeys.androidModules_permissionButton.tr(),
                    icon: Icons.security_rounded,
                    onPressed: onRequestPermission,
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppPaddings.l),

        // ── Alt not ──
        Container(
          padding: AppPaddings.allM,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: AppPaddings.s),
              Expanded(
                child: Text(
                  LocaleKeys.androidModules_infoNote.tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppPaddings.xxl),
      ],
    );
  }
}

// ── Modül kart bileşeni ───────────────────────────────────────────────────────

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module});

  final AndroidModuleInfo module;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: AppPaddings.allL,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: module.iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(module.icon, color: module.iconColor, size: 24),
                ),
                const SizedBox(width: AppPaddings.m),
                Expanded(
                  child: Text(
                    module.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppPaddings.m),
            Text(
              module.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppPaddings.m),
            ...module.features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: AppPaddings.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: AppPaddings.s),
                    Expanded(child: Text(f, style: theme.textTheme.bodySmall)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Platform dışı ─────────────────────────────────────────────────────────────

class _NotSupportedBody extends StatelessWidget {
  const _NotSupportedBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.android, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: AppPaddings.l),
          Text(
            LocaleKeys.androidModules_notSupportedTitle.tr(),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppPaddings.s),
          Text(
            LocaleKeys.androidModules_notSupportedDesc.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
