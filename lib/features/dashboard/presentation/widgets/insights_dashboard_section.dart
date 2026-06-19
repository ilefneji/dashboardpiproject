import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../lot/presentation/controllers/lot_controller.dart';
import '../../../users/presentation/controllers/user_controller.dart';

class InsightsDashboardSection extends StatelessWidget {
  const InsightsDashboardSection({super.key});

  @override
  Widget build(BuildContext context) {
    final lotController = Get.find<LotController>();
    final userController = Get.find<UserController>();

    return Obx(() {
      final isLoading =
          lotController.isLoading.value || userController.isLoading.value;

      final totalLots = lotController.lots.length;
      final totalTasks = lotController.tasks.length;
      final tasksWithLot =
          lotController.tasks.where((task) => task.lotId != null).length;
      final tasksWithoutLot = totalTasks - tasksWithLot;

      final lotsWithTasks =
          lotController.lots.where((lot) => lot.taskIds.isNotEmpty).length;
      final lotsWithoutTasks = totalLots - lotsWithTasks;

      final totalUsers = userController.users.length;
      final activeUsers =
          userController.users.where((user) => user.isActive == true).length;
      final inactiveUsers = totalUsers - activeUsers;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isLoading) ...[
            const _InlineLoader(),
            const SizedBox(height: 10),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 900;

              final summaryCard = _SummaryCard(
                totalLots: totalLots,
                totalTasks: totalTasks,
                totalUsers: totalUsers,
                activeUsers: activeUsers,
              );

              final distributionCard = _DistributionCard(
                totalTasks: totalTasks,
                tasksWithLot: tasksWithLot,
                tasksWithoutLot: tasksWithoutLot,
                totalLots: totalLots,
                lotsWithTasks: lotsWithTasks,
                lotsWithoutTasks: lotsWithoutTasks,
                totalUsers: totalUsers,
                activeUsers: activeUsers,
                inactiveUsers: inactiveUsers,
              );

              if (isNarrow) {
                return Column(
                  children: [
                    summaryCard,
                    const SizedBox(height: 12),
                    distributionCard,
                  ],
                );
              }

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: summaryCard),
                    const SizedBox(width: 12),
                    Expanded(child: distributionCard),
                  ],
                ),
              );
            },
          ),
        ],
      );
    });
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

class _SummaryCard extends StatelessWidget {
  final int totalLots;
  final int totalTasks;
  final int totalUsers;
  final int activeUsers;

  const _SummaryCard({
    required this.totalLots,
    required this.totalTasks,
    required this.totalUsers,
    required this.activeUsers,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Synthese rapide',
      icon: Icons.insights_rounded,
      accentColor: const Color(0xFF4F8EF7),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MiniKpi(
                  title: 'Lots',
                  value: totalLots.toString(),
                  icon: Icons.layers_rounded,
                  color: const Color(0xFF4F8EF7),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniKpi(
                  title: 'Activites',
                  value: totalTasks.toString(),
                  icon: Icons.task_alt_rounded,
                  color: const Color(0xFF43C59E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniKpi(
                  title: 'Utilisateurs',
                  value: totalUsers.toString(),
                  icon: Icons.people_alt_rounded,
                  color: const Color(0xFFF7934C),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniKpi(
                  title: 'Actifs',
                  value: activeUsers.toString(),
                  icon: Icons.verified_user_rounded,
                  color: const Color(0xFFAF7EF7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DistributionCard extends StatelessWidget {
  final int totalTasks;
  final int tasksWithLot;
  final int tasksWithoutLot;
  final int totalLots;
  final int lotsWithTasks;
  final int lotsWithoutTasks;
  final int totalUsers;
  final int activeUsers;
  final int inactiveUsers;

  const _DistributionCard({
    required this.totalTasks,
    required this.tasksWithLot,
    required this.tasksWithoutLot,
    required this.totalLots,
    required this.lotsWithTasks,
    required this.lotsWithoutTasks,
    required this.totalUsers,
    required this.activeUsers,
    required this.inactiveUsers,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Repartition',
      icon: Icons.donut_small_rounded,
      accentColor: const Color(0xFF43C59E),
      child: Column(
        children: [
          _ProgressRow(
            label: 'Activites liees a un lot',
            count: tasksWithLot,
            total: totalTasks,
            color: const Color(0xFF4F8EF7),
          ),
          const SizedBox(height: 12),
          _ProgressRow(
            label: 'Activites sans lot',
            count: tasksWithoutLot,
            total: totalTasks,
            color: const Color(0xFFF97316),
          ),
          const SizedBox(height: 12),
          _ProgressRow(
            label: 'Lots avec activites',
            count: lotsWithTasks,
            total: totalLots,
            color: const Color(0xFFAF7EF7),
          ),
          const SizedBox(height: 12),
          _ProgressRow(
            label: 'Utilisateurs actifs',
            count: activeUsers,
            total: totalUsers,
            color: const Color(0xFF43C59E),
          ),
          const SizedBox(height: 12),
          _ProgressRow(
            label: 'Utilisateurs inactifs',
            count: inactiveUsers,
            total: totalUsers,
            color: const Color(0xFF94A3B8),
          ),
          if (totalLots > 0) ...[
            const SizedBox(height: 12),
            _ProgressRow(
              label: 'Lots sans activites',
              count: lotsWithoutTasks,
              total: totalLots,
              color: const Color(0xFFF59E0B),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniKpi extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniKpi({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _ProgressRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final safeTotal = total == 0 ? 1 : total;
    final percent = count / safeTotal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ),
            Text(
              '$count',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: percent.clamp(0, 1),
            minHeight: 6,
            backgroundColor: color.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: accentColor),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
