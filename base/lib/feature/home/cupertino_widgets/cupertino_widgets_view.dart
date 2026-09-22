import 'package:akillisletme/product/const/app_paddings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CupertinoWidgetsView extends StatefulWidget {
  const CupertinoWidgetsView({super.key});

  @override
  State<CupertinoWidgetsView> createState() => _CupertinoWidgetsViewState();
}

class _CupertinoWidgetsViewState extends State<CupertinoWidgetsView> {
  bool switchValue = false;
  double sliderValue = 0.5;
  int segmentedValue = 0;
  late final TextEditingController textController;
  late final ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    textController = TextEditingController();
    scrollController = ScrollController();
  }

  @override
  void dispose() {
    textController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Cupertino Widgets')),
      body: ListView(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(
          horizontal: AppPaddings.l,
          vertical: AppPaddings.s,
        ),
        children: [
          // ── Buttons ──
          const _SectionTitle('Buttons', icon: CupertinoIcons.hand_raised),
          Card(
            child: Padding(
              padding: AppPaddings.allL,
              child: Wrap(
                spacing: AppPaddings.s,
                runSpacing: AppPaddings.s,
                children: [
                  CupertinoButton(onPressed: () {}, child: const Text('Plain')),
                  CupertinoButton.filled(
                    onPressed: () {},
                    child: const Text('Filled'),
                  ),
                  CupertinoButton.tinted(
                    onPressed: () {},
                    child: const Text('Tinted'),
                  ),
                  const CupertinoButton(
                    onPressed: null,
                    child: Text('Disabled'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppPaddings.xxl),

          // ── Switch ──
          const _SectionTitle(
            'Switch',
            icon: CupertinoIcons.circle_lefthalf_fill,
          ),
          Card(
            child: Padding(
              padding: AppPaddings.allL,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Enable notifications', style: tt.bodyMedium),
                  CupertinoSwitch(
                    value: switchValue,
                    onChanged: (v) => setState(() => switchValue = v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppPaddings.xxl),

          // ── Slider ──
          const _SectionTitle(
            'Slider',
            icon: CupertinoIcons.slider_horizontal_3,
          ),
          Card(
            child: Padding(
              padding: AppPaddings.allL,
              child: Column(
                children: [
                  CupertinoSlider(
                    value: sliderValue,
                    onChanged: (v) => setState(() => sliderValue = v),
                  ),
                  Text('${(sliderValue * 100).round()}%', style: tt.bodyMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppPaddings.xxl),

          // ── Segmented Control ──
          const _SectionTitle(
            'Segmented Control',
            icon: CupertinoIcons.square_grid_3x2,
          ),
          Card(
            child: Padding(
              padding: AppPaddings.allL,
              child: CupertinoSlidingSegmentedControl<int>(
                groupValue: segmentedValue,
                onValueChanged: (v) => setState(() => segmentedValue = v ?? 0),
                children: const {
                  0: Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppPaddings.s),
                    child: Text('Day'),
                  ),
                  1: Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppPaddings.s),
                    child: Text('Week'),
                  ),
                  2: Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppPaddings.s),
                    child: Text('Month'),
                  ),
                },
              ),
            ),
          ),
          const SizedBox(height: AppPaddings.xxl),

          // ── Text Field ──
          const _SectionTitle('Text Field', icon: CupertinoIcons.textformat),
          Card(
            child: Padding(
              padding: AppPaddings.allL,
              child: Column(
                spacing: AppPaddings.l,
                children: [
                  CupertinoTextField(
                    controller: textController,
                    placeholder: 'Enter your username',
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: AppPaddings.s),
                      child: Icon(CupertinoIcons.person, size: 20),
                    ),
                  ),
                  const CupertinoTextField(
                    obscureText: true,
                    placeholder: 'Enter your password',
                    prefix: Padding(
                      padding: EdgeInsets.only(left: AppPaddings.s),
                      child: Icon(CupertinoIcons.lock, size: 20),
                    ),
                  ),
                  const CupertinoTextField(
                    maxLines: 3,
                    placeholder: 'Tell us about yourself...',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppPaddings.xxl),

          // ── Activity Indicator ──
          const _SectionTitle(
            'Activity Indicator',
            icon: CupertinoIcons.circle_grid_hex,
          ),
          Card(
            child: Padding(
              padding: AppPaddings.allL,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const CupertinoActivityIndicator(),
                  const CupertinoActivityIndicator(radius: 20),
                  CupertinoActivityIndicator(
                    color: CupertinoColors.activeBlue.resolveFrom(context),
                    radius: 16,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppPaddings.xxl),

          // ── Dialogs & Sheets ──
          const _SectionTitle(
            'Dialogs & Sheets',
            icon: CupertinoIcons.chat_bubble,
          ),
          Card(
            child: Padding(
              padding: AppPaddings.allL,
              child: Wrap(
                spacing: AppPaddings.s,
                runSpacing: AppPaddings.s,
                children: [
                  CupertinoButton.tinted(
                    onPressed: () => showCupertinoDialog<void>(
                      context: context,
                      builder: (_) => CupertinoAlertDialog(
                        title: const Text('Alert'),
                        content: const Text(
                          'This is a Cupertino alert dialog.',
                        ),
                        actions: [
                          CupertinoDialogAction(
                            isDestructiveAction: true,
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          CupertinoDialogAction(
                            isDefaultAction: true,
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    ),
                    child: const Text('Alert Dialog'),
                  ),
                  CupertinoButton.tinted(
                    onPressed: () => showCupertinoModalPopup<void>(
                      context: context,
                      builder: (_) => CupertinoActionSheet(
                        title: const Text('Choose an option'),
                        message: const Text('Select the action to perform'),
                        actions: [
                          CupertinoActionSheetAction(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Option 1'),
                          ),
                          CupertinoActionSheetAction(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Option 2'),
                          ),
                          CupertinoActionSheetAction(
                            isDestructiveAction: true,
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Delete'),
                          ),
                        ],
                        cancelButton: CupertinoActionSheetAction(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                    ),
                    child: const Text('Action Sheet'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppPaddings.xxl),

          // ── Date Picker ──
          const _SectionTitle('Date Picker', icon: CupertinoIcons.calendar),
          Card(
            child: SizedBox(
              height: 200,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: DateTime.now(),
                onDateTimeChanged: (_) {},
              ),
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppPaddings.s,
        top: AppPaddings.xs,
      ),
      child: Row(
        spacing: AppPaddings.s,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
