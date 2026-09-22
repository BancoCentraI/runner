import 'dart:async';

import 'package:akillisletme/product/cache/shared_operation/shared_cache.dart';
import 'package:akillisletme/product/cache/shared_operation/shared_keys.dart';
import 'package:akillisletme/product/service/subscription/purchase_service.dart';
import 'package:akillisletme/product/service/subscription/subscription_models.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_cubit.freezed.dart';
part 'subscription_state.dart';

/// App-geneli abonelik durumu.
///
/// Acilista once **yerel cache**'ten premium taninir (cevrimdisi acilista da
/// dogru davranis), ardindan RevenueCat stream'inden ve [init] senkronundan
/// tazelenir. Ozellik erisimi [isPremiumFor] ile sorgulanir.
class SubscriptionCubit extends Cubit<SubscriptionState>
    implements PremiumEntitlement {
  SubscriptionCubit({
    required PurchaseService purchaseService,
    required SharedCache cache,
  }) : _service = purchaseService,
       _cache = cache,
       super(
         SubscriptionState(
           isPremium: cache.getValue<bool>(SharedKeys.premiumActive) ?? false,
         ),
       ) {
    _subscription = _service.statusStream.listen(_onStatus);
  }

  final PurchaseService _service;
  final SharedCache _cache;
  StreamSubscription<SubscriptionStatus>? _subscription;

  /// Acilis senkronu: guncel durumu ceker (otomatik restore).
  Future<void> init() async {
    await _onStatus(await _service.refresh());
    if (!isClosed) emit(state.copyWith(isReady: true));
  }

  /// Paywall icin satin alinabilir planlari getirir. Bos olabilir — urun henuz
  /// import edilmemis demektir, hata degil.
  Future<SubscriptionOffering> fetchOffering() => _service.fetchOffering();

  /// Bir plani satin alir. Basariliysa durum stream uzerinden guncellenir.
  Future<PurchaseAttemptResult> purchase(String planId) =>
      _service.purchase(planId);

  /// Ayarlar'daki "Satin alimlari geri yukle" — iOS'ta magaza sarti.
  Future<void> restore() async {
    if (isClosed) return;
    emit(state.copyWith(isRestoring: true));
    await _onStatus(await _service.restore());
    if (!isClosed) emit(state.copyWith(isRestoring: false));
  }

  /// Oturum degisiminde cagrilir — abonelik kullanici hesabina baglanir.
  Future<void> syncUser(String? uid) => _service.setAppUserId(uid);

  /// Tum ozellikler icin tek kural: aktif abonelik. Ozellik bazli istisna
  /// gerekirse buraya dal eklenir.
  @override
  bool isPremiumFor(PremiumFeature feature) => state.isPremium;

  @override
  bool get hasAnyPremium => state.isPremium;

  Future<void> _onStatus(SubscriptionStatus status) async {
    // Cache'i guncel tut — bir sonraki acilis cevrimdisi de dogru tanisin.
    if ((_cache.getValue<bool>(SharedKeys.premiumActive) ?? false) !=
        status.isPremium) {
      await _cache.setValue(SharedKeys.premiumActive, status.isPremium);
    }
    if (!isClosed && state.isPremium != status.isPremium) {
      emit(state.copyWith(isPremium: status.isPremium));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
