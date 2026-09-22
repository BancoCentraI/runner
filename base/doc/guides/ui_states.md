# Ekran Durumları (loading / error / empty / data)

`doc/guides/clean_code.md` → "Ekran durumları": veri çeken her ekran bu dördünü ele alır. Biri eksikse ekran bitmemiştir. Bu rehber, dördünü elle yazmadan kullanmanın yolunu anlatır.

## ViewState

`lib/product/enum/view_state.dart`

```dart
ViewState.from(
  isLoading: state.isLoading,
  hasError: state.errorMessage != null,
  isEmpty: state.items.isEmpty,
)
```

Öncelik sırası sabittir: **loading → error → empty → data**. Boş liste hata değildir.

## AppStateView

`lib/product/widget/state/app_state_view.dart` — dört durumu tek yerde çözer.

```dart
BlocBuilder<TaskCubit, TaskState>(
  builder: (context, state) => AppStateView(
    state: ViewState.from(
      isLoading: state.isLoading,
      hasError: state.errorMessage != null,
      isEmpty: state.tasks.isEmpty,
    ),
    errorMessage: state.errorMessage,
    onRetry: context.read<TaskCubit>().load,
    loadingPlaceholder: const AppShimmerList(),
    emptyTitle: LocaleKeys.tasks_emptyTitle.tr(),
    emptyActionLabel: LocaleKeys.tasks_create.tr(),
    onEmptyAction: () => const CreateTaskRoute().push(context),
    builder: () => TaskList(tasks: state.tasks),
  ),
)
```

`builder` **yalnızca data durumunda** çalışır. Bu yüzden içinde `state.items.first` gibi erişimler güvenlidir.

## Tek tek widget'lar

| Widget | Kullanım |
|---|---|
| `AppLoadingView` | Ortalanmış gösterge. `showMessage: true` ile metin. |
| `AppErrorView` | İkon + başlık + mesaj + "tekrar dene". `AppErrorView.offline()` bağlantı varyantı. |
| `AppEmptyView` | Boş durum. Varsayılan olarak retry göstermez; ileri götüren bir aksiyon alabilir. |
| `AppMessageView` | Üçünün ortak düzeni. İzin/uyarı gibi özel durumlar için doğrudan kullanılır. |
| `AppShimmer` / `AppShimmerBox` / `AppShimmerList` | İskelet placeholder. |

## Shimmer mi spinner mı?

İçeriğin şekli önceden biliniyorsa (liste, kart ızgarası) **shimmer** kullan — algılanan hız belirgin şekilde artar:

```dart
loadingPlaceholder: const AppShimmerList(itemCount: 6, itemHeight: 76)
```

Kendi iskeletini kurmak için:

```dart
AppShimmer(
  child: Column(
    spacing: AppPaddings.m,
    children: [
      AppShimmerBox(height: 180, borderRadius: AppRadius.card),
      const AppShimmerBox(height: 20, width: 140),
    ],
  ),
)
```

## Hata mesajı kuralı

`errorMessage` **yerelleştirilmiş kullanıcı metnidir**. Cubit ham exception'ı asla state'e koymaz:

```dart
} on Object catch (error, stackTrace) {
  AppErrorHandler.reportHandled(error, stackTrace);   // ham hata log'a
  emit(state.copyWith(errorMessage: LocaleKeys.error_generic.tr()));
}
```

Hazır anahtarlar: `error.generic`, `error.network`, `error.timeout`, `error.permission`.

## Bloke edici hata

Ekran içinde değil, akışı durduran bir hata (açılış kontrolü, zorunlu yükleme) için sheet kullanılır:

```dart
final shouldRetry = await AppErrorSheet.show(context, isOffline: true) ?? false;
if (shouldRetry) await cubit.retry();
```

## Checklist

- [ ] `ViewState.from(...)` ile durum türetildi
- [ ] `onRetry` bağlandı (error durumunda kullanıcı sıkışmıyor)
- [ ] Boş durum hata gibi gösterilmiyor
- [ ] Liste ekranında `loadingPlaceholder` verildi
- [ ] `errorMessage` yerelleştirilmiş, ham exception değil
