import 'package:material_ui/material_ui.dart';

import '../../../../app/app_strings.dart';
import '../../../../app/app_theme.dart';
import '../../domain/schedule_item.dart';

class ScheduleTile extends StatelessWidget {
  const ScheduleTile({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onToggle,
    this.enabled = true,
  });

  final ScheduleItem item;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.categoryColor(item.category);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: color.withValues(alpha: 0.07),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? onEdit : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        decoration: item.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(AppStrings.itemTime(item)),
                    const SizedBox(height: 4),
                    Text(
                      '${AppStrings.categoryName(item.category)}'
                      '${item.origin != null ? ' · ${AppStrings.repeat}' : ''}'
                      '${item.isCompleted ? ' · ${AppStrings.completed}' : ''}',
                      style: TextStyle(color: color),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: item.isCompleted
                    ? AppStrings.undoComplete
                    : AppStrings.complete,
                onPressed: enabled ? onToggle : null,
                icon: Icon(
                  item.isCompleted
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                ),
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
