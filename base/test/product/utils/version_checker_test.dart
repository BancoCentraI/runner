import 'package:akillisletme/product/utils/version_checker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VersionChecker.compare', () {
    test('esit surumler 0 doner', () {
      expect(VersionChecker.compare('1.2.3', '1.2.3'), 0);
    });

    test('eksik segmentler 0 sayilir', () {
      expect(VersionChecker.compare('1.2', '1.2.0'), 0);
      expect(VersionChecker.compare('2', '2.0.0'), 0);
    });

    test('major segment once karsilastirilir', () {
      expect(VersionChecker.compare('1.9.9', '2.0.0'), lessThan(0));
      expect(VersionChecker.compare('2.0.0', '1.9.9'), greaterThan(0));
    });

    test('cok haneli segment dogru siralanir', () {
      // Noktalari silip sayiya ceviren yontem burada patlar:
      // '1.10.0' -> 1100 > '1.9.0' -> 190 sansen dogru cikar ama
      // '1.2.10' -> 1210 > '1.3.0' -> 130 yanlis sonuc verir.
      expect(VersionChecker.compare('1.10.0', '1.9.0'), greaterThan(0));
      expect(VersionChecker.compare('1.2.10', '1.3.0'), lessThan(0));
      expect(VersionChecker.compare('1.0.100', '1.0.99'), greaterThan(0));
    });

    test('build metadata ve on-surum eki yok sayilir', () {
      expect(VersionChecker.compare('1.2.3+45', '1.2.3'), 0);
      expect(VersionChecker.compare('1.2.3-beta', '1.2.3'), 0);
    });

    test('sayiya cevrilemeyen segment 0 sayilir', () {
      expect(VersionChecker.compare('1.x.3', '1.0.3'), 0);
    });
  });

  group('VersionChecker.isUpdateRequired', () {
    test('mevcut surum minimumun altindaysa true', () {
      expect(
        VersionChecker.isUpdateRequired(current: '1.2.10', minimum: '1.3.0'),
        isTrue,
      );
    });

    test('mevcut surum minimuma esit veya ustundeyse false', () {
      expect(
        VersionChecker.isUpdateRequired(current: '1.3.0', minimum: '1.3.0'),
        isFalse,
      );
      expect(
        VersionChecker.isUpdateRequired(current: '2.0.0', minimum: '1.3.0'),
        isFalse,
      );
    });

    test('surum bilgisi bos ise kullaniciyi kilitlemez', () {
      expect(
        VersionChecker.isUpdateRequired(current: '', minimum: '1.3.0'),
        isFalse,
      );
      expect(
        VersionChecker.isUpdateRequired(current: '1.0.0', minimum: '  '),
        isFalse,
      );
    });
  });
}
