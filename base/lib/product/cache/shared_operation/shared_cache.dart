import 'package:akillisletme/product/cache/shared_operation/base_shared_operation.dart';
import 'package:akillisletme/product/cache/shared_operation/shared_keys.dart';
import 'package:flutter/material.dart';

final class SharedCache {
  SharedCache._internal();
  static final SharedCache instance = SharedCache._internal();

  late final BaseSharedOperation _sharedOperation;

  Future<void> init() async {
    _sharedOperation = SharedOperation();
    await _sharedOperation.init();
  }

  Future<void> clear() async {
    await _sharedOperation.clear();
  }

  // ── Generic erişim ─────────────────────────────────────────
  T? getValue<T>(SharedKeys key) => _sharedOperation.getValue<T>(key);

  Future<void> setValue<T>(SharedKeys key, T value) async {
    await _sharedOperation.setValue<T>(key, value);
  }

  // ── First App Open ─────────────────────────────────────────
  bool get isFirstAppOpen =>
      _sharedOperation.getValue<bool>(SharedKeys.firstAppOpen) ?? true;

  Future<void> setFirstAppOpen() async {
    await _sharedOperation.setValue(SharedKeys.firstAppOpen, false);
  }

  // ── Onboarding ───────────────────────────────────────────
  bool get isOnboardingCompleted =>
      _sharedOperation.getValue<bool>(SharedKeys.onboardingCompleted) ?? false;

  Future<void> setOnboardingCompleted({required bool value}) async {
    await _sharedOperation.setValue(SharedKeys.onboardingCompleted, value);
  }

  // ── Background Animation ──────────────────────────────────
  bool get isBackgroundAnimationEnabled =>
      _sharedOperation.getValue<bool>(SharedKeys.backgroundAnimation) ?? true;

  Future<void> setBackgroundAnimation({required bool enabled}) async {
    await _sharedOperation.setValue(SharedKeys.backgroundAnimation, enabled);
  }

  // ── Theme ──────────────────────────────────────────────────
  ThemeMode get themeMode {
    final key = _sharedOperation.getValue<String>(SharedKeys.theme);
    if (key == null) return ThemeMode.system;
    return ThemeMode.values.firstWhere(
      (m) => m.name == key,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _sharedOperation.setValue<String>(SharedKeys.theme, mode.name);
  }
}
