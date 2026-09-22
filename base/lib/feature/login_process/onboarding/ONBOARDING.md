# Onboarding Sistemi

5 adimlik, PageView tabanli onboarding akisi. Tum adimlar bos template olarak gelir — icerik projeye gore doldurulur.

## Yapi

```
onboarding/
├── onboarding_view.dart           # Ana view — PageView + navigasyon kontrolleri
├── cubit/
│   └── onboarding_cubit.dart      # Sayfa navigasyonu + tamamlama state'i
├── steps/
│   ├── step1/step_1.dart          # Adim 1 (ornek: Hos geldiniz)
│   ├── step2/step_2.dart          # Adim 2
│   ├── step3/step_3.dart          # Adim 3
│   ├── step4/step_4.dart          # Adim 4
│   └── step_5.dart                # Adim 5 — Son adim (Baslayalim butonu)
└── ONBOARDING.md                  # Bu dosya
```

## Nasil Calisir

1. `OnboardingView` bir `PageView` icerir, her sayfa bir step widget'idir
2. `OnboardingCubit` mevcut sayfa index'ini tutar ve sayfa gecislerini yonetir
3. Her step'in altinda `AppPrimaryButton` ile ilerleme saglanir
4. Son adimda buton `completeOnboarding()` cagirarak:
   - `SharedCache`'e `onboardingCompleted = true` yazar
   - `context.go('/')` ile ana sayfaya yonlendirir
5. Alt kisimda `SmoothPageIndicator` ile sayfa gostergesi bulunur

## Adim Ekleme / Cikarma

1. `steps/` altinda yeni bir step dosyasi olustur
2. `onboarding_view.dart`'taki `PageView.children` listesine ekle
3. `OnboardingCubit.totalPages` sayisini guncelle

## Icerik Ekleme

Her step dosyasindaki `TODO` yorumlarini takip et. Ornek:

```dart
class Step1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Buraya icerik ekle: baslik, aciklama, gorseller vs.
              const Spacer(),
              AppPrimaryButton(
                label: 'Devam Et',
                onPressed: () => context.read<OnboardingCubit>().nextPage(),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
```

## Rota

| Rota | Dosya | Aciklama |
|------|-------|----------|
| `/onboarding` | `app_router.dart` | Onboarding akisini baslatir |

## Cache

| Key | Tip | Aciklama |
|-----|-----|----------|
| `onboardingCompleted` | `bool` | Onboarding tamamlandi mi |

Erisim: `locator.sharedCache.isOnboardingCompleted`

## Bagimliliklari

- `flutter_bloc` — State yonetimi (OnboardingCubit)
- `smooth_page_indicator` — Sayfa gostergesi
- `go_router` — Navigasyon
- `SharedCache` — Tamamlama durumu kaydi
