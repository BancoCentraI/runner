import 'package:akillisletme/product/init/language/locale_keys.g.dart';
import 'package:akillisletme/product/theme/state/theme_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Serbest seed renk secici (bottom sheet).
///
/// Harici paket kullanmadan HSV slider'lariyla (ton + doygunluk + parlaklik)
/// bir renk uretir; `fromSeed` bu renkten tam M3 paletini olusturur.
class CustomColorSheet extends StatefulWidget {
  const CustomColorSheet({required this.initialColor, super.key});

  final Color initialColor;

  static Future<void> show(BuildContext context, Color initialColor) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => BlocProvider.value(
        value: context.read<ThemeCubit>(),
        child: CustomColorSheet(initialColor: initialColor),
      ),
    );
  }

  @override
  State<CustomColorSheet> createState() => _CustomColorSheetState();
}

class _CustomColorSheetState extends State<CustomColorSheet> {
  late HSVColor _hsv;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initialColor);
  }

  Color get _color => _hsv.toColor();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            LocaleKeys.theme_pickColor.tr(),
            style: textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Onizleme + uretilen palet
          Container(
            height: 72,
            decoration: BoxDecoration(
              color: _color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _ColorSlider(
            label: LocaleKeys.theme_hue.tr(),
            value: _hsv.hue,
            max: 360,
            activeColor: HSVColor.fromAHSV(1, _hsv.hue, 1, 1).toColor(),
            gradientColors: const [
              Color(0xFFFF0000),
              Color(0xFFFFFF00),
              Color(0xFF00FF00),
              Color(0xFF00FFFF),
              Color(0xFF0000FF),
              Color(0xFFFF00FF),
              Color(0xFFFF0000),
            ],
            onChanged: (v) => setState(() => _hsv = _hsv.withHue(v)),
          ),
          _ColorSlider(
            label: LocaleKeys.theme_saturation.tr(),
            value: _hsv.saturation,
            activeColor: _color,
            gradientColors: [
              HSVColor.fromAHSV(1, _hsv.hue, 0, 1).toColor(),
              HSVColor.fromAHSV(1, _hsv.hue, 1, 1).toColor(),
            ],
            onChanged: (v) => setState(() => _hsv = _hsv.withSaturation(v)),
          ),
          _ColorSlider(
            label: LocaleKeys.theme_brightnessLevel.tr(),
            value: _hsv.value,
            activeColor: _color,
            gradientColors: [
              Colors.black,
              HSVColor.fromAHSV(1, _hsv.hue, _hsv.saturation, 1).toColor(),
            ],
            onChanged: (v) => setState(() => _hsv = _hsv.withValue(v)),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              context.read<ThemeCubit>().setCustomSeed(_color);
              Navigator.pop(context);
            },
            child: Text(LocaleKeys.theme_apply.tr()),
          ),
        ],
      ),
    );
  }
}

class _ColorSlider extends StatelessWidget {
  const _ColorSlider({
    required this.label,
    required this.value,
    required this.activeColor,
    required this.gradientColors,
    required this.onChanged,
    this.max = 1,
  });

  final String label;
  final double value;
  final double max;
  final Color activeColor;
  final List<Color> gradientColors;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.labelMedium),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: 12,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradientColors),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.transparent,
                inactiveTrackColor: Colors.transparent,
                thumbColor: activeColor,
                overlayColor: activeColor.withValues(alpha: 0.2),
                trackHeight: 12,
              ),
              child: Slider(value: value, max: max, onChanged: onChanged),
            ),
          ],
        ),
      ],
    );
  }
}
