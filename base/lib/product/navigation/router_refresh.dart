import 'dart:async';

import 'package:flutter/foundation.dart';

/// Bir [Stream]'i GoRouter'in `refreshListenable`'ina koprular: stream'e her
/// olay dustugunde router `redirect`'i yeniden degerlendirir.
///
/// Auth-gating icin oturum stream'iyle kullanilir — cikis yapildigi anda
/// korumali sayfadan otomatik cikarilir.
final class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
