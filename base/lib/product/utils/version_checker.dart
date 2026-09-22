import 'package:flutter/foundation.dart';

/// Semantic version karsilastirmasi — zorunlu guncelleme kontrolu icin.
///
/// Surumler **segment segment** karsilastirilir. Yaygin ve sessiz bir hata,
/// noktalari silip sayiya cevirmektir (`'1.2.10'` → `1210`): o yontem
/// `1.10.0` ile `1.2.0`'i yanlis siralar ve cok haneli bir minor/patch
/// cikinca guncelleme uyarisi hic gosterilmez.
///
/// ```dart
/// VersionChecker.isUpdateRequired(current: '1.2.10', minimum: '1.3.0'); // true
/// ```
@immutable
final class VersionChecker {
  const VersionChecker._();

  /// [current], [minimum]'dan kucukse `true` — yani guncelleme gerekiyor.
  ///
  /// Girdilerden biri okunamazsa `false` doner: surum bilgisi alinamadi diye
  /// kullaniciyi uygulamadan kilitlemek yanlis taraf.
  static bool isUpdateRequired({
    required String current,
    required String minimum,
  }) {
    if (current.trim().isEmpty || minimum.trim().isEmpty) return false;
    return compare(current, minimum) < 0;
  }

  /// [a] < [b] ise negatif, esitse 0, [a] > [b] ise pozitif.
  ///
  /// Eksik segmentler 0 sayilir (`'1.2'` == `'1.2.0'`). Build metadata
  /// (`+42`) ve on-surum eki (`-beta`) yok sayilir.
  static int compare(String a, String b) {
    final left = _segments(a);
    final right = _segments(b);
    final length = left.length > right.length ? left.length : right.length;

    for (var index = 0; index < length; index++) {
      final leftPart = index < left.length ? left[index] : 0;
      final rightPart = index < right.length ? right[index] : 0;
      if (leftPart != rightPart) return leftPart.compareTo(rightPart);
    }
    return 0;
  }

  static List<int> _segments(String version) {
    // '1.4.2+17-beta' → '1.4.2'
    final core = version.trim().split(RegExp('[+-]')).first;
    return core
        .split('.')
        .map((part) => int.tryParse(part.trim()) ?? 0)
        .toList();
  }
}
