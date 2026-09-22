import 'dart:io';

import 'package:akillisletme/feature/settings/theme_selection/widget/custom_color_sheet.dart';
import 'package:akillisletme/feature/settings/theme_selection/widget/theme_preview_card.dart';
import 'package:akillisletme/feature/settings/theme_selection/widget/theme_swatch.dart';
import 'package:akillisletme/product/const/app_paddings.dart';
import 'package:akillisletme/product/init/language/locale_keys.g.dart';
import 'package:akillisletme/product/theme/app_theme_option.dart';
import 'package:akillisletme/product/theme/state/theme_cubit.dart';
import 'package:akillisletme/product/theme/state/theme_state.dart';
import 'package:akillisletme/product/theme/theme_preset.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Tema & kisisellestirme tam sayfasi (`/settings/theme`).
///
/// Renk paleti, nötr/AMOLED temalar, custom seed, Material You (sistem
/// renkleri), kontrast, mod ve presetleri canli onizlemeyle tek yerden sunar.
class ThemeSelectionView extends StatelessWidget {
  const ThemeSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    context.locale; // Dil degisiminde rebuild

    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.theme_title.tr())),
      body: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) {
          return ListView(
            padding: AppPaddings.page,
            children: [
              const ThemePreviewCard(),
              const SizedBox(height: 24),
              _ColorsSection(state: state),
              const SizedBox(height: 24),
              _NeutralSection(state: state),
              const SizedBox(height: 24),
              if (Platform.isAndroid) ...[
                _SystemColorsTile(state: state),
                const SizedBox(height: 24),
              ],
              _ContrastSection(state: state),
              const SizedBox(height: 24),
              _ModeSection(state: state),
              const SizedBox(height: 24),
              _PresetsSection(state: state),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ColorsSection extends StatelessWidget {
  const _ColorsSection({required this.state});
  final ThemeState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ThemeCubit>();
    final isCustomSelected =
        state.themeId == AppThemeIds.custom && !state.useSystemColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(LocaleKeys.theme_sectionColors.tr()),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final option in AppThemeCatalog.colors)
              ThemeSwatch(
                color: option.previewColor,
                label: option.labelKey.tr(),
                isSelected:
                    state.themeId == option.id && !state.useSystemColors,
                onTap: () => cubit.selectTheme(option.id),
              ),
            // Custom seed
            ThemeSwatch(
              color: isCustomSelected
                  ? state.previewColor
                  : Theme.of(context).colorScheme.primary,
              label: LocaleKeys.theme_name_custom.tr(),
              isSelected: isCustomSelected,
              icon: Icons.colorize_rounded,
              onTap: () => CustomColorSheet.show(context, state.previewColor),
            ),
          ],
        ),
      ],
    );
  }
}

class _NeutralSection extends StatelessWidget {
  const _NeutralSection({required this.state});
  final ThemeState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ThemeCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(LocaleKeys.theme_sectionNeutral.tr()),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final option in AppThemeCatalog.neutrals)
              ThemeSwatch(
                color: option.previewColor,
                label: option.labelKey.tr(),
                isSelected:
                    state.themeId == option.id && !state.useSystemColors,
                onTap: () => cubit.selectTheme(option.id),
              ),
          ],
        ),
      ],
    );
  }
}

class _SystemColorsTile extends StatelessWidget {
  const _SystemColorsTile({required this.state});
  final ThemeState state;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: Icon(Icons.wallpaper_rounded, color: cs.onSurfaceVariant),
      title: Text(LocaleKeys.theme_systemColors.tr()),
      subtitle: Text(LocaleKeys.theme_systemColorsDesc.tr()),
      value: state.useSystemColors,
      onChanged: (v) =>
          context.read<ThemeCubit>().setUseSystemColors(enabled: v),
    );
  }
}

class _ContrastSection extends StatelessWidget {
  const _ContrastSection({required this.state});
  final ThemeState state;

  @override
  Widget build(BuildContext context) {
    final isHigh = state.contrastLevel >= 0.5;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(LocaleKeys.theme_contrast.tr()),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: false,
                label: Text(LocaleKeys.theme_contrastStandard.tr()),
              ),
              ButtonSegment(
                value: true,
                label: Text(LocaleKeys.theme_contrastHigh.tr()),
              ),
            ],
            selected: {isHigh},
            onSelectionChanged: (s) => context
                .read<ThemeCubit>()
                .setContrastLevel(s.first ? 1.0 : 0.0),
          ),
        ),
      ],
    );
  }
}

class _ModeSection extends StatelessWidget {
  const _ModeSection({required this.state});
  final ThemeState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(LocaleKeys.theme_mode.tr()),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(LocaleKeys.settings_themeModeSystem.tr()),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text(LocaleKeys.settings_themeModeLight.tr()),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text(LocaleKeys.settings_themeModeDark.tr()),
              ),
            ],
            selected: {state.themeMode},
            onSelectionChanged: (s) =>
                context.read<ThemeCubit>().setThemeMode(s.first),
          ),
        ),
      ],
    );
  }
}

class _PresetsSection extends StatelessWidget {
  const _PresetsSection({required this.state});
  final ThemeState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ThemeCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(LocaleKeys.theme_presets.tr()),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final preset in ThemePreset.all)
              ThemeSwatch(
                color: preset.previewColor,
                label: preset.labelKey.tr(),
                isSelected:
                    !state.useSystemColors &&
                    state.themeId == preset.themeId &&
                    state.themeMode == preset.themeMode,
                icon: Icons.auto_awesome_rounded,
                onTap: () => cubit.applyPreset(preset),
              ),
          ],
        ),
      ],
    );
  }
}
