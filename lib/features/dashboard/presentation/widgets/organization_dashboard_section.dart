import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../organization/presentation/controllers/organization_controller.dart';

class OrganizationDashboardSection extends StatelessWidget {
  const OrganizationDashboardSection({super.key});

  // Palette for type distribution bars
  static const List<Color> _typeColors = [
    Color(0xFF4F8EF7),
    Color(0xFF43C59E),
    Color(0xFFF7934C),
    Color(0xFFAF7EF7),
    Color(0xFFF76E8A),
    Color(0xFF59C8E5),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OrganizationController>();

    return Obx(() {
      final isLoading = controller.isLoading.value;

      final typeData = controller.organizationsByType.entries.toList();
      final recentOrgs = controller.recentOrganizations;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLoading) ...[const _InlineLoader(), const SizedBox(height: 10)],
          _buildSectionHeader(context, controller),
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildTypeDistributionCard(typeData, controller),
                ),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: _buildRecentOrgsCard(recentOrgs)),
              ],
            ),
          ),
        ],
      );
    });
  }

  // ── Section Header ───────────────────────────────────────────────────────────

  Widget _buildSectionHeader(
    BuildContext context,
    OrganizationController controller,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        // Accent bar with gradient
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFE6820A), Color(0xFFF7934C)],
            ),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Organisations',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
          ),
        ),
        const Spacer(),
        // Total badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF4F8EF7).withOpacity(0.10),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.corporate_fare_rounded,
                size: 12,
                color: Color(0xFF4F8EF7),
              ),
              const SizedBox(width: 4),
              Text(
                '${controller.totalOrganizations} au total',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4F8EF7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Type Distribution Card ────────────────────────────────────────────────────

  Widget _buildTypeDistributionCard(
    List<MapEntry<String, int>> typeData,
    OrganizationController controller,
  ) {
    return _SectionCard(
      title: 'Répartition par type',
      icon: Icons.donut_small_rounded,
      accentColor: const Color(0xFF4F8EF7),
      child: typeData.isEmpty
          ? const _EmptyState(message: 'Aucune donnée disponible')
          : Column(
              children: typeData.asMap().entries.map((entry) {
                final total = controller.totalOrganizations == 0
                    ? 1
                    : controller.totalOrganizations;
                final percent = entry.value.value / total;
                final color = _typeColors[entry.key % _typeColors.length];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 13),
                  child: _TypeProgressRow(
                    label: entry.value.key,
                    count: entry.value.value,
                    percent: percent,
                    color: color,
                  ),
                );
              }).toList(),
            ),
    );
  }

  // ── Recent Organizations Card ─────────────────────────────────────────────────

  Widget _buildRecentOrgsCard(List<dynamic> recentOrgs) {
    return _SectionCard(
      title: 'Récentes',
      icon: Icons.access_time_filled_rounded,
      accentColor: const Color(0xFF43C59E),
      child: recentOrgs.isEmpty
          ? const _EmptyState(message: 'Aucune organisation')
          : Column(
              children: recentOrgs.asMap().entries.map((entry) {
                final org = entry.value;
                final type = (org.organismeType ?? '').trim().isEmpty
                    ? 'Non défini'
                    : org.organismeType!;
                final avatarColor = _typeColors[entry.key % _typeColors.length];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RecentOrgItem(
                    name: org.name,
                    type: type,
                    avatarColor: avatarColor,
                  ),
                );
              }).toList(),
            ),
    );
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

// ── KPI Data Model ────────────────────────────────────────────────────────────

class _KpiData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final List<Color> gradientColors;

  const _KpiData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.gradientColors,
  });
}

// ── Section Card ──────────────────────────────────────────────────────────────

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
          // Card Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: accentColor),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? const Color(0xFFF9FAFB)
                      : const Color(0xFF111827),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Divider(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
            thickness: 1,
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

// ── Type Progress Row ─────────────────────────────────────────────────────────

class _TypeProgressRow extends StatelessWidget {
  final String label;
  final int count;
  final double percent;
  final Color color;

  const _TypeProgressRow({
    required this.label,
    required this.count,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Color dot
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 7),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF6B7280),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // Percentage label
            Text(
              '${(percent * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(width: 6),
            // Count badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Progress bar with gradient
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Stack(
            children: [
              // Background track
              Container(height: 6, color: color.withOpacity(0.08)),
              // Filled portion
              FractionallySizedBox(
                widthFactor: percent.clamp(0.0, 1.0),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.7), color],
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Recent Org Item ───────────────────────────────────────────────────────────

class _RecentOrgItem extends StatelessWidget {
  final String name;
  final String type;
  final Color avatarColor;

  const _RecentOrgItem({
    required this.name,
    required this.type,
    required this.avatarColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        // Avatar with gradient
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [avatarColor.withOpacity(0.7), avatarColor],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: avatarColor.withOpacity(0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFFF9FAFB)
                      : const Color(0xFF111827),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              // Type chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: avatarColor.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  type,
                  style: GoogleFonts.poppins(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: avatarColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 28,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
