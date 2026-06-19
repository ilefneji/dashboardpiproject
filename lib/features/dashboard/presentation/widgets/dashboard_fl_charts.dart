import 'package:constructiondashboard/core/theme/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Empty state helper ──────────────────────────────────────────────────────
class _ChartEmptyState extends StatelessWidget {
  const _ChartEmptyState({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: Get.isDarkMode
                  ? const Color(0xFF1F2937)
                  : const Color(0xFFFFF3E8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.insert_chart_outlined,
              color: AppColors.primaryOrange,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aucune donnee disponible',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Get.isDarkMode
                  ? const Color(0xFFF9FAFB)
                  : const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Get.isDarkMode
                  ? const Color(0xFF9CA3AF)
                  : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 1. Grouped Bar Chart – Projets actifs / archives par mois ───────────────
class ProjectStatusBarChart extends StatelessWidget {
  const ProjectStatusBarChart({super.key, required this.data});

  final List<({String label, int active, int archived})> data;

  @override
  Widget build(BuildContext context) {
    if (data.every((d) => d.active == 0 && d.archived == 0)) {
      return const _ChartEmptyState(
        title: 'Les projets apparaitront apres chargement.',
      );
    }

    final maxVal = data.fold<int>(
      1,
      (m, d) => m > d.active
          ? (m > d.archived ? m : d.archived)
          : (d.active > d.archived ? d.active : d.archived),
    );

    return Column(
      children: [
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (maxVal * 1.2).ceilToDouble(),
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) {
                      if (value % 1 != 0) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(
                          value.toInt().toString(),
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= data.length)
                        return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          data[i].label,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: Get.isDarkMode
                      ? const Color(0xFF374151)
                      : const Color(0xFFE5E7EB),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: data.asMap().entries.map((e) {
                final i = e.key;
                final d = e.value;
                return BarChartGroupData(
                  x: i,
                  barsSpace: 3,
                  barRods: [
                    BarChartRodData(
                      toY: d.active.toDouble(),
                      color: AppColors.primaryOrange,
                      width: 6,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                    BarChartRodData(
                      toY: d.archived.toDouble(),
                      color: const Color(0xFF94A3B8),
                      width: 6,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendItem(color: AppColors.primaryOrange, label: 'Actifs'),
            const SizedBox(width: 16),
            _LegendItem(color: const Color(0xFF94A3B8), label: 'Archives'),
          ],
        ),
      ],
    );
  }
}

// ── 2. Pie Chart – Reserves par priorite ────────────────────────────────────
class ReservePriorityPieChart extends StatelessWidget {
  const ReservePriorityPieChart({super.key, required this.data});

  final Map<String, int> data;

  static const _colors = {
    'Haute': Color(0xFFDC2626),
    'Moyenne': Color(0xFFF59E0B),
    'Faible': Color(0xFF10B981),
  };

  @override
  Widget build(BuildContext context) {
    final nonZero = data.entries.where((e) => e.value > 0).toList();
    if (nonZero.isEmpty) {
      return const _ChartEmptyState(
        title: 'Les reserves apparaitront apres creation.',
      );
    }

    final total = nonZero.fold<int>(0, (s, e) => s + e.value);

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 32,
              sections: nonZero.map((e) {
                final pct = total == 0 ? 0 : (e.value / total * 100);
                return PieChartSectionData(
                  value: e.value.toDouble(),
                  color: _colors[e.key] ?? AppColors.primaryOrange,
                  radius: 52,
                  title: '${pct.toStringAsFixed(0)}%',
                  titleStyle: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  titlePositionPercentageOffset: 0.55,
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: nonZero.map((e) {
            return _LegendItem(
              color: _colors[e.key] ?? AppColors.primaryOrange,
              label: '${e.key} (${e.value})',
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── 3. Horizontal Bar Chart – Activites par statut ──────────────────────────
class TaskStatusHorizontalChart extends StatelessWidget {
  const TaskStatusHorizontalChart({super.key, required this.data});

  final Map<String, int> data;

  static const _colors = {
    'Affectees': Color(0xFF2563EB),
    'Non affectees': Color(0xFF94A3B8),
    'Terminees': Color(0xFF10B981),
    'En retard': Color(0xFFDC2626),
  };

  @override
  Widget build(BuildContext context) {
    final nonZero = data.entries.where((e) => e.value > 0).toList();
    if (nonZero.isEmpty) {
      return const _ChartEmptyState(
        title: 'Les activites apparaitront apres creation.',
      );
    }

    final maxVal = nonZero.fold<int>(1, (m, e) => e.value > m ? e.value : m);

    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: nonZero.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final entry = nonZero[index];
        final color = _colors[entry.key] ?? AppColors.primaryOrange;
        final ratio = entry.value / maxVal;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.key,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${entry.value}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.05, 1.0),
                minHeight: 10,
                backgroundColor: Get.isDarkMode
                    ? const Color(0xFF374151)
                    : const Color(0xFFE5E7EB),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── 4. Line Chart – Journaux de chantier par mois ───────────────────────────
class JournalMonthlyLineChart extends StatelessWidget {
  const JournalMonthlyLineChart({super.key, required this.data});

  final List<({String label, int count})> data;

  @override
  Widget build(BuildContext context) {
    if (data.every((d) => d.count == 0)) {
      return const _ChartEmptyState(
        title: 'Les journaux apparaitront apres creation.',
      );
    }

    final maxVal = data.fold<int>(1, (m, d) => d.count > m ? d.count : m);
    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.count.toDouble());
    }).toList();

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: (maxVal * 1.2).ceilToDouble(),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: AppColors.textPrimary,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((s) {
                final label = data[s.x.toInt()].label;
                return LineTooltipItem(
                  '$label\n${s.y.toInt()}',
                  GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Get.isDarkMode
                ? const Color(0xFF374151)
                : const Color(0xFFE5E7EB),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                if (value % 1 != 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    value.toInt().toString(),
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    data[i].label,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: AppColors.primaryOrange,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.primaryOrange,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primaryOrange.withOpacity(0.12),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 5. Bar Chart – Budget par projet (Top 5) ────────────────────────────────
class TopBudgetBarChart extends StatelessWidget {
  const TopBudgetBarChart({super.key, required this.data});

  final List<({String name, double budget})> data;

  static const _colors = [
    AppColors.primaryOrange,
    Color(0xFF2563EB),
    Color(0xFF10B981),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
  ];

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const _ChartEmptyState(
        title: 'Les budgets apparaitront apres creation de projets.',
      );
    }

    final maxVal = data.fold<double>(1, (m, d) => d.budget > m ? d.budget : m);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (maxVal * 1.15),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: AppColors.textPrimary,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final item = data[groupIndex];
              return BarTooltipItem(
                '${item.name}\n${_formatCompactBudget(item.budget)} TND',
                GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value % 1 != 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    _formatCompactBudget(value),
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                final name = data[i].name;
                final short =
                    name.length > 8 ? '${name.substring(0, 7)}..' : name;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    short,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Get.isDarkMode
                ? const Color(0xFF374151)
                : const Color(0xFFE5E7EB),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data.asMap().entries.map((e) {
          final i = e.key;
          final d = e.value;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: d.budget,
                color: _colors[i % _colors.length],
                width: 18,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── Helpers ─────────────────────────────────────────────────────────────────
class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

String _formatCompactBudget(double value) {
  if (value >= 1000000000) return '${(value / 1000000000).toStringAsFixed(1)}B';
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
  return value.toStringAsFixed(0);
}
