import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

/// Kullaniciya gosterilebilir dosya yukleme hatasi.
final class StorageException implements Exception {
  const StorageException(this.code);

  /// Dilden bagimsiz kod — UI `LocaleKeys` ile cevirir.
  final String code;

  @override
  String toString() => 'StorageException($code)';
}

/// Dosya depolamanin sozlesmesi (Firebase Storage).
abstract interface class StorageService {
  /// [file]'i [path] yoluna yukler ve indirme URL'ini doner.
  ///
  /// [path] ornegi: `users/{uid}/avatar.jpg`. Ayni yola tekrar yuklemek eskiyi
  /// ezer — URL degismedigi icin `CachedNetworkImage` bayat kopyayi gosterebilir;
  /// gorselin degismesi gerekiyorsa yola bir surum eki koy.
  Future<String> upload(String path, File file, {String? contentType});

  /// Yoldaki dosyayi siler. Dosya yoksa sessizce doner.
  Future<void> delete(String path);
}

/// Firebase kapaliyken kullanilan sessiz implementasyon.
final class NoopStorageService implements StorageService {
  const NoopStorageService();

  @override
  Future<String> upload(String path, File file, {String? contentType}) async {
    throw const StorageException('unavailable');
  }

  @override
  Future<void> delete(String path) async {}
}

/// `firebase_storage` kullanan uretim implementasyonu.
final class FirebaseStorageService implements StorageService {
  FirebaseStorageService([FirebaseStorage? storage])
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  @override
  Future<String> upload(String path, File file, {String? contentType}) async {
    try {
      final ref = _storage.ref(path);
      // contentType verilmezse Storage `application/octet-stream` yazar ve
      // tarayicida gorsel goruntulenmek yerine indirilir.
      await ref.putFile(file, SettableMetadata(contentType: contentType));
      return await ref.getDownloadURL();
    } on FirebaseException catch (error) {
      throw StorageException(error.code);
    }
  }

  @override
  Future<void> delete(String path) async {
    try {
      await _storage.ref(path).delete();
    } on FirebaseException catch (error) {
      // Zaten yoksa hata degil.
      if (error.code == 'object-not-found') return;
      throw StorageException(error.code);
    }
  }
}
