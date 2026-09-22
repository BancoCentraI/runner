# Flutter Temiz Kod Standardı

Bu dosya, projede yazılan **her satır kodda** geçerli olan taşınabilir kod standardıdır. Mimari dayatmaz: projenin mevcut yapısı neyse (Cubit+Freezed, GetIt locator, GoRouter) **ona uy** — bu dosya o yapının *içinde* yazılan kodun kalitesini belirler. Başka bir Flutter projesine olduğu gibi taşınabilir.

## Önce projeyi tanı

Kod yazmadan önce: projede aynı türde iş nasıl yapılmış bak (benzer bir ekran, benzer bir servis) ve o deseni takip et. Projede iki farklı desen varsa hangisinin güncel olduğunu sor. Yeni desen icat etme.

## Widget kuralları

- Önce `StatelessWidget`; `StatefulWidget` sadece gerçekten yerel state varsa.
- `build()` içinde ağır işlem yok: hesaplama, parse, sıralama, network build dışında.
- `build()` ~80 satırı geçiyorsa parçala. Tekrar eden UI, metot değil ayrı widget sınıfına çıkar (rebuild optimizasyonu için).
- Mümkün olan her yerde `const`.
- State'i mümkün olan en dar kapsamda tut; dinlemeyi (watch/listen) sadece ihtiyacı olan widget yapar.
- İş mantığı widget'ta olmaz; widget çizer ve event iletir.

## Ekran durumları

Veri çeken her ekran dört durumu ele alır: **loading**, **error** (anlamlı mesaj + yeniden dene), **empty** (boş liste ≠ hata), **data**. Bunlardan biri eksikse ekran bitmemiştir.

## Hata yönetimi

- Boş `catch {}` yasak; exception sessizce yutulmaz.
- Hata yakalandığı katmanda loglanır, anlamlı bir tipe çevrilip yukarı iletilir; UI ham exception görmez.
- Her `async` çağrıda dört senaryo düşünülür: timeout, ağ yok, yetki hatası, boş/beklenmeyen yanıt.
- Kullanıcıya teknik mesaj gösterilmez; anlaşılır, yerelleştirilmiş mesaj gösterilir.

## Kod düzeni

- Effective Dart'a ve projedeki `analysis_options.yaml`'a uy.
- Dosya adları `snake_case.dart`; bir dosya bir ana sınıf.
- Kod tekrarı: aynı mantık ikinci kez yazılacaksa ortak fonksiyona/widget'a/extension'a çıkar.
- Magic number/string bırakma; anlamlı sabite çevir ve projenin sabit dosyasına koy.
- Yorum "ne yaptığını" değil "neden yapıldığını" anlatır. Bariz kodu yorumlama.
- Ölü kod bırakma: yorum satırına alınmış eski kod commit'lenmez, silinir.

## Paket disiplini

- Projede zaten çözümü olan iş için yeni paket ekleme (tarih için `intl` varsa ikinci tarih paketi ekleme gibi).
- Yeni paket eklemeden önce SOR ve gerekçe sun. Birkaç satır kodla çözülen iş için paket ekleme.
- Animasyonda önce Flutter'ın kendi araçları (implicit: `AnimatedContainer`, `AnimatedOpacity`, `AnimatedSwitcher`; gerekirse explicit `AnimationController`).

## Test

- Yeni iş mantığı (servis/viewmodel/cubit metodu) test ile gelir; test dosyası kaynakla aynı klasör yapısında `test/` altındadır.
- Test edilebilirlik için bağımlılıklar constructor'dan alınabilir olmalı; yeni sınıfa global erişim (singleton'a doğrudan çağrı) gömme.

## Bitirme kontrolü

Her görev şununla kapanır:

```bash
./script/verify.sh      # dart format → flutter analyze → flutter test
```

Ek olarak elle doğrula:

1. Codegen gerekiyorsa `./script/codegen.sh` çalıştırıldı mı.
2. Çeviri anahtarı eklendiyse `./script/lang.sh` çalıştırıldı mı (ve anahtar **hem** `tr.json` **hem** `en.json`'da mı).
3. Yeni ekranlarda dört durum (loading/error/empty/data) ele alındı mı — `doc/guides/ui_states.md`.
4. `flutter analyze` sıfır uyarı verdi mi. `// ignore:` ile susturma yok; çözemiyorsan sor.
5. Kırmızı test bırakılmadı mı.
