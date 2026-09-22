import 'dart:async';

import 'package:akillisletme/product/init/app_error_handler.dart';
import 'package:akillisletme/product/service/firebase/auth/auth_service.dart';
import 'package:akillisletme/product/state/auth/auth_error_localizer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_cubit.freezed.dart';
part 'auth_state.dart';

/// Bir auth aksiyonunun sonucu: basari, kullanici iptali veya hata.
///
/// Iptal ve basari **ayri** tutulur; aksi halde yarida birakilan bir giris
/// (Google/Apple sayfasinin kapatilmasi) basari sanilir ve oturum acilmadigi
/// halde "giris basarili" gosterilir.
sealed class AuthActionResult {
  const AuthActionResult();
}

/// Aksiyon tamamlandi (oturum acildi / e-posta gonderildi).
final class AuthActionSuccess extends AuthActionResult {
  const AuthActionSuccess();
}

/// Kullanici akisi yarida birakti — ne hata ne basari mesaji gosterilir.
final class AuthActionCanceled extends AuthActionResult {
  const AuthActionCanceled();
}

/// Aksiyon hata verdi; [message] gosterime hazir, yerellestirilmis metindir.
final class AuthActionFailure extends AuthActionResult {
  const AuthActionFailure(this.message);
  final String message;
}

/// Oturum akisini yoneten app-geneli cubit.
///
/// Aksiyon metotlari **emit yapmaz**: durum daima
/// [AuthService.authStateChanges] stream'inden akar. Metotlar yalnizca servisi
/// cagirir ve [AuthActionResult] dondurur; ekran sonuca gore geri bildirim
/// gosterir.
///
/// Ayrinti: `doc/guides/auth.md`
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._auth) : super(AuthState.fromUser(_auth.currentUser)) {
    _syncIdentity(_auth.currentUser);
    _subscription = _auth.authStateChanges().listen((user) {
      emit(AuthState.fromUser(user));
      _syncIdentity(user);
    });
  }

  final AuthService _auth;
  late final StreamSubscription<AppUser?> _subscription;

  // ── Aksiyonlar ─────────────────────────────────────────────

  Future<AuthActionResult> signInWithEmail(String email, String password) =>
      _run(() => _auth.signInWithEmail(email, password));

  Future<AuthActionResult> register({
    required String email,
    required String password,
    String? name,
  }) => _run(() => _auth.registerWithEmail(email, password, name: name));

  Future<AuthActionResult> sendPasswordReset(String email) =>
      _run(() => _auth.sendPasswordReset(email));

  Future<AuthActionResult> signInWithGoogle() => _run(_auth.signInWithGoogle);

  Future<AuthActionResult> signInWithApple() => _run(_auth.signInWithApple);

  Future<AuthActionResult> sendEmailVerification() =>
      _run(_auth.sendEmailVerification);

  Future<void> signOut() => _auth.signOut();

  /// Kullaniciyi sunucudan tazeleyip guncel dogrulama durumunu dondurur
  /// (kullanici e-postadaki baglantiya tikladiktan sonra "Dogruladim"a basinca).
  ///
  /// Elle emit sart: `emailVerified` degisimi `authStateChanges`'i tetiklemez,
  /// stream'i beklersek durum bir sonraki girise kadar eski kalirdi.
  Future<bool> reloadEmailVerified() async {
    final verified = await _auth.reloadEmailVerified();
    if (!isClosed && verified != state.emailVerified) {
      emit(state.copyWith(emailVerified: verified));
    }
    return verified;
  }

  /// Profil adini gunceller ve durumu aninda yansitir.
  ///
  /// `updateDisplayName` de `authStateChanges`'i tetiklemez — stream beklenirse
  /// ad ekranda degismezdi.
  Future<AuthActionResult> updateDisplayName(String name) async {
    final result = await _run(() => _auth.updateDisplayName(name));
    if (result is AuthActionSuccess && !isClosed) {
      emit(state.copyWith(name: name.trim()));
    }
    return result;
  }

  /// Hesabi kalici olarak siler (magaza sarti: App Store 5.1.1(v) + Play).
  ///
  /// Sira bilincli:
  /// 1. **Yeniden dogrulama** — saglayiciya gore sifre / Google / Apple.
  ///    Firebase 5 dakikadan taze giris ister; e-posta kullanicisinda
  ///    [password] zorunludur (UI dialog'la toplar).
  /// 2. **Silme** — Firebase kullaniciyi siler.
  /// 3. **Yerel cikis** — silme sonrasi stream zaten `null`a duser, ancak
  ///    garanti icin cagrilir.
  Future<AuthActionResult> deleteAccount({String? password}) {
    return _run(() async {
      switch (state.providerId) {
        case 'google.com':
          await _auth.reauthenticateWithGoogle();
        case 'apple.com':
          await _auth.reauthenticateWithApple();
        default:
          // E-posta saglayicisi — sifresiz gelmek UI hatasidir.
          if (password == null || password.isEmpty) {
            throw const AuthException('generic');
          }
          await _auth.reauthenticateWithPassword(password);
      }

      await _auth.deleteAccount();

      try {
        await _auth.signOut();
      } on Object catch (error, stackTrace) {
        // Kullanici sunucuda coktan yok; yerel cikis hata verse bile
        // authStateChanges eninde sonunda null'a duser.
        AppErrorHandler.reportHandled(error, stackTrace);
      }
    });
  }

  // ── Ic isler ───────────────────────────────────────────────

  /// Kullanici kimligini hata raporlama kanalina yayar (cikista `null`).
  void _syncIdentity(AppUser? user) {
    unawaited(AppErrorHandler.setUserId(user?.uid));
  }

  /// Aksiyonu calistirir; basari / iptal / hata ayri sonuclar doner.
  /// Oturum degisimi stream uzerinden yansidigi icin burada emit yapilmaz.
  Future<AuthActionResult> _run(Future<void> Function() action) async {
    try {
      await action();
      return const AuthActionSuccess();
    } on AuthException catch (error) {
      if (error.isCanceled) return const AuthActionCanceled();
      // Ham kodu logla, kullaniciya yerellestirilmis mesaj goster.
      AppErrorHandler.reportHandled(error);
      return AuthActionFailure(AuthErrorLocalizer.message(error.code));
    } on Object catch (error, stackTrace) {
      AppErrorHandler.reportHandled(error, stackTrace);
      return AuthActionFailure(AuthErrorLocalizer.message('generic'));
    }
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
