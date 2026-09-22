part of 'splash_cubit.dart';

@freezed
abstract class SplashState with _$SplashState {
  /// Initial state before any checks
  const factory SplashState.initial() = _Initial;

  /// Performing version check
  const factory SplashState.checking() = _Checking;

  /// All checks passed, ready to proceed
  const factory SplashState.success() = _Success;

  /// App update is required
  const factory SplashState.updateRequired({
    required String currentVersion,
    required String minimumVersion,
  }) = _UpdateRequired;

  /// No internet connection — kullanici baglaniyi acip tekrar deneyebilir.
  const factory SplashState.offline() = _Offline;

  /// Error occurred during checks
  const factory SplashState.error({required String message}) = _Error;
}
