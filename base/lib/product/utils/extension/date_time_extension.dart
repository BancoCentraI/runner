import 'package:akillisletme/product/init/language/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';

/// Tarih bicimlendirme ve goreceli sure gosterimi.
///
/// Cikti metinleri `LocaleKeys` uzerinden gelir; ay/gun adlari `intl`
/// tarafindan aktif locale'e gore bicimlendirilir.
extension DateTimeExtension on DateTime {
  /// Gun basi (00:00) — iki tarihi gun bazinda karsilastirmak icin.
  DateTime get startOfDay => DateTime(year, month, day);

  /// Suresi henuz dolmamis mi.
  bool get isNotExpired => DateTime.now().isBefore(this);

  bool get isToday => startOfDay == DateTime.now().startOfDay;

  bool get isYesterday =>
      startOfDay == DateTime.now().startOfDay.subtract(const Duration(days: 1));

  /// 24 saat formati. → `'14:30'`
  String get hm => DateFormat.Hm().format(this);

  /// Kisa tarih — aktif dile gore ay adi kisaltilir. → `'12 Oca 2026'`
  String get shortDate => DateFormat('d MMM y').format(this);

  /// Tarih + saat. → `'12 Oca 2026, 14:30'`
  String get dateTimeLabel => DateFormat('d MMM y, HH:mm').format(this);

  /// Goreceli sure. → `'Az once'`, `'2 saat once'`
  String get timeAgo {
    final difference = DateTime.now().difference(this);

    if (difference.inDays >= 365) {
      return LocaleKeys.date_yearsAgo.tr(args: ['${difference.inDays ~/ 365}']);
    }
    if (difference.inDays >= 30) {
      return LocaleKeys.date_monthsAgo.tr(args: ['${difference.inDays ~/ 30}']);
    }
    if (difference.inDays >= 1) {
      return LocaleKeys.date_daysAgo.tr(args: ['${difference.inDays}']);
    }
    if (difference.inHours >= 1) {
      return LocaleKeys.date_hoursAgo.tr(args: ['${difference.inHours}']);
    }
    if (difference.inMinutes >= 1) {
      return LocaleKeys.date_minutesAgo.tr(args: ['${difference.inMinutes}']);
    }
    return LocaleKeys.date_justNow.tr();
  }

  /// Liste basligi icin gun etiketi.
  /// → `'Bugun'`, `'Dun'`, `'12 Ocak'`, `'12 Oca 2025'`
  String get relativeDayLabel {
    final now = DateTime.now();
    final dayDifference = now.startOfDay.difference(startOfDay).inDays;

    return switch (dayDifference) {
      0 => LocaleKeys.date_today.tr(),
      1 => LocaleKeys.date_yesterday.tr(),
      -1 => LocaleKeys.date_tomorrow.tr(),
      _ when year == now.year => DateFormat.MMMMd().format(this),
      _ => DateFormat.yMMMd().format(this),
    };
  }
}

extension NullableDateTimeExtension on DateTime? {
  /// Sunucu zaman damgasi henuz yazilmadiysa (`null`) "simdi" varsayar.
  String get timeAgoOrNow => (this ?? DateTime.now()).timeAgo;
}
