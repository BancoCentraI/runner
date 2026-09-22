# Extension'lar

`lib/product/utils/extension/` — tekrar eden dönüşümler burada toplanır. Aynı mantık ikinci kez yazılacaksa extension'a çıkar.

## context_extension.dart

**ResponsiveExtension** — ekran ölçeği ve boyut sorguları:

```dart
context.isWide            // genişlik > 600 (tablet / yatay)
context.isPortrait
context.r(AppPaddings.l)  // boyut ölçekle (0.85–1.25 clamp)
context.rf(16)            // yazı boyutu ölçekle (0.95–1.15 clamp)
context.widthRatio(.4)    // ekran genişliğinin %40'ı
context.heightRatio(.25)
```

**ThemeContextExtension** — kısa erişimler:

```dart
context.theme
context.colorScheme
context.textTheme
context.isDarkMode
context.isKeyboardOpen    // form ekranında buton konumlandırmak için
context.keyboardHeight
context.dismissKeyboard()
```

## string_extension.dart

```dart
'  bir   iki  '.normalize      // 'bir iki' — fazla boşluk/satır temizler
'Ada Lovelace'.initials()      // 'AL' — avatar fallback
'Ada Lovelace'.shortDisplayName // 'Ada L.'
'example.com'.withHttps        // 'https://example.com'
'merhaba'.capitalized          // 'Merhaba'
'user@example.com'.isValidEmail
'+90 555 123 45 67'.isValidPhone
'+90 (555) 123-45-67'.digitsOnly  // '905551234567'
await 'kopyalanacak'.copyToClipboard()
```

Nullable için:

```dart
value.isNullOrBlank
value.isNotNullOrBlank
value.orElse('varsayılan')
```

## date_time_extension.dart

Çıktı metinleri `LocaleKeys`'ten, ay/gün adları aktif locale'den gelir.

```dart
date.startOfDay
date.isToday / date.isYesterday
date.isNotExpired
date.hm                 // '14:30'
date.shortDate          // '12 Oca 2026'
date.dateTimeLabel      // '12 Oca 2026, 14:30'
date.timeAgo            // 'Az önce', '2 saat önce'
date.relativeDayLabel   // 'Bugün', 'Dün', '12 Ocak'
nullableDate.timeAgoOrNow  // null ise "şimdi" varsayar (server timestamp)
```

## num_extension.dart

```dart
5.padded                 // '05'
1250.grouped             // '1.250'
1200.compact             // '1.2K'
3.seconds                // Duration(seconds: 3)
3.10.trimmed(1)          // '3.1'
1536000.readableFileSize // '1.5 MB'
```

## Yeni extension yazarken

- Dosya adı `<tip>_extension.dart`, tek tip başına tek dosya.
- Extension'a isim ver (`extension StringExtension on String`) — isimsiz extension import edilemez.
- Kullanıcıya görünen metin döndüren her şey `LocaleKeys` kullanır; sabit Türkçe/İngilizce metin gömme.
- Extension davranışı testle gelir: `test/product/utils/extension/` altında aynı klasör yapısı.
- Tek bir feature'a özel dönüşümler `product/` altına değil, o feature'ın içine.
