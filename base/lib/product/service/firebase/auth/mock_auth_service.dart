import 'dart:async';

import 'package:akillisletme/product/const/app_durations.dart';
import 'package:akillisletme/product/service/firebase/auth/auth_service.dart';

/// Firebase kurulmadan once (ve testlerde) kullanilan bellek-ici [AuthService].
///
/// Gercek ag yok: kisa bir gecikmeyle basari taklit eder ve oturumu
/// `authStateChanges()` stream'inden yayinlar — arayuz (`AuthCubit`, ekranlar)
/// `FirebaseAuthService`'le **birebir ayni** sozlesmeyi gorur. Boylece template
/// klonlandigi anda giris akisi calisir durumda goruntulenebilir.
///
/// Firebase kurulunca `AppConfig.firebaseEnabled = true` yapmak yeterlidir;
/// locator otomatik olarak gercek servise gecer.
///
/// Sinirlar (bilincli): sifre dogrulanmaz, e-posta gercekten gonderilmez,
/// oturum uygulama kapaninca kaybolur.
final class MockAuthService implements AuthService {
  final StreamController<AppUser?> _controller =
      StreamController<AppUser?>.broadcast();

  AppUser? _current;

  static const Duration _latency = AppDurations.long;

  @override
  Stream<AppUser?> authStateChanges() async* {
    // Once mevcut durumu ver: dinlemeye gec baslayan (ör. router) da oturumu
    // gorur, ilk degisimi beklemek zorunda kalmaz.
    yield _current;
    yield* _controller.stream;
  }

  @override
  AppUser? get currentUser => _current;

  @override
  Future<void> signInWithEmail(String email, String password) async {
    await Future<void>.delayed(_latency);
    _emit(
      AppUser(
        uid: _uidFor(email),
        email: email.trim(),
        emailVerified: true,
        providerId: 'password',
      ),
    );
  }

  @override
  Future<void> registerWithEmail(
    String email,
    String password, {
    String? name,
  }) async {
    await Future<void>.delayed(_latency);
    _emit(
      AppUser(
        uid: _uidFor(email),
        email: email.trim(),
        name: name,
        providerId: 'password',
      ),
    );
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await Future<void>.delayed(_latency);
  }

  @override
  Future<void> signInWithGoogle() async {
    await Future<void>.delayed(_latency);
    _emit(
      const AppUser(
        uid: 'mock-google',
        email: 'google.user@example.com',
        name: 'Google User',
        emailVerified: true,
        providerId: 'google.com',
      ),
    );
  }

  @override
  Future<void> signInWithApple() async {
    await Future<void>.delayed(_latency);
    _emit(
      const AppUser(
        uid: 'mock-apple',
        email: 'apple.user@example.com',
        name: 'Apple User',
        emailVerified: true,
        providerId: 'apple.com',
      ),
    );
  }

  @override
  Future<void> updateDisplayName(String name) async {
    _emitCopy(name: name.trim());
  }

  @override
  Future<void> updatePhotoUrl(String? url) async {
    _emitCopy(photoUrl: url, clearPhoto: url == null);
  }

  @override
  Future<void> sendEmailVerification() async {
    await Future<void>.delayed(_latency);
  }

  @override
  Future<bool> reloadEmailVerified() async => _current?.emailVerified ?? false;

  @override
  Future<void> reauthenticateWithPassword(String password) async {
    await Future<void>.delayed(_latency);
  }

  @override
  Future<void> reauthenticateWithGoogle() async {
    await Future<void>.delayed(_latency);
  }

  @override
  Future<void> reauthenticateWithApple() async {
    await Future<void>.delayed(_latency);
  }

  @override
  Future<void> deleteAccount() async {
    await Future<void>.delayed(_latency);
    _emit(null);
  }

  @override
  Future<void> signOut() async => _emit(null);

  void _emitCopy({String? name, String? photoUrl, bool clearPhoto = false}) {
    final current = _current;
    if (current == null) return;
    _emit(
      AppUser(
        uid: current.uid,
        email: current.email,
        name: name ?? current.name,
        emailVerified: current.emailVerified,
        photoUrl: clearPhoto ? null : (photoUrl ?? current.photoUrl),
        providerId: current.providerId,
      ),
    );
  }

  void _emit(AppUser? user) {
    _current = user;
    if (!_controller.isClosed) _controller.add(user);
  }

  String _uidFor(String email) => 'mock-${email.trim().toLowerCase()}';
}
