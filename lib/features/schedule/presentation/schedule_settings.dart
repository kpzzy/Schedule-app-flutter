import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/app_strings.dart';
import '../domain/schedule_item.dart';
import '../domain/schedule_preferences.dart';
import 'schedule_preferences_controller.dart';

class ScheduleSettings extends StatelessWidget {
  const ScheduleSettings({super.key, required this.controller});

  final SchedulePreferencesController controller;

  Future<void> _chooseHour(BuildContext context) async {
    final selected = controller.value.startHour;
    final hour = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text(AppStrings.dayStartHour),
        children: [
          for (var hour = 0; hour < 24; hour++)
            ListTile(
              title: Text(AppStrings.hour(hour)),
              selected: selected == hour,
              onTap: () => Navigator.pop(context, hour),
            ),
        ],
      ),
    );
    if (hour == null || hour == selected || !context.mounted) return;
    await _save(context, controller.value.copyWith(startHour: hour));
  }

  void _editCategory(
    BuildContext context, {
    ScheduleCategoryDefinition? category,
  }) {
    showDialog<void>(
      context: context,
      builder: (_) =>
          _CategoryDialog(controller: controller, category: category),
    );
  }

  Future<void> _deleteCategory(
    BuildContext context,
    ScheduleCategoryDefinition category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppStrings.namedCategoryAction(
            AppStrings.deleteCategory,
            category.name,
          ),
        ),
        content: const Text(AppStrings.deletedCategoryHint),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final preferences = controller.value;
    await _save(
      context,
      preferences.copyWith(
        categories: preferences.categories.where(
          (entry) => entry.id != category.id,
        ),
      ),
    );
  }

  Future<void> _save(
    BuildContext context,
    SchedulePreferences preferences,
  ) async {
    final saved = await controller.save(preferences);
    if (!saved && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.updateFailure)));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text(AppStrings.settings)),
    body: SafeArea(
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final preferences = controller.value;
          final ready = !controller.isLoading && !controller.loadFailed;
          final enabled = ready && !controller.isSaving;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (controller.isLoading || controller.isSaving)
                const LinearProgressIndicator(),
              if (controller.loadFailed)
                ListTile(
                  title: const Text(AppStrings.settingsLoadFailure),
                  subtitle: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: controller.load,
                      child: const Text(AppStrings.retry),
                    ),
                  ),
                ),
              if (ready)
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: Text(
                    '${AppStrings.dayStartHour} · ${AppStrings.hour(preferences.startHour)}',
                  ),
                  subtitle: const Text(AppStrings.earlierHoursHint),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: enabled ? () => _chooseHour(context) : null,
                ),
              const Divider(),
              ExpansionTile(
                leading: const Icon(Icons.widgets_outlined),
                title: const Text(AppStrings.homeWidgetHelp),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                expandedAlignment: Alignment.centerLeft,
                children: [
                  Text(
                    defaultTargetPlatform == TargetPlatform.iOS
                        ? AppStrings.homeWidgetIos
                        : AppStrings.homeWidgetAndroid,
                  ),
                ],
              ),
              if (ready) ...[
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    AppStrings.manageCategories,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text(AppStrings.addCategory),
                  onTap: enabled ? () => _editCategory(context) : null,
                ),
                for (final category in preferences.categories)
                  ListTile(
                    leading: CircleAvatar(
                      radius: 9,
                      backgroundColor: Color(category.color),
                    ),
                    title: Text(category.name),
                    onTap: enabled
                        ? () => _editCategory(context, category: category)
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: AppStrings.namedCategoryAction(
                            AppStrings.editCategory,
                            category.name,
                          ),
                          onPressed: enabled
                              ? () => _editCategory(context, category: category)
                              : null,
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          tooltip: AppStrings.namedCategoryAction(
                            AppStrings.deleteCategory,
                            category.name,
                          ),
                          onPressed: enabled
                              ? () => _deleteCategory(context, category)
                              : null,
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    ),
  );
}

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({required this.controller, this.category});

  final SchedulePreferencesController controller;
  final ScheduleCategoryDefinition? category;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  static const _colors = [
    0xFF315CA8,
    0xFF7854A0,
    0xFF287453,
    0xFFAA5B2C,
    0xFFAE2730,
    0xFF11727D,
    0xFF9A336F,
    0xFF555E65,
  ];
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.category?.name);
  late int _color = widget.category?.color ?? _colors.first;
  bool _busy = false;
  bool _saveFailed = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String? _validateName(String? input) {
    if (input == null || input.trim().isEmpty) {
      return AppStrings.categoryNameRequired;
    }
    if (widget.controller.value.hasCategoryName(
      input,
      exceptId: widget.category?.id,
    )) {
      return AppStrings.duplicateCategoryName;
    }
    return null;
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    final existing = widget.category;
    final category = ScheduleCategoryDefinition(
      existing?.id ?? ScheduleItem.newId(),
      _name.text.trim(),
      _color,
    );
    final preferences = widget.controller.value;
    final categories = [
      for (final entry in preferences.categories)
        entry.id == existing?.id ? category : entry,
      if (existing == null) category,
    ];
    setState(() {
      _busy = true;
      _saveFailed = false;
    });
    final saved = await widget.controller.save(
      preferences.copyWith(categories: categories),
    );
    if (!mounted) return;
    if (saved && ModalRoute.of(context)?.isCurrent == true) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _busy = false;
      _saveFailed = !saved;
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      scrollable: true,
      title: Text(
        widget.category == null
            ? AppStrings.addCategory
            : AppStrings.editCategory,
      ),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _name,
              maxLength: 40,
              enabled: !_busy,
              decoration: const InputDecoration(
                labelText: AppStrings.categoryName,
              ),
              validator: _validateName,
            ),
            const SizedBox(height: 12),
            const Text(AppStrings.categoryColor),
            Wrap(
              spacing: 8,
              children: [
                for (final (index, color) in _colors.indexed)
                  ChoiceChip(
                    avatar: CircleAvatar(backgroundColor: Color(color)),
                    label: Text(AppStrings.categoryColorNames[index]),
                    selected: _color == color,
                    onSelected: _busy
                        ? null
                        : (_) => setState(() => _color = color),
                  ),
              ],
            ),
            if (_saveFailed)
              Text(
                AppStrings.saveFailure,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(_busy ? AppStrings.saving : AppStrings.save),
        ),
      ],
    ),
  );
}
