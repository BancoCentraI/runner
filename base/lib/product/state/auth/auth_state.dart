part of 'auth_cubit.dart';

/// Uygulama oturum durumu.
///
/// Tek dogru kaynak [AuthService.authStateChanges] stream'idir; giris/cikis
/// nerede olursa olsun cubit bu durumu otomatik gunceller.
@freezed
abstract class AuthState with _$AuthState {
  const factory AuthState({
    @Default(false) bool isLoggedIn,
    String? uid,
    String? name,
    String? email,
    String? photoUrl,
    @Default(false) bool emailVerified,
    String? providerId,
  }) = _AuthState;

  /// Ozel getter tanimlayabilmek icin gereken private constructor.
  const AuthState._();

  /// Misafir (oturumsuz) durum.
  factory AuthState.guest() => const AuthState();

  /// Servis modelinden durum uretir.
  factory AuthState.fromUser(AppUser? user) => user == null
      ? const AuthState()
      : AuthState(
          isLoggedIn: true,
          uid: user.uid,
          name: user.name,
          email: user.email,
          photoUrl: user.photoUrl,
          emailVerified: user.emailVerified,
          providerId: user.providerId,
        );

  /// Profilde gosterilecek ad: ad yoksa e-postanin kullanici kismi.
  String get displayName {
    final trimmedName = name?.trim();
    if (trimmedName != null && trimmedName.isNotEmpty) return trimmedName;

    final mail = email;
    if (mail != null && mail.contains('@')) return mail.split('@').first;

    return '';
  }

  /// Sosyal saglayiciyla girenlerin sifresi yoktur — hesap silme akisi sifre
  /// yerine saglayiciyla yeniden dogrulama yapar.
  bool get isPasswordProvider => providerId == null || providerId == 'password';
}
