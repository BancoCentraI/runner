import 'dart:async';
import 'dart:io';

import 'package:akillisletme/product/const/app_durations.dart';
import 'package:flutter/foundation.dart';

/// Gercek internet erisimi kontrolu.
///
/// Cihazin Wi-Fi'a bagli olmasi internetin oldugu anlamina gelmez (captive
/// portal, DNS'i cevaplamayan ag). Bu yuzden arayuz durumu yerine **gercek bir
/// DNS cozumlemesi** denenir.
///
/// Surekli dinleme (baglanti acildi/kapandi olayi) gerekiyorsa `connectivity_plus`
/// eklenip bu sinifin arkasina konabilir; template varsayilan olarak ek paket
/// tasimaz.
@immutable
final class NetworkChecker {
  const NetworkChecker._();

  /// Cozumleme icin denenen alan adlari. Biri engelliyse digeri denenir.
  static const List<String> _probeHosts = ['one.one.one.one', 'dns.google'];

  /// Internet erisimi var mi.
  ///
  /// Web'de `dart:io` calismadigi icin daima `true` doner — tarayici zaten
  /// cevrimici olmadan uygulamayi yukleyemez.
  static Future<bool> hasConnection({
    Duration timeout = AppDurations.networkTimeout,
  }) async {
    if (kIsWeb) return true;

    for (final host in _probeHosts) {
      if (await _canResolve(host, timeout)) return true;
    }
    return false;
  }

  static Future<bool> _canResolve(String host, Duration timeout) async {
    try {
      final addresses = await InternetAddress.lookup(host).timeout(timeout);
      return addresses.isNotEmpty && addresses.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    }
  }
}
