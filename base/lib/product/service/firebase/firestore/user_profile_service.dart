import 'dart:convert';

import 'package:akillisletme/product/cache/shared_operation/shared_cache.dart';
import 'package:akillisletme/product/cache/shared_operation/shared_keys.dart';
import 'package:akillisletme/product/service/firebase/auth/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

/// Kullanici profil dokumaninin sozlesmesi (`users/{uid}`).
///
/// Auth kimliginden bagimsiz bir katman: oturum acildiginda (e-posta / Google /
/// Apple) profil Firestore'a **upsert** edilir.
abstract interface class UserProfileService {
  /// [user]'i `users/{uid}` dokumanina yazar/gunceller (idempotent).
  Future<void> upsertFromAuth(AppUser user);

  /// Profili okur (dokuman yoksa `null`).
  Future<Map<String, dynamic>?> fetch(String uid);

  /// Duzenlenebilir alanlari yazar (merge — kimlik alanlarina dokunmaz).
  Future<void> updateDetails(String uid, Map<String, dynamic> fields);
}

/// Firebase kapaliyken kullanilan sessiz implementasyon.
final class NoopUserProfileService implements UserProfileService {
  const NoopUserProfileService();

  @override
  Future<void> upsertFromAuth(AppUser user) async {}

  @override
  Future<Map<String, dynamic>?> fetch(String uid) async => null;

  @override
  Future<void> updateDetails(String uid, Map<String, dynamic> fields) async {}
}

/// `cloud_firestore` kullanan uretim implementasyonu.
final class FirestoreUserProfileService implements UserProfileService {
  FirestoreUserProfileService({
    required SharedCache cache,
    FirebaseFirestore? firestore,
  }) : _cache = cache,
       _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  final SharedCache _cache;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  /// Profilin Firestore'daki halini belirleyen her sey + gun.
  ///
  /// Ayni parmak izi = yazacak yeni bir sey yok. Gun de icinde: `lastLoginAt`
  /// gunluk tazelensin ama her acilista degil.
  ///
  /// **Hash'leniyor:** degerin kendisi hic okunmuyor, yalniz esitligine
  /// bakiliyor — duz hali kullanicinin adini ve e-postasini
  /// SharedPreferences'a (cihazda duz dosya) yazardi. Hash ayni isi gorur,
  /// kisisel veriyi birakmaz.
  String _fingerprint(AppUser user) {
    final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    final raw = [
      user.uid,
      user.name,
      user.email,
      user.emailVerified,
      user.providerId,
      today,
    ].join('|');
    return sha256.convert(utf8.encode(raw)).toString();
  }

  @override
  Future<void> upsertFromAuth(AppUser user) async {
    // Degisen bir sey yoksa okuma da yazma da gereksiz. Bu kontrol olmadan her
    // acilista 1 okuma + 1 yazma (yazma ~3 kat pahali) olusur.
    final fingerprint = _fingerprint(user);
    if (_cache.getValue<String>(SharedKeys.profileSync) == fingerprint) return;

    final ref = _users.doc(user.uid);
    final snapshot = await ref.get();
    final now = FieldValue.serverTimestamp();

    await ref.set({
      'uid': user.uid,
      'email': user.email,
      'name': user.name,
      'emailVerified': user.emailVerified,
      'provider': user.providerId,
      'photoUrl': user.photoUrl,
      'updatedAt': now,
      'lastLoginAt': now,
      // Ilk yaratimda kalici; sonraki merge'lerde dokunulmaz.
      if (!snapshot.exists) 'createdAt': now,
    }, SetOptions(merge: true));

    // Yazma basariliysa isaretle: hata alirsak parmak izi yazilmaz ve bir
    // sonraki acilis yeniden dener.
    await _cache.setValue(SharedKeys.profileSync, fingerprint);
  }

  @override
  Future<Map<String, dynamic>?> fetch(String uid) async {
    final snapshot = await _users.doc(uid).get();
    return snapshot.data();
  }

  @override
  Future<void> updateDetails(String uid, Map<String, dynamic> fields) {
    return _users.doc(uid).set({
      ...fields,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
