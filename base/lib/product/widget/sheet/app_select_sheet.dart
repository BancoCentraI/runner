import 'package:akillisletme/product/const/app_icon_sizes.dart';
import 'package:akillisletme/product/const/app_paddings.dart';
import 'package:akillisletme/product/utils/app_messenger.dart';
import 'package:akillisletme/product/utils/extension/context_extension.dart';
import 'package:flutter/material.dart';

/// [AppSelectSheet] icinde gosterilen tek secenek.
@immutable
class AppSelectItem<T> {
  const AppSelectItem({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
    this.enabled = true,
  });

  final T value;

  /// Yerellestirilmis etiket — cagri yeri `LocaleKeys...tr()` gecer.
  final String label;

  final String? subtitle;
  final IconData? icon;
  final bool enabled;
}

/// Listeden tek secim yapilan genel amacli bottom sheet.
///
/// Secilen degeri doner, iptal edilirse `null`:
///
/// ```dart
/// final choice = await AppSelectSheet.show<SortType>(
///   context,
///   title: LocaleKeys.general_select.tr(),
///   items: [
///     AppSelectItem(value: SortType.newest, label: LocaleKeys.sort_newest.tr()),
///     AppSelectItem(value: SortType.oldest, label: LocaleKeys.sort_oldest.tr()),
///   ],
///   selected: currentSort,
/// );
/// if (choice != null) cubit.changeSort(choice);
/// ```
class AppSelectSheet<T> extends StatelessWidget {
  const AppSelectSheet({
    required this.items,
    super.key,
    this.title,
    this.selected,
  });

  final List<AppSelectItem<T>> items;
  final String? title;
  final T? selected;

  /// Sheet'i acar ve secilen degeri doner; kullanici kapatirsa `null`.
  static Future<T?> show<T>(
    BuildContext context, {
    required List<AppSelectItem<T>> items,
    String? title,
    T? selected,
  }) {
    return context.showAppBottomSheet<T>(
      child: AppSelectSheet<T>(items: items, title: title, selected: selected),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: AppPaddings.page,
            child: Text(title!, style: context.textTheme.titleMedium),
          ),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: AppPaddings.s),
            itemCount: items.length,
            itemBuilder: (context, index) => _SelectTile<T>(
              item: items[index],
              isSelected: items[index].value == selected,
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectTile<T> extends StatelessWidget {
  const _SelectTile({required this.item, required this.isSelected});

  final AppSelectItem<T> item;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return ListTile(
      enabled: item.enabled,
      leading: item.icon == null ? null : Icon(item.icon, size: AppIconSizes.m),
      title: Text(item.label),
      subtitle: item.subtitle == null ? null : Text(item.subtitle!),
      trailing: isSelected
          ? Icon(Icons.check_rounded, size: AppIconSizes.m, color: cs.primary)
          : null,
      selected: isSelected,
      onTap: () => Navigator.of(context).pop(item.value),
    );
  }
}
