// lib/features/dashboard/presentation/widgets/project_dashboard_section.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../project/presentation/controllers/project_controller.dart';
import 'project_analytics_histogram.dart';

class ProjectDashboardSection extends StatelessWidget {
  const ProjectDashboardSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProjectController>();

    return Obx(() {
      final isLoading = controller.isLoading.value;
      // ── Données demo (stables jusqu'à confirmation du modèle) ────────
      final histoData = _buildDemoData();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isLoading) ...[
            const _InlineLoader(),
            const SizedBox(height: 10),
          ],
          ProjectAnalyticsHistogram(
            title: 'Analyse des Projets',
            data: histoData,
          ),
        ],
      );
    });
  }

  // ── Données demo ──────────────────────────────────────────────────────
  List<ProjectBarData> _buildDemoData() {
    return [
      const ProjectBarData(label: 'Jan', total: 5, active: 3, archived: 2),
      const ProjectBarData(label: 'Fév', total: 8, active: 6, archived: 2),
      const ProjectBarData(label: 'Mar', total: 12, active: 9, archived: 3),
      const ProjectBarData(label: 'Avr', total: 7, active: 5, archived: 2),
      const ProjectBarData(label: 'Mai', total: 15, active: 11, archived: 4),
      const ProjectBarData(label: 'Jun', total: 10, active: 7, archived: 3),
    ];
  }
}

class _InlineLoader extends StatelessWidget {
  const _InlineLoader();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: const LinearProgressIndicator(minHeight: 3),
    );
  }
}
