import 'package:permission_handler/permission_handler.dart';

/// İzin işlemlerini merkezi olarak yöneten servis.
final class PermissionService {
  PermissionService._();
  static final PermissionService instance = PermissionService._();

  /// İzin durumunu kontrol eder.
  Future<PermissionStatus> check(Permission permission) {
    return permission.status;
  }

  /// İzin ister. Zaten verilmişse tekrar sormaz.
  Future<PermissionStatus> request(Permission permission) async {
    final status = await permission.status;
    if (status.isGranted) return status;
    return permission.request();
  }

  /// İznin verilip verilmediğini bool olarak döner.
  Future<bool> isGranted(Permission permission) {
    return permission.isGranted;
  }

  /// Kullanıcı "bir daha sorma" seçtiyse ayarlara yönlendirir.
  Future<bool> openSettings() {
    return openAppSettings();
  }
}
