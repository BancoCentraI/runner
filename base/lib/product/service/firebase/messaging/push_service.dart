import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Arka planda/kapaliyken gelen mesaji isleyen ust duzey handler.
///
/// **Ayri bir isolate'te calisir:** [Firebase.initializeApp] tekrar cagrilmali
/// ve ana uygulamanin state'ine (cubit/context/locator) erisilemez. Agir is
/// yapma — sadece hafif isleme veya yerel kayit.
///
/// `@pragma('vm:entry-point')` release build'de tree-shaking'in bu fonksiyonu
/// silmesini engeller; olmadan arka plan bildirimleri sessizce calismaz.
@pragma('vm:entry-point')
Future<void> pushBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// Push bildirimlerinin (FCM) sozlesmesi.
abstract interface class PushService {
  /// Tum cihazlarin abone oldugu yayin konusu — backend duyuruyu tek mesajla
  /// buraya gonderir, token toplamak zorunda kalmaz.
  static const String broadcastTopic = 'all';

  /// Izin ister, dinleyicileri ve foreground bildirim kanalini kurar.
  Future<void> init();

  /// Bildirim izni ister; verildiyse `true`.
  Future<bool> requestPermission();

  /// Bu cihazin FCM token'i (hedefli gonderim icin backend'de saklanir).
  Future<String?> getToken();

  /// Token yenilendiginde tetiklenir — backend'deki kaydi guncelle.
  Stream<String> get onTokenRefresh;

  /// Bildirime dokunularak uygulama acildiginda tasinan veri (deep link).
  Stream<Map<String, dynamic>> get onNotificationTap;

  /// Uygulama kapaliyken bildirimle acildiysa ilk mesajin verisi.
  ///
  /// `onNotificationTap` bu durumu **yakalamaz** — uygulama daha baslamamisti.
  /// Acilista bir kez sorulmazsa deep link kaybolur.
  Future<Map<String, dynamic>?> getInitialData();

  Future<void> subscribeToTopic(String topic);

  Future<void> unsubscribeFromTopic(String topic);

  /// Token'i siler. **Cikista cagrilmali**: aksi halde ayni cihazi kullanan bir
  /// sonraki kullaniciya oncekinin bildirimleri duser.
  Future<void> deleteToken();
}

/// Firebase kapaliyken kullanilan sessiz implementasyon.
final class NoopPushService implements PushService {
  const NoopPushService();

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<String?> getToken() async => null;

  @override
  Stream<String> get onTokenRefresh => const Stream<String>.empty();

  @override
  Stream<Map<String, dynamic>> get onNotificationTap =>
      const Stream<Map<String, dynamic>>.empty();

  @override
  Future<Map<String, dynamic>?> getInitialData() async => null;

  @override
  Future<void> subscribeToTopic(String topic) async {}

  @override
  Future<void> unsubscribeFromTopic(String topic) async {}

  @override
  Future<void> deleteToken() async {}
}

/// `firebase_messaging` + `flutter_local_notifications` kullanan uretim
/// implementasyonu.
///
/// FCM, uygulama **onde**yken bildirimi kendisi gostermez — yerel bildirimle
/// biz gosteririz. Bu adim atlanirsa kullanici uygulama acikken hicbir bildirim
/// gormez ve sorun fark edilmesi zor olur.
final class FirebasePushService implements PushService {
  FirebasePushService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _local = localNotifications ?? FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _local;

  /// Android bildirim kanali. Kanal **kurulmazsa** Android 8+ bildirimleri
  /// sessizce dusurur. `id` degistirilirse eski kanal ayarlari kullanicida
  /// kalir — yeniden adlandirmak yerine yeni id vermek gerekir.
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'app_default',
    'Genel Bildirimler',
    description: 'Duyurular ve uygulama bildirimleri',
    importance: Importance.high,
  );

  @override
  Future<void> init() async {
    await requestPermission();
    await _configureLocalNotifications();
    FirebaseMessaging.onBackgroundMessage(pushBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
  }

  @override
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    final status = settings.authorizationStatus;
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> getToken() => _messaging.getToken();

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  Stream<Map<String, dynamic>> get onNotificationTap =>
      FirebaseMessaging.onMessageOpenedApp.map((message) => message.data);

  @override
  Future<Map<String, dynamic>?> getInitialData() async {
    final message = await _messaging.getInitialMessage();
    return message?.data;
  }

  @override
  Future<void> subscribeToTopic(String topic) =>
      _messaging.subscribeToTopic(topic);

  @override
  Future<void> unsubscribeFromTopic(String topic) =>
      _messaging.unsubscribeFromTopic(topic);

  @override
  Future<void> deleteToken() => _messaging.deleteToken();

  Future<void> _configureLocalNotifications() async {
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _local.initialize(settings: initSettings);
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
  }

  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _local.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}
