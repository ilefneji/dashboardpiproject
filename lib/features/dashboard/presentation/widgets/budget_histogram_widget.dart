// lib/features/dashboard/presentation/widgets/budget_histogram_widget.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../project/presentation/controllers/project_controller.dart';
import '../../../project/data/models/project_model.dart';

class BudgetHistogramWidget extends StatelessWidget {
  const BudgetHistogramWidget({
    super.key,
    this.suppressLoading = false,
    this.isLoading = false,
  });

  final bool suppressLoading;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProjectController>();

    return Obx(() {
      final isDark = Get.isDarkMode;
      final colors = Theme.of(context).colorScheme;
      final panelColor = isDark ? const Color(0xFF111827) : Colors.white;
      final softColor = isDark
          ? const Color(0xFF1F2937)
          : const Color(0xFFF8FAFC);
      final titleColor = isDark
          ? const Color(0xFFF9FAFB)
          : const Color(0xFF111827);
      final mutedColor = isDark
          ? const Color(0xFF9CA3AF)
          : const Color(0xFF6B7280);
      final gridColor =
          (isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB))
              .withOpacity(isDark ? 0.65 : 1);

      final projects = controller.filteredProjects
          .where((p) => p.budget > 0)
          .take(6)
          .toList();

      final actuallyLoading = isLoading || controller.isLoading.value;

      if (!suppressLoading && actuallyLoading && projects.isEmpty) {
        return _buildLoadingState(context, controller.selectedYear.value);
      }

      if (projects.isEmpty) {
        return _buildEmptyState(
          context,
          controller.selectedYear.value,
          'Aucune donnée disponible',
        );
      }

      final selectedYr = controller.selectedYear.value;
      final widgetTitle = selectedYr != 0
          ? 'Budget par Projet — $selectedYr'
          : 'Budget par Projet';

      // ✅ LayoutBuilder wraps everything to know real available width
      return LayoutBuilder(
        builder: (context, constraints) {
          // ✅ Dynamic bar width based on available space
          final int count = projects.length;
          final double barWidth = ((constraints.maxWidth - 80) / count - 12)
              .clamp(8.0, 28.0);

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: panelColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE5E7EB),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.22 : 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // ✅ shrink to content
              children: [
                // ── Header ──────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFF4F8EF7,
                        ).withOpacity(isDark ? 0.18 : 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Color(0xFF4F8EF7),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // ✅ Expanded prevents title from pushing layout
                    Expanded(
                      child: Text(
                        widgetTitle,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2, // ✅ allows wrap on narrow screens
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // ── Sous-titre + Badge ───────────────────────
                // ✅ Wrap instead of Row → badge drops below on narrow screens
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Répartition des budgets (TND)',
                      style: TextStyle(fontSize: 11, color: mutedColor),
                    ),
                    if (selectedYr != 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F8EF7).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$selectedYr',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(
                              0xFF4F8EF7,
                            ).withOpacity(isDark ? 0.9 : 1),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Bar Chart ────────────────────────────────
                // ✅ Fixed height — never expands uncontrollably
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxBudget(projects) * 1.2,

                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: isDark
                              ? const Color(0xFF1A1A2E)
                              : const Color(0xFF111827),
                          tooltipRoundedRadius: 8,
                          getTooltipItem: (group, groupIndex, rod, _) {
                            final project = projects[groupIndex];
                            return BarTooltipItem(
                              '${project.name}\n'
                              '${_formatBudget(rod.toY)} TND',
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
                        ),
                      ),

                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= projects.length) {
                                return const SizedBox.shrink();
                              }
                              final name = projects[index].name;
                              // ✅ Truncate label to available bar width
                              final maxChars = (barWidth / 6).floor().clamp(
                                3,
                                8,
                              );
                              final label = name.length > maxChars
                                  ? '${name.substring(0, maxChars)}…'
                                  : name;
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: mutedColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 46, // ✅ fixed reserved size
                            getTitlesWidget: (value, meta) {
                              return Text(
                                _formatBudgetShort(value),
                                style: TextStyle(
                                  fontSize: 9,
                                  color: mutedColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),

                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) =>
                            FlLine(color: gridColor, strokeWidth: 1),
                      ),

                      borderData: FlBorderData(show: false),

                      // ✅ Dynamic bar width passed in
                      barGroups: _buildBarGroups(projects, barWidth),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ── Total Footer ─────────────────────────────
                Container(
                  width: double.infinity, // ✅ always fills container
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: softColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  // ✅ Wrap prevents row overflow on small widths
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '💰 Budget Total',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                        ),
                      ),
                      Text(
                        '${_formatBudget(_getTotalBudget(projects))} TND',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(
                            0xFF4F8EF7,
                          ).withOpacity(isDark ? 0.9 : 1),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  // ✅ barWidth passed in — no more hardcoded 22
  List<BarChartGroupData> _buildBarGroups(
    List<ProjectModel> projects,
    double barWidth,
  ) {
    const colors = [
      Color(0xFF4F8EF7),
      Color(0xFF34C759),
      Color(0xFFFF9F0A),
      Color(0xFFFF453A),
      Color(0xFFBF5AF2),
      Color(0xFF32ADE6),
    ];

    return projects.asMap().entries.map((entry) {
      final index = entry.key;
      final project = entry.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: project.budget.toDouble(),
            color: colors[index % colors.length],
            width: barWidth, // ✅ responsive
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(5),
              topRight: Radius.circular(5),
            ),
          ),
        ],
      );
    }).toList();
  }

  double _getMaxBudget(List<ProjectModel> projects) {
    if (projects.isEmpty) return 100;
    return projects
        .map((p) => p.budget.toDouble())
        .reduce((a, b) => a > b ? a : b);
  }

  double _getTotalBudget(List<ProjectModel> projects) {
    return projects.fold(0.0, (sum, p) => sum + p.budget);
  }

  String _formatBudget(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toStringAsFixed(0);
  }

  String _formatBudgetShort(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(0)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toStringAsFixed(0);
  }

  Widget _buildEmptyState(
    BuildContext context,
    int selectedYr,
    String fallbackMessage,
  ) {
    final message = selectedYr != 0
        ? 'Aucun budget pour $selectedYr'
        : fallbackMessage;
    final isDark = Get.isDarkMode;
    final colors = Theme.of(context).colorScheme;
    final panelColor = isDark ? const Color(0xFF111827) : Colors.white;
    final titleColor = isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B7280);

    return Container(
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.22 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // ✅ no vertical expansion
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 48,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: titleColor, fontSize: 13),
              textAlign: TextAlign.center, // ✅ safe on narrow screens
            ),
            if (selectedYr != 0) ...[
              const SizedBox(height: 4),
              Text(
                'Filtre actif : $selectedYr',
                style: TextStyle(
                  color: const Color(0xFF4F8EF7).withOpacity(isDark ? 0.9 : 1),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context, int selectedYr) {
    final colors = Theme.of(context).colorScheme;
    final panelColor = colors.surface;
    final titleColor = colors.onSurfaceVariant;

    return Container(
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(Get.isDarkMode ? 0.22 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: const LinearProgressIndicator(minHeight: 3),
            ),
            const SizedBox(height: 16),
            Icon(
              Icons.bar_chart_rounded,
              size: 48,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              'Aucune donnée disponible',
              style: TextStyle(color: titleColor, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              selectedYr != 0
                  ? 'Chargement en cours pour $selectedYr'
                  : 'Chargement des budgets en cours',
              style: TextStyle(color: titleColor, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
