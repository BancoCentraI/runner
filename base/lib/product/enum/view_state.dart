/// Veri ceken bir ekranin icinde bulunabilecegi dort durum.
///
/// `doc/guides/clean_code.md` → "Ekran durumlari": bu dortlunun tamami ele alinmadan
/// ekran bitmis sayilmaz. `AppStateView` bu enum'a gore dogru gorunumu secer.
enum ViewState {
  /// Veri bekleniyor.
  loading,

  /// Islem hatayla sonuclandi — kullaniciya anlamli mesaj + yeniden dene.
  error,

  /// Islem basarili ama sonuc bos. Bos liste hata degildir.
  empty,

  /// Gosterilecek veri var.
  data;

  bool get isLoading => this == ViewState.loading;
  bool get isError => this == ViewState.error;
  bool get isEmpty => this == ViewState.empty;
  bool get isData => this == ViewState.data;

  /// Yukleme/hata bayraklarindan ve veri boslugundan durum turetir.
  ///
  /// ```dart
  /// ViewState.from(
  ///   isLoading: state.isLoading,
  ///   hasError: state.errorMessage != null,
  ///   isEmpty: state.items.isEmpty,
  /// )
  /// ```
  static ViewState from({
    required bool isLoading,
    required bool hasError,
    required bool isEmpty,
  }) {
    if (isLoading) return ViewState.loading;
    if (hasError) return ViewState.error;
    if (isEmpty) return ViewState.empty;
    return ViewState.data;
  }
}
