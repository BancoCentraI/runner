import 'dart:io';

import 'package:akillisletme/product/const/app_string.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// url_launcher işlemlerini merkezi olarak yöneten servis.
final class UrlLauncherService {
  UrlLauncherService._();
  static final UrlLauncherService instance = UrlLauncherService._();

  /// Verilen [url]'i in-app browser'da açar.
  Future<void> openInApp(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);
  }

  /// Verilen [url]'i harici uygulamada açar (ör. Instagram, Play Store).
  Future<void> openExternal(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  /// Platforma göre App Store veya Play Store'u açar.
  Future<void> openStore() async {
    final url = Platform.isIOS ? AppString.appStoreUrl : AppString.playStoreUrl;
    if (url.isEmpty) {
      debugPrint('UrlLauncherService.openStore -> Store URL tanımlanmamış');
      return;
    }
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  /// Mail uygulamasını açar.
  Future<void> sendEmail({
    required String to,
    String subject = '',
    String body = '',
  }) async {
    final params = <String, String>{
      if (subject.isNotEmpty) 'subject': subject,
      if (body.isNotEmpty) 'body': body,
    };

    final uri = Uri(
      scheme: 'mailto',
      path: to,
      queryParameters: params.isNotEmpty ? params : null,
    );

    debugPrint('UrlLauncherService.sendEmail -> $uri');
    await launchUrl(uri);
  }
}
