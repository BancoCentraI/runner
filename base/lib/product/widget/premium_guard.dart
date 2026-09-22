import 'package:akillisletme/product/const/app_icon_sizes.dart';
import 'package:akillisletme/product/service/subscription/subscription_models.dart';
import 'package:akillisletme/product/state/subscription/subscription_cubit.dart';
import 'package:akillisletme/product/utils/extension/context_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Premium olmayan kullanici icin [child]'i kilitler.
///
/// [feature] premium'a acilmissa icerik oldugu gibi gosterilir. Degilse
/// soluklastirilir + kilit ikonu bindirilir; dokununca [onLockedTap] calisir.
///
/// **UX kurali:** alan tiklanabilir kalir. Kullaniciyi ozelligi gormekten
/// alikoymak yerine, kullanmaya kalktiginda paywall'a yonlendir — donusum
/// belirgin sekilde artar.
class PremiumGuard extends StatelessWidget {
  const PremiumGuard({
    required this.feature,
    required this.child,
    required this.onLockedTap,
    super.key,
  });

  final PremiumFeature feature;
  final Widget child;

  /// Kilitliyken dokunma davranisi — genellikle paywall'a yonlendirir.
  final VoidCallback onLockedTap;

  @override
  Widget build(BuildContext context) {
    final isPremium = context.select<SubscriptionCubit, bool>(
      (cubit) => cubit.isPremiumFor(feature),
    );
    if (isPremium) return child;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onLockedTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // IgnorePointer sart: alttaki butonlar hala tiklanabilir olsaydi
          // kullanici kilitli ozelligi yine de tetikleyebilirdi.
          Opacity(opacity: 0.4, child: IgnorePointer(child: child)),
          Icon(
            Icons.lock_rounded,
            size: AppIconSizes.s,
            color: context.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
