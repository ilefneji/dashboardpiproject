import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/task_control.dart';

class TaskControlListItem extends StatelessWidget {
  final TaskControl taskControl;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskControlListItem({
    super.key,
    required this.taskControl,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.outlineVariant),
            boxShadow: [
              BoxShadow(
                  color: colors.shadow.withOpacity(
                      theme.brightness == Brightness.dark ? 0.16 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 4))
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  (taskControl.name != null && taskControl.name!.isNotEmpty)
                      ? taskControl.name![0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18),
                ),
              ),

              const SizedBox(width: 14),

              // Main info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      taskControl.name ?? '-',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface),
                    ),
                    if (taskControl.description != null &&
                        taskControl.description!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        taskControl.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13, color: colors.onSurfaceVariant),
                      ),
                    ],

                    const SizedBox(height: 10),

                    // Chips row
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (taskControl.taskId != null)
                          _InfoChip(
                            icon: Icons.tag,
                            label: 'ID: ${taskControl.taskId}',
                            color: const Color(0xFF64748B),
                          ),
                        if (taskControl.status != null &&
                            taskControl.status!.isNotEmpty)
                          _InfoChip(
                            icon: Icons.info_outline,
                            label: taskControl.status!,
                            color: AppColors.primaryColor,
                          ),
                        if (taskControl.referencePath != null &&
                            taskControl.referencePath!.isNotEmpty)
                          _InfoChip(
                            icon: Icons.link,
                            label: taskControl.referencePath!,
                            color: const Color(0xFF94A3B8),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Actions
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: onEdit,
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.edit_outlined,
                          size: 18, color: AppColors.primaryColor),
                    ),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.delete_outline,
                          size: 18, color: Color(0xFFEF4444)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Small info chip used in task control cards to match organization style
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color.withOpacity(0.85)),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color.withOpacity(0.9)),
            ),
          ),
        ],
      ),
    );
  }
}
