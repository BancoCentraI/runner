import 'package:akillisletme/feature/home/material_widgets/material_widgets_view_mode.dart';
import 'package:akillisletme/product/const/app_paddings.dart';
import 'package:flutter/material.dart';

class MaterialWidgetsView extends StatefulWidget {
  const MaterialWidgetsView({super.key});

  @override
  State<MaterialWidgetsView> createState() => _MaterialWidgetsViewState();
}

class _MaterialWidgetsViewState extends MaterialWidgetsViewMode {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Material Widgets')),
      body: ListView(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(
          horizontal: AppPaddings.l,
          vertical: AppPaddings.s,
        ),
        children: [
          // ── Typography ──
          const _SectionTitle('Typography', icon: Icons.text_fields),
          Card(
            child: Padding(
              padding: AppPaddings.allL,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppPaddings.xs,
                children: [
                  Text('headlineSmall (24)', style: tt.headlineSmall),
                  Text('titleLarge (22)', style: tt.titleLarge),
                  Text('titleMedium (16)', style: tt.titleMedium),
                  Text('titleSmall (14)', style: tt.titleSmall),
                  Text('bodyLarge (16)', style: tt.bodyLarge),
                  Text('bodyMedium (14)', style: tt.bodyMedium),
                  Text('bodySmall (12)', style: tt.bodySmall),
                  Text('labelLarge', style: tt.labelLarge),
                  Text('labelMedium', style: tt.labelMedium),
                  Text('labelSmall', style: tt.labelSmall),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppPaddings.xxl),

          // ── Material Buttons ──
          const _SectionTitle('Material Buttons', icon: Icons.touch_app),
          Card(
            child: Padding(
              padding: AppPaddings.allL,
              child: Wrap(
                spacing: AppPaddings.s,
                runSpacing: AppPaddings.s,
                children: [
                  FilledButton(onPressed: () {}, child: const Text('Filled')),
                  FilledButton.tonal(
                    onPressed: () {},
                    child: const Text('Filled Tonal'),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Elevated'),
                  ),
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text('Outlined'),
                  ),
                  TextButton(onPressed: () {}, child: const Text('Text')),
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add),
                    label: const Text('Icon'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppPaddings.xxl),

          // ── Icon Buttons ──
          const _SectionTitle('Icon Buttons', icon: Icons.radio_button_checked),
          Card(
            child: Padding(
              padding: AppPaddings.allL,
              child: Row(
                spacing: AppPaddings.s,
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.favorite),
                  ),
                  IconButton.filled(
                    onPressed: () {},
                    icon: const Icon(Icons.favorite),
                  ),
                  IconButton.filledTonal(
                    onPressed: () {},
                    icon: const Icon(Icons.favorite),
                  ),
                  IconButton.outlined(
                    onPressed: () {},
                    icon: const Icon(Icons.favorite),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppPaddings.xxl),

          // ── Chips ──
          const _SectionTitle('Chips', icon: Icons.label),
          Card(
            child: Padding(
              padding: AppPaddings.allL,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppPaddings.m,
                children: [
                  Text('Action Chips', style: tt.labelMedium),
                  Wrap(
                    spacing: AppPaddings.s,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.calendar_today, size: 16),
                        label: const Text('Today'),
                        onPressed: () {},
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.alarm, size: 16),
                        label: const Text('Reminder'),
                        onPressed: () {},
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.share, size: 16),
                        label: const Text('Share'),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const Divider(),
                  Text('Filter Chips', style: tt.labelMedium),
                  Wrap(
                    spacing: AppPaddings.s,
                    children: List.generate(4, (i) {
                      final labels = ['All', 'Active', 'Done', 'Archived'];
                      return FilterChip(
                        label: Text(labels[i]),
                        selected: selectedFilters.contains(i),
                        onSelected: (v) => setState(() {
                          if (v) {
                            selectedFilters.add(i);
                          } else {
                            selectedFilters.remove(i);
                          }
                        }),
                      );
                    }),
                  ),
                  const Divider(),
                  Text('Choice Chips', style: tt.labelMedium),
                  Wrap(
                    spacing: AppPaddings.s,
                    children: List.generate(3, (i) {
                      final labels = ['Small', 'Medium', 'Large'];
                      return ChoiceChip(
                        label: Text(labels[i]),
                        selected: choiceIndex == i,
                        onSelected: (_) => setState(() => choiceIndex = i),
                      );
                    }),
                  ),
                  const Divider(),
                  Text('Input Chips', style: tt.labelMedium),
                  Wrap(
                    spacing: AppPaddings.s,
                    children: [
                      InputChip(
                        avatar: CircleAvatar(
                          backgroundColor: cs.primary,
                          child: Text(
                            'A',
                            style: tt.labelSmall?.copyWith(color: cs.onPrimary),
                          ),
                        ),
                        label: const Text('Flutter'),
                        onDeleted: () {},
                      ),
                      InputChip(
                        avatar: CircleAvatar(
                          backgroundColor: cs.secondary,
                          child: Text(
                            'B',
                            style: tt.labelSmall?.copyWith(
                              color: cs.onSecondary,
                            ),
                          ),
                        ),
                        label: const Text('Dart'),
                        onDeleted: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppPaddings.xxl),

          // ── SegmentedButton ──
          const _SectionTitle('Segmented Button', icon: Icons.view_week),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'day', label: Text('Day')),
              ButtonSegment(value: 'week', label: Text('Week')),
              ButtonSegment(value: 'month', label: Text('Month')),
            ],
            selected: segmentSelection,
            onSelectionChanged: (v) => setState(() => segmentSelection = v),
          ),
          const SizedBox(height: AppPaddings.xxl),

          // ── Switch & Checkbox ──
          const _SectionTitle('Toggles', icon: Icons.toggle_on),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Enable notifications'),
                  subtitle: const Text('Receive push notifications'),
                  secondary: const Icon(Icons.notifications),
                  value: switchValue,
                  onChanged: (v) => setState(() => switchValue = v),
                ),
                const Divider(height: 1),
                CheckboxListTile(
                  title: const Text('Accept terms'),
                  subtitle: const Text('Terms and conditions'),
                  value: checkboxValue,
                  onChanged: (v) => setState(() => checkboxValue = v ?? false),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppPaddings.xxl),

          // ── Radio ──
          const _SectionTitle(
            'Radio Buttons',
            icon: Icons.radio_button_checked,
          ),
          Card(
            child: RadioGroup<int>(
              groupValue: radioValue,
              onChanged: (v) => setState(() => radioValue = v ?? 0),
              child: Column(
                children: List.generate(3, (i) {
                  const labels = [
                    'Option Alpha',
                    'Option Beta',
                    'Option Gamma',
                  ];
                  return RadioListTile<int>(
                    title: Text(labels[i]),
                    value: i,
                    toggleable: true,
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: AppPaddings.xxl),

          // ── Slider ──
          const _SectionTitle('Slider', icon: Icons.tune),
          Card(
            child: Padding(
              padding: AppPaddings.allL,
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.volume_down),
                      Expanded(
                        child: Slider(
                          value: sliderValue,
                          onChanged: (v) => setState(() => sliderValue = v),
                        ),
                      ),
                      const Icon(Icons.volume_up),
                    ],
                  ),
                  Text('${(sliderValue * 100).round()}%', style: tt.bodyMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppPaddings.xxl),

          // ── Text Fields ──
          const _SectionTitle('Text Fields', icon: Icons.edit),
          Card(
            child: Padding(
              padding: AppPaddings.allL,
              child: Column(
                spacing: AppPaddings.l,
                children: [
                  TextField(
                    controller: textController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      hintText: 'Enter your username',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: Icon(Icons.lock),
                      suffixIcon: Icon(Icons.visibility_off),
                    ),
                  ),
                  const TextField(
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Bio',
                      hintText: 'Tell us about yourself...',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppPaddings.xxl),

          // ── Progress Indicators ──
          const _SectionTitle(
            'Progress Indicators',
            icon: Icons.hourglass_bottom,
          ),
          Card(
            child: Padding(
              padding: AppPaddings.allL,
              child: Column(
                spacing: AppPaddings.l,
                children: [
                  const LinearProgressIndicator(),
                  LinearProgressIndicator(value: sliderValue),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      CircularProgressIndicator(),
                      CircularProgressIndicator.adaptive(),
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppPaddings.xxl),

          // ── ListTiles ──
          const _SectionTitle('List Tiles', icon: Icons.list),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: cs.primaryContainer,
                    child: Icon(Icons.person, color: cs.onPrimaryContainer),
                  ),
                  title: const Text('John Doe'),
                  subtitle: const Text('Software Engineer'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: cs.secondaryContainer,
                    child: Icon(Icons.email, color: cs.onSecondaryContainer),
                  ),
                  title: const Text('Messages'),
                  subtitle: const Text('3 unread messages'),
                  trailing: Badge(
                    label: const Text('3'),
                    child: Icon(Icons.mail, color: cs.onSurfaceVariant),
                  ),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: cs.tertiaryContainer,
                    child: Icon(Icons.star, color: cs.onTertiaryContainer),
                  ),
                  title: const Text('Favorites'),
                  subtitle: const Text('12 items saved'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: AppPaddings.xxl),

          // ── Badges ──
          const _SectionTitle('Badges', icon: Icons.notifications_active),
          Card(
            child: Padding(
              padding: AppPaddings.allL,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Badge(
                    label: const Text('5'),
                    child: Icon(Icons.mail, size: 32, color: cs.primary),
                  ),
                  Badge(
                    label: const Text('99+'),
                    child: Icon(
                      Icons.notifications,
                      size: 32,
                      color: cs.primary,
                    ),
                  ),
                  Badge(child: Icon(Icons.chat, size: 32, color: cs.primary)),
                  Badge(
                    label: const Text('NEW'),
                    backgroundColor: cs.tertiary,
                    textColor: cs.onTertiary,
                    child: Icon(Icons.star, size: 32, color: cs.primary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppPaddings.xxl),

          // ── Color Palette ──
          const _SectionTitle('Color Palette', icon: Icons.palette),
          Card(
            child: Padding(
              padding: AppPaddings.allL,
              child: Column(
                spacing: AppPaddings.s,
                children: [
                  _ColorRow('primary', cs.primary, cs.onPrimary),
                  _ColorRow(
                    'primaryContainer',
                    cs.primaryContainer,
                    cs.onPrimaryContainer,
                  ),
                  _ColorRow('secondary', cs.secondary, cs.onSecondary),
                  _ColorRow(
                    'secondaryContainer',
                    cs.secondaryContainer,
                    cs.onSecondaryContainer,
                  ),
                  _ColorRow('tertiary', cs.tertiary, cs.onTertiary),
                  _ColorRow(
                    'tertiaryContainer',
                    cs.tertiaryContainer,
                    cs.onTertiaryContainer,
                  ),
                  _ColorRow('error', cs.error, cs.onError),
                  _ColorRow('surface', cs.surface, cs.onSurface),
                  _ColorRow(
                    'surfaceContainerHighest',
                    cs.surfaceContainerHighest,
                    cs.onSurface,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppPaddings.xxl),

          // ── Dialogs & Snackbars ──
          const _SectionTitle('Dialogs & Snackbars', icon: Icons.message),
          Card(
            child: Padding(
              padding: AppPaddings.allL,
              child: Wrap(
                spacing: AppPaddings.s,
                runSpacing: AppPaddings.s,
                children: [
                  FilledButton.tonal(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('This is a SnackBar'),
                        action: SnackBarAction(label: 'Undo', onPressed: () {}),
                      ),
                    ),
                    child: const Text('SnackBar'),
                  ),
                  FilledButton.tonal(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => AlertDialog(
                        icon: const Icon(Icons.info),
                        title: const Text('Dialog Title'),
                        content: const Text(
                          'This is a Material 3 AlertDialog to '
                          'preview theme colors.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Confirm'),
                          ),
                        ],
                      ),
                    ),
                    child: const Text('Dialog'),
                  ),
                  FilledButton.tonal(
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      showDragHandle: true,
                      builder: (_) => SizedBox(
                        height: 200,
                        child: Center(
                          child: Text(
                            'Bottom Sheet Content',
                            style: tt.titleMedium,
                          ),
                        ),
                      ),
                    ),
                    child: const Text('Bottom Sheet'),
                  ),
                  FilledButton.tonal(
                    onPressed: () => showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    ),
                    child: const Text('Date Picker'),
                  ),
                  FilledButton.tonal(
                    onPressed: () => showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    ),
                    child: const Text('Time Picker'),
                  ),
                ],
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

class _ColorRow extends StatelessWidget {
  const _ColorRow(this.label, this.color, this.onColor);

  final String label;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppPaddings.s),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppPaddings.m),
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: onColor),
      ),
    );
  }
}
