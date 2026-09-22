import 'package:akillisletme/product/const/app_paddings.dart';
import 'package:akillisletme/product/init/language/locale_keys.g.dart';
import 'package:akillisletme/product/theme/app_theme_variant.dart';
import 'package:akillisletme/product/theme/state/theme_cubit.dart';
import 'package:akillisletme/product/theme/state/theme_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Onboarding Step 3 — Theme Selection
class Step3 extends StatelessWidget {
  const Step3({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppPaddings.allXxl,
          child: BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, state) {
              return Column(
                children: [
                  const SizedBox(height: 24),
                  Icon(Icons.palette_rounded, size: 48, color: cs.primary),
                  const SizedBox(height: 16),
                  Text(
                    LocaleKeys.onboarding_step3Title.tr(),
                    style: tt.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8, width: double.infinity),
                  Text(
                    LocaleKeys.onboarding_step3Desc.tr(),
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  // ── Theme Variant Grid ──
                  _buildVariantGrid(context, state),
                  const SizedBox(height: 24),
                  // ── Theme Mode Selector ──
                  _buildThemeModeSelector(context, state),
                  const SizedBox(height: 80),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildVariantGrid(BuildContext context, ThemeState state) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: AppThemeVariant.values.map((variant) {
        final isSelected = variant == state.variant;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            context.read<ThemeCubit>().setVariant(variant);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 72,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? cs.primaryContainer
                  : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? variant.previewColor : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: variant.previewColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                  ],
                ),
                Text(
                  variant.label,
                  style: tt.labelSmall?.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? variant.previewColor : cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildThemeModeSelector(BuildContext context, ThemeState state) {
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(LocaleKeys.settings_themeMode.tr(), style: tt.titleSmall),
        const SizedBox(height: 8),
        SizedBox(
          width: double.maxFinite,
          child: SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(
                  LocaleKeys.settings_themeModeSystem.tr(),
                  style: tt.labelMedium,
                ),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text(
                  LocaleKeys.settings_themeModeLight.tr(),
                  style: tt.labelMedium,
                ),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text(
                  LocaleKeys.settings_themeModeDark.tr(),
                  style: tt.labelMedium,
                ),
              ),
            ],
            selected: {state.themeMode},
            onSelectionChanged: (modes) {
              HapticFeedback.selectionClick();
              context.read<ThemeCubit>().setThemeMode(modes.first);
            },
          ),
        ),
      ],
    );
  }
}
