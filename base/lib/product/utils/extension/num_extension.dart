import 'package:easy_localization/easy_localization.dart';

extension IntExtension on int {
  /// Tek haneli sayinin basina 0 ekler — saat/dakika gosteriminde.
  /// → `5.padded` = `'05'`
  String get padded => this < 10 ? '0$this' : '$this';

  /// Binlik ayracli gosterim, aktif locale'e gore. → `'1.250'` / `'1,250'`
  String get grouped => NumberFormat.decimalPattern().format(this);

  /// Buyuk sayilari kisaltir. → `'1,2B'` yerine `'1.2K'`
  String get compact => NumberFormat.compact().format(this);

  Duration get milliseconds => Duration(milliseconds: this);
  Duration get seconds => Duration(seconds: this);
  Duration get minutes => Duration(minutes: this);
  Duration get days => Duration(days: this);
}

extension DoubleExtension on double {
  /// Basamak sayisini sabitler ve gereksiz sifirlari atar.
  /// → `3.10.trimmed(1)` = `'3.1'`, `3.00.trimmed(1)` = `'3'`
  String trimmed(int fractionDigits) {
    final text = toStringAsFixed(fractionDigits);
    if (!text.contains('.')) return text;
    return text.replaceAll(RegExp(r'\.?0+$'), '');
  }
}

extension FileSizeExtension on int {
  /// Bayt degerini okunabilir boyuta cevirir. → `'1.4 MB'`
  String get readableFileSize {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var size = toDouble();
    var unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.trimmed(1)} ${units[unitIndex]}';
  }
}
