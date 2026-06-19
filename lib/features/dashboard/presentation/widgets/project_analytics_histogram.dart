// lib/features/dashboard/presentation/widgets/project_analytics_histogram.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Modèle de données ─────────────────────────────────────────────────────────
class ProjectBarData {
  final String label;
  final int total;
  final int active;
  final int archived;

  const ProjectBarData({
    required this.label,
    required this.total,
    required this.active,
    required this.archived,
  });
}

// ── Widget principal ──────────────────────────────────────────────────────────
class ProjectAnalyticsHistogram extends StatelessWidget {
  final String title;
  final List<ProjectBarData> data;

  const ProjectAnalyticsHistogram({
    super.key,
    required this.title,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxValue = data.isEmpty
        ? 1
        : data.map((e) => e.total).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // ✅ shrinks to content
        children: [
          // ── Titre + Légende ───────────────────────────────
          // ✅ Wrap prevents overflow in narrow screens
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
                ),
                overflow: TextOverflow.ellipsis, // ✅ no title crash
                maxLines: 1,
              ),
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LegendDot(
                    color: Color(0xFF4F8EF7),
                    label: 'Actifs',
                  ),
                  SizedBox(width: 12),
                  _LegendDot(
                    color: Color(0xFFFFB347),
                    label: 'Archivés',
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Chart Area ────────────────────────────────────
          // ✅ LayoutBuilder reads actual available width
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;

              // ✅ Dynamically size bars based on available width
              final int count = data.isEmpty ? 1 : data.length;
              final double barWidth = ((availableWidth / count) - 16)
                  .clamp(6.0, 20.0); // ✅ never too thin or too wide
              final double gap = barWidth * 0.3;

              return SizedBox(
                height: 180,
                child: data.isEmpty
                    ? Center(
                        child: Text(
                          'Aucune donnée',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: isDark
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: data.map((item) {
                          return _BarGroup(
                            data: item,
                            maxValue: maxValue,
                            barWidth: barWidth, // ✅ responsive bar width
                            gap: gap,
                          );
                        }).toList(),
                      ),
              );
            },
          ),

          const SizedBox(height: 8),

          // ── Baseline ──────────────────────────────────────
          Container(
            height: 1,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
          ),

          const SizedBox(height: 8),

          // ── Total global ──────────────────────────────────
          Center(
            child: Wrap(
              spacing: 4,
              children: [
                Text(
                  'Total projets :',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                  ),
                ),
                Text(
                  '${data.fold(0, (sum, e) => sum + e.total)}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
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

// ── Groupe de barres ──────────────────────────────────────────────────────────
class _BarGroup extends StatelessWidget {
  final ProjectBarData data;
  final int maxValue;
  final double barWidth; // ✅ dynamic
  final double gap; // ✅ dynamic

  const _BarGroup({
    required this.data,
    required this.maxValue,
    required this.barWidth,
    required this.gap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Total value label ──────────────────────────────
        Text(
          '${data.total}',
          style: GoogleFonts.poppins(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 4),

        // ── Barres actif + archivé ─────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            _SingleBar(
              value: data.active,
              maxValue: maxValue,
              color: const Color(0xFF4F8EF7),
              width: barWidth,
            ),
            SizedBox(width: gap),
            _SingleBar(
              value: data.archived,
              maxValue: maxValue,
              color: const Color(0xFFFFB347),
              width: barWidth,
            ),
          ],
        ),
        const SizedBox(height: 6),

        // ── Label mois ────────────────────────────────────
        // ✅ SizedBox constrains label to bar group width
        SizedBox(
          width: barWidth * 2 + gap,
          child: Text(
            data.label,
            style: GoogleFonts.poppins(
              fontSize: 9,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis, // ✅ no label crash
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}

// ── Barre unique ──────────────────────────────────────────────────────────────
class _SingleBar extends StatelessWidget {
  final int value;
  final int maxValue;
  final Color color;
  final double width; // ✅ responsive width injected

  const _SingleBar({
    required this.value,
    required this.maxValue,
    required this.color,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final double height = maxValue == 0 ? 4 : (value / maxValue) * 130;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      width: width,
      height: height.clamp(4.0, 130.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// ── Point de légende ──────────────────────────────────────────────────────────
class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}
