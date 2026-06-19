
// lib/organization/presentation/widgets/org_card_widget.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class OrgCardWidget extends StatelessWidget {
  final String name;
  final String date;
  final int members;
  final int projects;

  const OrgCardWidget({super.key, 
    required this.name,
    required this.date,
    required this.members,
    required this.projects,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withOpacity(0.12),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Header
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.business,
              color: AppColors.primaryOrange,
              size: 24,
            ),
          ),

          const SizedBox(height: 12),

          // Nom
          Text(name,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface)),

          Text(date,
              style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),

          const Spacer(),

          // Stats
          Row(
            children: [
              const Icon(Icons.people, size: 14, color: AppColors.primaryOrange),
              const SizedBox(width: 4),
              Text('\$$members',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(width: 12),
              const Icon(Icons.folder, size: 14, color: AppColors.primaryOrange),
              const SizedBox(width: 4),
              Text('\$$projects',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),

          const SizedBox(height: 8),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: projects / 10,
              backgroundColor: AppColors.primaryOrange.withOpacity(0.1),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primaryOrange),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
