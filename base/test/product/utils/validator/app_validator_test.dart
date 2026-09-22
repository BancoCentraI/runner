import 'package:akillisletme/product/utils/validator/app_validator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helper/pump_app.dart';

/// Testler hata **metnini** degil, gecerlilik kararini dogrular: metin
/// ceviriden gelir ve degisebilir, kural degismez.
void main() {
  setUpAll(initializeTestBindings);

  group('required', () {
    test('bos deger reddedilir', () {
      expect(Validators.required.isValid(null), isFalse);
      expect(Validators.required.isValid(''), isFalse);
      expect(Validators.required.isValid('   '), isFalse);
    });

    test('dolu deger kabul edilir', () {
      expect(Validators.required.isValid('a'), isTrue);
    });
  });

  test('optional her degeri kabul eder', () {
    expect(Validators.optional.isValid(null), isTrue);
    expect(Validators.optional.isValid(''), isTrue);
  });

  group('email', () {
    test('gecerli adres kabul edilir', () {
      expect(Validators.email.isValid('user@example.com'), isTrue);
    });

    test('gecersiz adres reddedilir', () {
      expect(Validators.email.isValid('user@example'), isFalse);
      expect(Validators.email.isValid('example.com'), isFalse);
    });

    test('zorunlu varyantta bos deger reddedilir', () {
      expect(Validators.email.isValid(''), isFalse);
    });

    test('opsiyonel varyantta bos deger kabul edilir', () {
      expect(Validators.optionalEmail().isValid(''), isTrue);
      expect(Validators.optionalEmail().isValid('bozuk'), isFalse);
    });
  });

  group('password', () {
    test('8 karakter, harf ve rakam sarti', () {
      expect(Validators.password.isValid('sifre123'), isTrue);
      expect(Validators.password.isValid('kisa1'), isFalse);
      expect(Validators.password.isValid('yalnizcaharf'), isFalse);
      expect(Validators.password.isValid('12345678'), isFalse);
    });
  });

  group('numericRange', () {
    final validator = Validators.numericRange(min: 1, max: 10);

    test('aralik icindeki deger kabul edilir', () {
      expect(validator.isValid('1'), isTrue);
      expect(validator.isValid('10'), isTrue);
    });

    test('aralik disindaki deger reddedilir', () {
      expect(validator.isValid('0'), isFalse);
      expect(validator.isValid('11'), isFalse);
    });

    test('sayi olmayan deger reddedilir', () {
      expect(validator.isValid('bes'), isFalse);
    });

    test('opsiyonel varyantta bos deger kabul edilir', () {
      expect(
        Validators.numericRange(min: 1, isOptional: true).isValid(''),
        isTrue,
      );
    });
  });

  group('match', () {
    test('esit degerler kabul edilir', () {
      expect(Validators.match(() => 'sifre123').isValid('sifre123'), isTrue);
    });

    test('farkli degerler reddedilir', () {
      expect(Validators.match(() => 'sifre123').isValid('sifre124'), isFalse);
    });
  });

  group('minLength / maxLength', () {
    test('minLength bosluklari saymaz', () {
      expect(Validators.minLength(3).isValid('  ab  '), isFalse);
      expect(Validators.minLength(3).isValid('abc'), isTrue);
    });

    test('maxLength null degeri gecirir', () {
      expect(Validators.maxLength(3).isValid(null), isTrue);
      expect(Validators.maxLength(3).isValid('abcd'), isFalse);
    });
  });

  group('all', () {
    final validator = Validators.all([
      Validators.required,
      Validators.minLength(3),
    ]);

    test('ilk basarisiz kural hatayi belirler', () {
      expect(validator.isValid(''), isFalse);
      expect(validator.isValid('ab'), isFalse);
      expect(validator.isValid('abc'), isTrue);
    });
  });

  test('fullName ad + soyad bekler', () {
    expect(Validators.fullName.isValid('Ada Lovelace'), isTrue);
    expect(Validators.fullName.isValid('Ada'), isFalse);
  });
}
