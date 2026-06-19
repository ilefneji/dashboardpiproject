// lib/features/dashboard/presentation/widgets/global_kpi_section.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../organization/presentation/controllers/organization_controller.dart';
import '../../../users/presentation/controllers/user_controller.dart';
import '../../../project/presentation/controllers/project_controller.dart';
import '../../../lot/presentation/controllers/lot_controller.dart';

class GlobalKpiSection extends StatefulWidget {
  const GlobalKpiSection({super.key});

  @override
  State<GlobalKpiSection> createState() => _GlobalKpiSectionState();
}

class _GlobalKpiSectionState extends State<GlobalKpiSection> {
  late final OrganizationController orgController;
  late final UserController userController;
  late final ProjectController projectController;
  late final LotController lotController;

  @override
  void initState() {
    super.initState();

    // ✅ Récupère les controllers — données déjà chargées par le Binding !
    orgController = Get.find<OrganizationController>();
    userController = Get.find<UserController>();
    projectController = Get.find<ProjectController>();
    lotController = Get.find<LotController>();

    // 🔥 SUPPRIMÉ — plus de fetch ici, le Binding s'en charge !
    // if (orgController.organizations.isEmpty)  orgController.fetchOrganizations();
    // if (userController.users.isEmpty)         userController.fetchUsers();
    // if (projectController.projects.isEmpty)   projectController.getAllProjectsNoFilter();
    // if (lotController.lots.isEmpty)           lotController.fetchLots();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final kpis = [
        _KpiData(
          title: 'Activites',
          value: lotController.tasks.length.toString(),
          icon: Icons.task_alt_rounded,
          color: const Color(0xFF4F8EF7),
          gradientColors: [
            const Color(0xFF4F8EF7),
            const Color(0xFF3B6FD4),
          ],
        ),
        _KpiData(
          title: 'Utilisateurs',
          value: '${userController.users.length}',
          icon: Icons.people_alt_rounded,
          color: const Color(0xFF43C59E),
          gradientColors: [
            const Color(0xFF43C59E),
            const Color(0xFF2EA87F),
          ],
        ),
        _KpiData(
          title: 'Projets',
          value: projectController.projects.length.toString(),
          icon: Icons.folder_rounded,
          color: const Color(0xFFF7934C),
          gradientColors: [
            const Color(0xFFF7934C),
            const Color(0xFFE07330),
          ],
        ),
        _KpiData(
          title: 'Lots',
          value: lotController.lots.length.toString(),
          icon: Icons.layers_rounded,
          color: const Color(0xFFAF7EF7),
          gradientColors: [
            const Color(0xFFAF7EF7),
            const Color(0xFF8B55E0),
          ],
        ),
      ];

      return _buildKpiRow(kpis);
    });
  }

  // ── KPI Row ───────────────────────────────────────────────────

  Widget _buildKpiRow(List<_KpiData> kpis) {
    return Row(
      children: kpis
          .asMap()
          .entries
          .map((e) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: e.key < kpis.length - 1 ? 10 : 0,
                  ),
                  child: _KpiCard(data: e.value),
                ),
              ))
          .toList(),
    );
  }

}

// ── KPI Data Model ─────────────────────────────────────────────

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

// ── KPI Card ───────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final _KpiData data;
  const _KpiCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: data.color.withOpacity(0.10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Gradient Icon ────────────────────────────
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: data.gradientColors,
              ),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: data.color.withOpacity(0.30),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(data.icon, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 10),

          // ── Value ────────────────────────────────────
          Text(
            data.value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),

          // ── Title ────────────────────────────────────
          Text(
            data.title,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
