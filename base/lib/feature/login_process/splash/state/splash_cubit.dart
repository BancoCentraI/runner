import 'package:akillisletme/product/init/app_error_handler.dart';
import 'package:akillisletme/product/init/language/locale_keys.g.dart';
import 'package:akillisletme/product/service/services/remote_config_service.dart';
import 'package:akillisletme/product/utils/network_checker.dart';
import 'package:akillisletme/product/utils/version_checker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:package_info_plus/package_info_plus.dart';

part 'splash_cubit.freezed.dart';
part 'splash_state.dart';

/// Acilis kapisi: baglanti → zorunlu surum → devam.
///
/// Her dal ayri bir state uretir; view yalnizca cizer. Hicbir exception
/// yutulmaz, hepsi [SplashState.error]'a cevrilir ve raporlanir.
class SplashCubit extends Cubit<SplashState> {
  SplashCubit({
    required AppVersionSource versionSource,
    this.requiresNetwork = false,
  }) : _versionSource = versionSource,
       super(const SplashState.initial());

  final AppVersionSource _versionSource;

  /// Uygulama acilista veri cekiyorsa `true` yap — baglanti yoksa kullanici
  /// bos/kirik bir ekran yerine "tekrar dene" gorur.
  ///
  /// Template varsayilani `false`: kutudan cikan hali hicbir uzak kaynaga
  /// bagimli degil. Firebase veya bir API acildiginda `true` yapilir.
  final bool requiresNetwork;

  /// Acilis kontrollerini calistirir.
  Future<void> checkApp() async {
    emit(const SplashState.checking());

    try {
      if (requiresNetwork && !await NetworkChecker.hasConnection()) {
        emit(const SplashState.offline());
        return;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final minimumVersion = _versionSource.minVersion;

      if (VersionChecker.isUpdateRequired(
        current: currentVersion,
        minimum: minimumVersion,
      )) {
        emit(
          SplashState.updateRequired(
            currentVersion: currentVersion,
            minimumVersion: minimumVersion,
          ),
        );
        return;
      }

      emit(const SplashState.success());
    } on Object catch (error, stackTrace) {
      // Ham exception kullaniciya gosterilmez; log'a gider, ekrana
      // yerellestirilmis mesaj cikar.
      AppErrorHandler.reportHandled(error, stackTrace);
      emit(SplashState.error(message: LocaleKeys.error_generic.tr()));
    }
  }

  /// Hata veya baglanti ekranindaki "tekrar dene".
  Future<void> retry() => checkApp();
}
