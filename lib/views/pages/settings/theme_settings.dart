import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:panara_dialogs/panara_dialogs.dart';
import 'package:trackedify/services/theme_controller.dart';

class ThemeSettingsPage extends StatefulWidget {
  const ThemeSettingsPage({super.key});

  @override
  State<ThemeSettingsPage> createState() => _ThemeSettingsPageState();
}

class _ThemeSettingsPageState extends State<ThemeSettingsPage> {
  final ThemeController ctrl = ThemeController.instance;

  void showTipsDialog() {
    const tips =
        '''Tip: You can choose different color schemes for Light and Dark. The System mode uses your system OS mode to pick which one to apply.''';

    PanaraInfoDialog.show(
      context,
      title: 'Tips',
      message: tips,
      buttonText: 'Got it',
      onTapDismiss: () => Navigator.pop(context),
      textColor: Theme.of(context).textTheme.bodySmall?.color,
      panaraDialogType: PanaraDialogType.normal,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Theme Settings', style: theme.textTheme.titleLarge),
        centerTitle: false,
        leading: IconButton(
          tooltip: "Back",
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 25,
            color: cs.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actionsPadding: const EdgeInsets.only(right: 6),
        actions: [
          IconButton(
            tooltip: 'Tips',
            icon: Icon(Icons.lightbulb_outline, color: cs.onSurface),
            onPressed: showTipsDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AnimatedBuilder(
          animation: ctrl,
          builder: (context, _) {
            return ListView(
              children: [
                Text(
                  'Mode',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: ThemeMode.values.map((m) {
                      final label = m == ThemeMode.system
                          ? 'System'
                          : (m == ThemeMode.light ? 'Light' : 'Dark');
                      final bool selected = ctrl.themeMode == m;
                      return ListTile(
                        leading: Icon(
                          selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: selected ? theme.colorScheme.primary : null,
                        ),
                        title: Text(label),
                        onTap: () {
                          if (!selected) {
                            ctrl.setThemeMode(m);
                          }
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Light theme options',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _buildOptionsGrid(
                      options: ctrl.availableLightOptions,
                      selected: ctrl.selectedLightOption,
                      onSelect: (opt) async {
                        await ctrl.setLightOption(opt);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Dark theme options',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _buildOptionsGrid(
                      options: ctrl.availableDarkOptions,
                      selected: ctrl.selectedDarkOption,
                      onSelect: (opt) async {
                        await ctrl.setDarkOption(opt);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildOptionsGrid({
    required List<ThemeOption> options,
    required ThemeOption selected,
    required ValueChanged<ThemeOption> onSelect,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: options.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.75,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (context, idx) {
        final o = options[idx];
        final isSelected = o.id == selected.id;

        // Prepare a small color preview: primary + secondary bands.
        Color primary;
        Color secondary;
        if (o.isFlex) {
          final td = FlexThemeData.light(scheme: o.flexScheme!);
          primary = td.colorScheme.primary;
          secondary = td.colorScheme.secondary;
        } else {
          final cs = o.colorScheme!;
          primary = cs.primary;
          secondary = cs.secondary;
        }

        return GestureDetector(
          onTap: () => onSelect(o),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                ),
              ],
            ),
            padding: const EdgeInsets.all(6),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Column(
                      children: [
                        Expanded(child: Container(color: primary)),
                        Expanded(child: Container(color: secondary)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  o.name,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
