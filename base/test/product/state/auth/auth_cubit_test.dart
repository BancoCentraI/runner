import 'package:akillisletme/product/service/firebase/auth/auth_service.dart';
import 'package:akillisletme/product/service/firebase/auth/mock_auth_service.dart';
import 'package:akillisletme/product/state/auth/auth_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helper/pump_app.dart';

/// Basarisiz senaryolari uretmek icin — `MockAuthService` her zaman basarili.
///
/// `MockAuthService` `final class` oldugu icin genisletilemez; sozlesmeyi
/// sarmalayarak yalnizca ilgili metotlari degistiriyoruz (delegation).
final class _FailingAuthService implements AuthService {
  _FailingAuthService(this.code);

  final String code;
  final MockAuthService _inner = MockAuthService();

  @override
  Future<void> signInWithEmail(String email, String password) async =>
      throw AuthException(code);

  @override
  Future<void> signInWithGoogle() async =>
      throw const AuthException('canceled');

  @override
  Stream<AppUser?> authStateChanges() => _inner.authStateChanges();

  @override
  AppUser? get currentUser => _inner.currentUser;

  @override
  Future<void> registerWithEmail(
    String email,
    String password, {
    String? name,
  }) => _inner.registerWithEmail(email, password, name: name);

  @override
  Future<void> sendPasswordReset(String email) =>
      _inner.sendPasswordReset(email);

  @override
  Future<void> signInWithApple() => _inner.signInWithApple();

  @override
  Future<void> updateDisplayName(String name) => _inner.updateDisplayName(name);

  @override
  Future<void> updatePhotoUrl(String? url) => _inner.updatePhotoUrl(url);

  @override
  Future<void> sendEmailVerification() => _inner.sendEmailVerification();

  @override
  Future<bool> reloadEmailVerified() => _inner.reloadEmailVerified();

  @override
  Future<void> reauthenticateWithPassword(String password) =>
      _inner.reauthenticateWithPassword(password);

  @override
  Future<void> reauthenticateWithGoogle() => _inner.reauthenticateWithGoogle();

  @override
  Future<void> reauthenticateWithApple() => _inner.reauthenticateWithApple();

  @override
  Future<void> deleteAccount() => _inner.deleteAccount();

  @override
  Future<void> signOut() => _inner.signOut();
}

void main() {
  setUpAll(initializeTestBindings);

  test('baslangicta oturumsuz', () {
    final cubit = AuthCubit(MockAuthService());
    expect(cubit.state.isLoggedIn, isFalse);
    expect(cubit.state.uid, isNull);
  });

  test('giris state\'i stream uzerinden gunceller', () async {
    final cubit = AuthCubit(MockAuthService());

    final result = await cubit.signInWithEmail('user@example.com', 'sifre123');

    expect(result, isA<AuthActionSuccess>());
    // Durum emit ile degil, servisin stream'inden akar.
    await expectLater(
      cubit.stream.firstWhere((state) => state.isLoggedIn),
      completes,
    );
    expect(cubit.state.email, 'user@example.com');
    expect(cubit.state.providerId, 'password');
  });

  test('cikis oturumu temizler', () async {
    final cubit = AuthCubit(MockAuthService());
    await cubit.signInWithEmail('user@example.com', 'sifre123');
    await cubit.stream.firstWhere((state) => state.isLoggedIn);

    // Beklentiyi aksiyondan ONCE kur: `firstWhere` yalnizca abone olduktan
    // sonraki olaylari gorur, cikis emit'ini kacirirsak test asili kalir.
    final loggedOut = cubit.stream.firstWhere((state) => !state.isLoggedIn);
    await cubit.signOut();
    await loggedOut;

    expect(cubit.state.isLoggedIn, isFalse);
  });

  test('hata AuthActionFailure dondurur, state bozulmaz', () async {
    final cubit = AuthCubit(_FailingAuthService('wrong-password'));

    final result = await cubit.signInWithEmail('user@example.com', 'yanlis');

    expect(result, isA<AuthActionFailure>());
    expect(cubit.state.isLoggedIn, isFalse);
  });

  test('iptal basaridan ayrilir ve hata sayilmaz', () async {
    final cubit = AuthCubit(_FailingAuthService('canceled'));

    final result = await cubit.signInWithGoogle();

    expect(result, isA<AuthActionCanceled>());
    expect(result, isNot(isA<AuthActionFailure>()));
  });

  group('AuthState', () {
    test('displayName ad yoksa e-postanin kullanici kismina duser', () {
      const withName = AuthState(name: 'Ada Lovelace', email: 'a@b.com');
      const withoutName = AuthState(email: 'ada@example.com');
      const empty = AuthState();

      expect(withName.displayName, 'Ada Lovelace');
      expect(withoutName.displayName, 'ada');
      expect(empty.displayName, '');
    });

    test('sosyal saglayici sifre saglayicisi degildir', () {
      expect(
        const AuthState(providerId: 'password').isPasswordProvider,
        isTrue,
      );
      expect(const AuthState().isPasswordProvider, isTrue);
      expect(
        const AuthState(providerId: 'google.com').isPasswordProvider,
        isFalse,
      );
    });
  });
}
