import 'package:akillisletme/product/const/app_icon_sizes.dart';
import 'package:akillisletme/product/enum/text_field_type.dart';
import 'package:akillisletme/product/utils/validator/app_validator.dart';
import 'package:flutter/material.dart';

/// Projenin standart metin alani.
///
/// Klavye tipi, otomatik doldurma, girdi filtresi ve karakter siniri
/// [TextFieldType]'tan gelir; gorunum tema `inputDecorationTheme`'inden.
/// Cagri yeri yalnizca **ne** istedigini soyler:
///
/// ```dart
/// AppTextField(
///   controller: emailController,
///   label: LocaleKeys.auth_email.tr(),
///   type: TextFieldType.email,
///   validator: Validators.email,
/// )
/// ```
///
/// Sifre alaninda goster/gizle dugmesi otomatik eklenir.
class AppTextField extends StatefulWidget {
  const AppTextField({
    required this.controller,
    required this.label,
    super.key,
    this.type = TextFieldType.text,
    this.validator = Validators.optional,
    this.hint,
    this.helperText,
    this.prefixIcon,
    this.suffix,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.textInputAction = TextInputAction.next,
    this.maxLines,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
  });

  final TextEditingController controller;
  final String label;
  final TextFieldType type;
  final AppValidator validator;

  final String? hint;
  final String? helperText;
  final IconData? prefixIcon;

  /// Sag taraftaki ozel widget. Sifre alaninda goster/gizle dugmesi bunun
  /// yerine gecer.
  final Widget? suffix;

  final bool enabled;

  /// Salt okunur — deger baska bir yerden (sheet, tarih secici) geliyorsa.
  /// Klavye acilmaz ama [onTap] calisir.
  final bool readOnly;

  final bool autofocus;
  final TextInputAction textInputAction;

  /// Verilmezse cok satirli alanda 5, digerlerinde 1 satir.
  final int? maxLines;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _isObscured = widget.type.isObscured;

  void _toggleObscured() => setState(() => _isObscured = !_isObscured);

  @override
  Widget build(BuildContext context) {
    final type = widget.type;

    return TextFormField(
      controller: widget.controller,
      validator: widget.validator.validate,
      keyboardType: type.keyboardType,
      inputFormatters: type.formatters,
      autofillHints: widget.enabled ? type.autofillHints : null,
      maxLength: type.maxLength,
      maxLines: widget.maxLines ?? (type.isMultiline ? 5 : 1),
      minLines: type.isMultiline ? 3 : null,
      obscureText: _isObscured,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      textInputAction: type.isMultiline
          ? TextInputAction.newline
          : widget.textInputAction,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      onTap: widget.onTap,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        helperText: widget.helperText,
        prefixIcon: widget.prefixIcon == null
            ? null
            : Icon(widget.prefixIcon, size: AppIconSizes.m),
        suffixIcon: _buildSuffix(),
        // Sayac yalnizca sinira yaklasirken anlamli; surekli gostermek
        // formu gurultulu yapar.
        counterText: '',
      ),
    );
  }

  Widget? _buildSuffix() {
    if (!widget.type.isObscured) return widget.suffix;
    return IconButton(
      onPressed: _toggleObscured,
      icon: Icon(
        _isObscured ? Icons.visibility_off_rounded : Icons.visibility_rounded,
        size: AppIconSizes.m,
      ),
    );
  }
}
