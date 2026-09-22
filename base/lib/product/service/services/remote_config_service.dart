import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Minimum surum kaynagi icin dar arayuz.
///
/// `SplashCubit` yalnizca buna baglidir; boylece testlerde Firebase'siz sahte
/// bir kaynak verilebilir ve Firebase kapaliyken [StaticVersionSource] devreye
/// girer.
abstract interface class AppVersionSource {
  /// Uzaktan gelen minimum gerekli surum (orn. `'2.0.4'`).
  String get minVersion;
}

/// Firebase kapaliyken kullanilan kaynak — zorunlu guncelleme hic tetiklenmez.
final class StaticVersionSource implements AppVersionSource {
  const StaticVersionSource();

  /// `0.0.0` her surumden kucuktur, dolayisiyla guncelleme istenmez.
  @override
  String get minVersion => '0.0.0';
}

/// Firebase Remote Config sarmalayicisi — zorunlu guncelleme icin minimum
/// surumu tasir.
///
/// **Minimum surum PLATFORM SPESIFIKTIR.** Console'da iki ayri anahtar tanimlanir:
/// `version_ios` ve `version_android` (string, orn. `2.0.6`).
///
/// Neden: iki magaza ayri hizda ilerler. Tek anahtar olsaydi, Android'e 2.0.7
/// cikip `version = 2.0.7` yapilinca App Store'da henuz 2.0.7 OLMAYAN iOS
/// kullanicilari da guncellemeye zorlanir ve indirecek surum bulunmadigi icin
/// ekranda **kilitlenirdi**.
///
/// Gecis: platform anahtari Console'da henuz tanimli degilse eski tek `version`
/// anahtarina duser — iki yeni anahtar olusturulana kadar akis bozulmaz.
final class RemoteConfigService implements AppVersionSource {
  RemoteConfigService._();
  static final RemoteConfigService instance = RemoteConfigService._();

  late final FirebaseRemoteConfig _remoteConfig;

  /// Eski tek anahtar — yalniz gecis donemi fallback'i.
  static const String _versionKeyLegacy = 'version';
  static const String _versionKeyIos = 'version_ios';
  static const String _versionKeyAndroid = 'version_android';

  /// Anahtar hic tanimlanmamissa guncelleme istenmesin.
  static const String _defaultVersion = '0.0.0';

  Future<void> init() async {
    _remoteConfig = FirebaseRemoteConfig.instance;

    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 3),
        // Debug'da her acilista taze cek; uretimde Firebase kotasini korumak
        // icin saatte bir.
        minimumFetchInterval: kDebugMode
            ? Duration.zero
            : const Duration(hours: 1),
      ),
    );

    await _remoteConfig.setDefaults(<String, dynamic>{
      _versionKeyLegacy: _defaultVersion,
      _versionKeyIos: _defaultVersion,
      _versionKeyAndroid: _defaultVersion,
    });

    try {
      await _remoteConfig.fetchAndActivate().timeout(
        const Duration(seconds: 4),
        onTimeout: () => false,
      );
    } on Exception catch (_) {
      // Cekilemezse varsayilanlarla devam — acilis ASLA bloklanmaz.
    }
  }

  @override
  String get minVersion {
    final key = defaultTargetPlatform == TargetPlatform.iOS
        ? _versionKeyIos
        : _versionKeyAndroid;

    // Platform anahtari Console'da TANIMLIYSA (uzaktan geldiyse) onu kullan.
    final platformValue = _remoteConfig.getValue(key);
    if (platformValue.source == ValueSource.valueRemote) {
      final value = platformValue.asString();
      if (value.isNotEmpty) return value;
    }

    final legacy = _remoteConfig.getString(_versionKeyLegacy);
    return legacy.isNotEmpty ? legacy : _defaultVersion;
  }

  Future<void> refresh() async {
    try {
      await _remoteConfig.fetchAndActivate();
    } on Exception catch (_) {
      // Sessiz basarisizlik — onbellekteki degerler kullanilir.
    }
  }
}
