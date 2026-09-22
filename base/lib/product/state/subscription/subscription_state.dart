part of 'subscription_cubit.dart';

@freezed
abstract class SubscriptionState with _$SubscriptionState {
  const factory SubscriptionState({
    @Default(false) bool isPremium,

    /// Acilis senkronu tamamlandi mi? Tamamlanmadan once [isPremium] yerel
    /// cache'ten gelir — gosterilebilir ama "kesin" degildir.
    @Default(false) bool isReady,

    @Default(false) bool isRestoring,
  }) = _SubscriptionState;

  const SubscriptionState._();
}
