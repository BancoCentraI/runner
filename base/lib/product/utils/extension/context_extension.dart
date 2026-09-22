import 'package:flutter/material.dart';

/// Ekran boyutuna gore olcekleme ve sik kullanilan boyut sorgulari.
///
/// Olcek, tasarim referans genisligine (`_baseWidth`) gore hesaplanir ve
/// clamp'lenir: kucuk telefonda okunmaz kadar kuculmez, tablette orantisiz
/// buyumez.
///
/// ```dart
/// SizedBox(height: context.r(AppPaddings.l))   // boyut olcekle
/// Icon(Icons.star, size: context.r(AppIconSizes.m))
/// if (context.isWide) ...                      // tablet/genis ekran dali
/// ```
extension ResponsiveExtension on BuildContext {
  /// Tasarimin referans aldigi cihaz genisligi (mantiksal piksel).
  static const double _baseWidth = 390;

  /// Genis ekran esigi — tablet ve yatay telefon.
  static const double wideBreakpoint = 600;

  Size get screenSize => MediaQuery.sizeOf(this);

  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;

  /// Tablet / genis ekran mi.
  bool get isWide => screenWidth > wideBreakpoint;

  /// Ekran yuksekligi genisliginden buyuk mu (dikey yerlesim).
  bool get isPortrait => screenHeight >= screenWidth;

  /// Boyut olcegi. Asiri kucuk/buyuk ekranlarda kontrolden cikmasin diye
  /// clamp'lidir.
  double get _scale => (screenWidth / _baseWidth).clamp(0.85, 1.25);

  /// Boyut olcekle — padding, ikon, yukseklik icin.
  double r(double value) => value * _scale;

  /// Yazi boyutu olcekle. Metin okunabilirligi boyuttan daha hassas oldugu icin
  /// olcek araligi daha dardir.
  double rf(double value) => value * _scale.clamp(0.95, 1.15);

  /// Ekran genisliginin yuzdesi. → `context.widthRatio(.4)`
  double widthRatio(double ratio) => screenWidth * ratio;

  /// Ekran yuksekliginin yuzdesi. → `context.heightRatio(.25)`
  double heightRatio(double ratio) => screenHeight * ratio;
}

/// Tema ve klavye icin kisa erisimler.
///
/// ```dart
/// Text('x', style: context.textTheme.titleMedium)
/// ColoredBox(color: context.colorScheme.surface)
/// if (context.isKeyboardOpen) ...
/// ```
extension ThemeContextExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Klavye acik mi — form ekranlarinda buton konumlandirmak icin.
  bool get isKeyboardOpen => MediaQuery.viewInsetsOf(this).bottom > 0;

  /// Klavyenin kapladigi yukseklik.
  double get keyboardHeight => MediaQuery.viewInsetsOf(this).bottom;

  /// Klavyeyi kapat.
  void dismissKeyboard() => FocusScope.of(this).unfocus();
}
