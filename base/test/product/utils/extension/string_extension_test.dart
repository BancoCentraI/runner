import 'package:akillisletme/product/utils/extension/string_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalize', () {
    test('bastaki ve sondaki bosluklari kaldirir', () {
      expect('  merhaba  '.normalize, 'merhaba');
    });

    test('coklu boslugu tek boskluga indirir', () {
      expect('bir    iki\tuc'.normalize, 'bir iki uc');
    });

    test('satir sonu etrafindaki bosluklari kirpar', () {
      expect('bir   \n   iki'.normalize, 'bir\niki');
    });

    test('uc ve uzeri satir sonunu ikiye indirir', () {
      expect('bir\n\n\n\niki'.normalize, 'bir\n\niki');
    });

    test('iki satir sonuna dokunmaz', () {
      expect('bir\n\niki'.normalize, 'bir\n\niki');
    });
  });

  group('initials', () {
    test('iki kelimenin bas harflerini buyuk dondurur', () {
      expect('ada lovelace'.initials(), 'AL');
    });

    test('take ile sinirlanir', () {
      expect('ada king lovelace'.initials(), 'AK');
      expect('ada king lovelace'.initials(take: 3), 'AKL');
    });

    test('tek kelimede tek harf doner', () {
      expect('Ada'.initials(), 'A');
    });

    test('bos metinde soru isareti doner', () {
      expect('   '.initials(), '?');
    });
  });

  group('shortDisplayName', () {
    test('ilk ad + soyad bas harfi', () {
      expect('Ada Lovelace'.shortDisplayName, 'Ada L.');
    });

    test('ikiden fazla kelimede son kelime kisaltilir', () {
      expect('Ada King Lovelace'.shortDisplayName, 'Ada L.');
    });

    test('tek kelime oldugu gibi kalir', () {
      expect('Ada'.shortDisplayName, 'Ada');
    });

    test('bos metin bos doner', () {
      expect('  '.shortDisplayName, '');
    });
  });

  group('withHttps', () {
    test('semasi olmayan adrese https ekler', () {
      expect('example.com'.withHttps, 'https://example.com');
    });

    test('mevcut semaya dokunmaz', () {
      expect('http://example.com'.withHttps, 'http://example.com');
      expect('https://example.com'.withHttps, 'https://example.com');
    });
  });

  group('dogrulama yardimcilari', () {
    test('isValidEmail', () {
      expect('user@example.com'.isValidEmail, isTrue);
      expect('  user@example.com  '.isValidEmail, isTrue);
      expect('user@example'.isValidEmail, isFalse);
      expect('example.com'.isValidEmail, isFalse);
    });

    test('isValidPhone bicimlendirmeyi yok sayar', () {
      expect('+90 555 123 45 67'.isValidPhone, isTrue);
      expect('05551234567'.isValidPhone, isTrue);
      expect('12345'.isValidPhone, isFalse);
    });

    test('digitsOnly rakam disini atar', () {
      expect('+90 (555) 123-45-67'.digitsOnly, '905551234567');
    });
  });

  group('nullable yardimcilari', () {
    test('isNullOrBlank', () {
      expect((null as String?).isNullOrBlank, isTrue);
      expect(''.isNullOrBlank, isTrue);
      expect('   '.isNullOrBlank, isTrue);
      expect('a'.isNullOrBlank, isFalse);
    });

    test('orElse bos degerde yedegi doner', () {
      expect((null as String?).orElse('yedek'), 'yedek');
      expect('  '.orElse('yedek'), 'yedek');
      expect('deger'.orElse('yedek'), 'deger');
    });
  });

  test('capitalized yalnizca ilk harfi buyutur', () {
    expect('merhaba dunya'.capitalized, 'Merhaba dunya');
    expect(''.capitalized, '');
  });
}
