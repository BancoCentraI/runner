import 'package:akillisletme/product/const/method_channels.dart';
import 'package:akillisletme/product/init/language/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OverlayTile extends StatefulWidget {
  const OverlayTile({super.key});

  @override
  State<OverlayTile> createState() => _OverlayTileState();
}

class _OverlayTileState extends State<OverlayTile> {
  static const _channel = MethodChannel(MethodChannels.overlayPermission);

  bool _enabled = true;

  @override
  void initState() {
    super.initState();
    _loadEnabled();
  }

  Future<void> _loadEnabled() async {
    final value = await _channel.invokeMethod<bool>('isEnabled') ?? true;
    if (mounted) setState(() => _enabled = value);
  }

  Future<void> _setEnabled(bool value) async {
    setState(() => _enabled = value);
    await _channel.invokeMethod<void>('setEnabled', {'enabled': value});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SwitchListTile(
      secondary: Icon(
        Icons.picture_in_picture_alt_rounded,
        color: cs.onSurfaceVariant,
      ),
      title: Text(LocaleKeys.settings_overlayWindow.tr()),
      subtitle: Text(LocaleKeys.settings_overlayWindowDesc.tr()),
      value: _enabled,
      onChanged: _setEnabled,
    );
  }
}
