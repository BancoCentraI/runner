import 'package:akillisletme/product/const/regex_types.dart';
import 'package:akillisletme/product/init/language/locale_keys.g.dart';
import 'package:akillisletme/product/utils/extension/string_extension.dart';
import 'package:easy_localization/easy_localization.dart';

/// Form alani dogrulayicilarinin ortak sozlesmesi.
///
/// Hata metni **dogrulayicinin icinde** uretilir ve daima yerellestirilmistir;
/// cagri yeri metin yazmaz. Bir alanin kurali degistiginde tek yer degisir.
///
/// ```dart
/// AppTextField(
///   controller: emailController,
///   label: LocaleKeys.settings_contactUs.tr(),
///   validator: Validators.email,
/// )
/// ```
abstract class AppValidator {
  const AppValidator();

  /// Gecerliyse `null`, degilse gosterilecek hata metni doner.
  /// Imza `TextFormField.validator` ile uyumludur: `validator: v.validate`.
  String? validate(String? value);

  /// Hata metnine ihtiyac duymadan gecerlilik sorgusu — "kaydet" butonunu
  /// canli olarak aktif/pasif yapmak icin.
  bool isValid(String? value) => validate(value) == null;
}

/// Bos birakilamaz.
final class RequiredValidator extends AppValidator {
  const RequiredValidator();

  @override
  String? validate(String? value) =>
      value.isNullOrBlank ? LocaleKeys.validation_required.tr() : null;
}

/// Hicbir kural uygulamaz — opsiyonel alanlarda niyeti acik kilar.
final class OptionalValidator extends AppValidator {
  const OptionalValidator();

  @override
  String? validate(String? value) => null;
}

final class EmailValidator extends AppValidator {
  const EmailValidator({this.isOptional = false});

  final bool isOptional;

  @override
  String? validate(String? value) {
    if (value.isNullOrBlank) {
      return isOptional ? null : LocaleKeys.validation_required.tr();
    }
    return value!.isValidEmail ? null : LocaleKeys.validation_email.tr();
  }
}

final class PhoneValidator extends AppValidator {
  const PhoneValidator({this.isOptional = false});

  final bool isOptional;

  @override
  String? validate(String? value) {
    if (value.isNullOrBlank) {
      return isOptional ? null : LocaleKeys.validation_required.tr();
    }
    return value!.isValidPhone ? null : LocaleKeys.validation_phone.tr();
  }
}

/// En az 8 karakter, 1 harf + 1 rakam ([RegexTypes.password]).
final class PasswordValidator extends AppValidator {
  const PasswordValidator();

  @override
  String? validate(String? value) {
    if (value.isNullOrBlank) return LocaleKeys.validation_required.tr();
    return RegexTypes.password.hasMatch(value!)
        ? null
        : LocaleKeys.validation_password.tr();
  }
}

/// Ad + soyad (Turkce karakter destekli).
final class FullNameValidator extends AppValidator {
  const FullNameValidator();

  @override
  String? validate(String? value) {
    if (value.isNullOrBlank) return LocaleKeys.validation_required.tr();
    return RegexTypes.fullName.hasMatch(value!.trim())
        ? null
        : LocaleKeys.validation_fullName.tr();
  }
}

final class UrlValidator extends AppValidator {
  const UrlValidator({this.isOptional = false});

  final bool isOptional;

  @override
  String? validate(String? value) {
    if (value.isNullOrBlank) {
      return isOptional ? null : LocaleKeys.validation_required.tr();
    }
    return RegexTypes.url.hasMatch(value!.trim())
        ? null
        : LocaleKeys.validation_url.tr();
  }
}

final class MinLengthValidator extends AppValidator {
  const MinLengthValidator(this.min);

  final int min;

  @override
  String? validate(String? value) {
    if (value.isNullOrBlank) return LocaleKeys.validation_required.tr();
    return value!.trim().length >= min
        ? null
        : LocaleKeys.validation_minLength.tr(args: ['$min']);
  }
}

final class MaxLengthValidator extends AppValidator {
  const MaxLengthValidator(this.max);

  final int max;

  @override
  String? validate(String? value) {
    if (value == null) return null;
    return value.trim().length <= max
        ? null
        : LocaleKeys.validation_maxLength.tr(args: ['$max']);
  }
}

/// Tam sayi alani — opsiyonel alt/ust sinirla.
final class NumericRangeValidator extends AppValidator {
  const NumericRangeValidator({this.min, this.max, this.isOptional = false});

  final int? min;
  final int? max;
  final bool isOptional;

  @override
  String? validate(String? value) {
    if (value.isNullOrBlank) {
      return isOptional ? null : LocaleKeys.validation_required.tr();
    }

    final number = int.tryParse(value!.trim());
    if (number == null) return LocaleKeys.validation_numeric.tr();

    final belowMin = min != null && number < min!;
    final aboveMax = max != null && number > max!;
    if (!belowMin && !aboveMax) return null;

    if (min != null && max != null) {
      return LocaleKeys.validation_numericRange.tr(args: ['$min', '$max']);
    }
    if (min != null) {
      return LocaleKeys.validation_numericMin.tr(args: ['$min']);
    }
    return LocaleKeys.validation_numericMax.tr(args: ['$max']);
  }
}

/// Baska bir alanla ayni olmali — sifre tekrari icin.
///
/// Karsilastirilacak deger cagri aninda okunur; bu yuzden controller'in
/// guncel degerini donduren bir fonksiyon alir.
final class MatchValidator extends AppValidator {
  const MatchValidator(this.other, {this.message});

  final String? Function() other;

  /// Varsayilan "Sifreler eslesmiyor" disinda bir metin gerekiyorsa.
  final String? message;

  @override
  String? validate(String? value) {
    if (value.isNullOrBlank) return LocaleKeys.validation_required.tr();
    return value == other()
        ? null
        : (message ?? LocaleKeys.validation_passwordMatch.tr());
  }
}

/// Birden fazla kurali sirayla uygular; ilk hatada durur.
final class CompositeValidator extends AppValidator {
  const CompositeValidator(this.validators);

  final List<AppValidator> validators;

  @override
  String? validate(String? value) {
    for (final validator in validators) {
      final error = validator.validate(value);
      if (error != null) return error;
    }
    return null;
  }
}

/// Hazir dogrulayicilara kisa erisim.
///
/// ```dart
/// validator: Validators.email
/// validator: Validators.all([Validators.required, Validators.minLength(3)])
/// validator: Validators.match(() => passwordController.text)
/// ```
abstract final class Validators {
  const Validators._();

  static const AppValidator required = RequiredValidator();
  static const AppValidator optional = OptionalValidator();
  static const AppValidator email = EmailValidator();
  static const AppValidator phone = PhoneValidator();
  static const AppValidator password = PasswordValidator();
  static const AppValidator fullName = FullNameValidator();
  static const AppValidator url = UrlValidator();

  static AppValidator optionalEmail() => const EmailValidator(isOptional: true);
  static AppValidator optionalPhone() => const PhoneValidator(isOptional: true);

  static AppValidator minLength(int min) => MinLengthValidator(min);
  static AppValidator maxLength(int max) => MaxLengthValidator(max);

  static AppValidator numericRange({
    int? min,
    int? max,
    bool isOptional = false,
  }) => NumericRangeValidator(min: min, max: max, isOptional: isOptional);

  static AppValidator match(String? Function() other, {String? message}) =>
      MatchValidator(other, message: message);

  static AppValidator all(List<AppValidator> validators) =>
      CompositeValidator(validators);
}
