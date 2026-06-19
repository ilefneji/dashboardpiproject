import 'package:constructiondashboard/core/widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/project_admin_detail_controller.dart';

class ProjectAdminDetailScreen extends StatefulWidget {
  const ProjectAdminDetailScreen({super.key});

  @override
  State<ProjectAdminDetailScreen> createState() =>
      _ProjectAdminDetailScreenState();
}

class _ProjectAdminDetailScreenState extends State<ProjectAdminDetailScreen> {
  late final ProjectAdminDetailController controller;
  final List<Worker> _workers = [];

  final sections = const [
    _ProjectSectionConfig('events', 'Événements', Icons.event_note_rounded),
    _ProjectSectionConfig('reserves', 'Réserves', Icons.report_problem_rounded),
    _ProjectSectionConfig(
      'referencePlans',
      'Plans de référence',
      Icons.map_rounded,
    ),
    _ProjectSectionConfig(
      'eventReports',
      'Rapports événement',
      Icons.description_rounded,
    ),
    _ProjectSectionConfig(
      'journal',
      'Journal de chantier',
      Icons.menu_book_rounded,
    ),
    _ProjectSectionConfig(
      'contractualDocuments',
      'Documents contractuels',
      Icons.gavel_rounded,
    ),
    _ProjectSectionConfig(
      'referenceDocuments',
      'Documents de référence',
      Icons.folder_copy_rounded,
    ),
    _ProjectSectionConfig('galleries', 'Galeries', Icons.photo_library_rounded),
    _ProjectSectionConfig(
      'stakeholders',
      'Parties prenantes / équipe chantier',
      Icons.groups_rounded,
    ),
    _ProjectSectionConfig(
      'archive',
      'Archivage du projet',
      Icons.archive_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    controller = Get.find<ProjectAdminDetailController>();
    _workers.addAll([
      ever(controller.isLoading, (_) => _refreshUi()),
      ever(controller.error, (_) => _refreshUi()),
      ever(controller.project, (_) => _refreshUi()),
      ever(controller.sections, (_) => _refreshUi()),
      ever(controller.counts, (_) => _refreshUi()),
      ever(controller.sectionLoading, (_) => _refreshUi()),
      ever(controller.activeSection, (_) => _refreshUi()),
    ]);
    final id = int.tryParse(Get.parameters['id'] ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (id != null) {
        controller.load(id);
      } else {
        controller.error.value = 'Projet introuvable.';
      }
    });
  }

  @override
  void dispose() {
    for (final worker in _workers) {
      worker.dispose();
    }
    super.dispose();
  }

  void _refreshUi() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(child: SafeArea(child: _buildBody()));
  }

  Widget _buildBody() {
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.error.value.isNotEmpty) {
      return _ErrorState(
        message: controller.error.value,
        onRetry: () {
          final id = controller.projectId;
          if (id != null) controller.load(id);
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final id = controller.projectId;
        if (id != null) await controller.load(id);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        children: [
          _Header(controller: controller),
          const SizedBox(height: 8),
          _SummaryGrid(controller: controller, sections: sections),
          const SizedBox(height: 10),
          _ProjectQuickOverview(controller: controller),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller});

  final ProjectAdminDetailController controller;

  @override
  Widget build(BuildContext context) {
    final project = controller.project;
    final isArchived = project['isActive'] == false;
    final membersCount = controller.countFor('stakeholders');
    final chefProjet = _projectManagerName(controller);
    final metaItems = [
      _ProjectMetaItem(
        icon: Icons.payments_outlined,
        label: 'Budget',
        value: _formatMoney(project['budget']),
      ),
      _ProjectMetaItem(
        icon: Icons.calendar_today_rounded,
        label: 'Date de début',
        value: _formatDateOnly(project['startDate']),
      ),
      _ProjectMetaItem(
        icon: Icons.event_available_rounded,
        label: 'Date de fin',
        value: _formatDateOnly(project['endDate']),
      ),
      _ProjectMetaItem(
        icon: Icons.engineering_rounded,
        label: 'Chef de projet',
        value: chefProjet,
      ),
      _ProjectMetaItem(
        icon: Icons.groups_rounded,
        label: 'Nombre de membres',
        value: '$membersCount',
      ),
      _ProjectMetaItem(
        icon: Icons.location_on_outlined,
        label: 'Localisation',
        value: _text(project['localisation'], fallback: 'Non renseignee'),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 620;
              final actions = Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: compact ? WrapAlignment.start : WrapAlignment.end,
                children: [
                  _StatusPill(
                    label: isArchived ? 'Archive' : 'Actif',
                    color: isArchived
                        ? const Color(0xFF64748B)
                        : const Color(0xFF16A34A),
                  ),
                  FilledButton.icon(
                    onPressed: () =>
                        _runAction(context, controller.archiveProject),
                    icon: const Icon(Icons.archive_outlined, size: 17),
                    label: const Text('Archiver'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              );
              final titleRow = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _IconAction(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Retour aux projets',
                    onPressed: () => Get.offNamed('/projects'),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.work_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _text(project['name'], fallback: 'Projet'),
                          maxLines: compact ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: compact ? 19 : 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _text(
                            project['description'],
                            fallback: 'Vue administrative du projet',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [titleRow, const SizedBox(height: 12), actions],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: titleRow),
                  const SizedBox(width: 12),
                  actions,
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          _GeneralInfoCard(items: metaItems),
        ],
      ),
    );
  }
}

class _ProjectMetaItem {
  const _ProjectMetaItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _GeneralInfoCard extends StatelessWidget {
  const _GeneralInfoCard({required this.items});

  final List<_ProjectMetaItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SectionIcon(
                icon: Icons.info_outline_rounded,
                size: 30,
                iconSize: 16,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Informations générales',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 920
                  ? 3
                  : constraints.maxWidth > 560
                      ? 2
                      : 1;
              final spacing = columns == 1 ? 8.0 : 12.0;
              final itemWidth = columns == 1
                  ? constraints.maxWidth
                  : _gridItemWidth(constraints.maxWidth, columns, spacing);

              return Wrap(
                spacing: spacing,
                runSpacing: 10,
                children: [
                  for (final item in items)
                    SizedBox(
                      width: itemWidth,
                      child: _GeneralInfoItem(item: item),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GeneralInfoItem extends StatelessWidget {
  const _GeneralInfoItem({required this.item});

  final _ProjectMetaItem item;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(item.icon, size: 16, color: AppColors.primaryColor),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.controller, required this.sections});

  final ProjectAdminDetailController controller;
  final List<_ProjectSectionConfig> sections;

  @override
  Widget build(BuildContext context) {
    final moduleCards = [
      _ProjectModuleCardData(
        config: _sectionFor('events'),
        count: controller.countFor('events'),
        helper: 'Suivi terrain',
      ),
      _ProjectModuleCardData(
        config: _sectionFor('referencePlans'),
        count: controller.countFor('referencePlans'),
        helper: 'Plans et reperes',
      ),
      _ProjectModuleCardData(
        config: const _ProjectSectionConfig(
          'documents',
          'Documents',
          Icons.folder_copy_rounded,
        ),
        count: _documentsTotal(controller),
        helper: 'Fichiers projet',
      ),
      _ProjectModuleCardData(
        config: _sectionFor('galleries'),
        count: controller.countFor('galleries'),
        helper: 'Photos et medias',
      ),
      _ProjectModuleCardData(
        config: _sectionFor('eventReports'),
        count: controller.countFor('eventReports'),
        helper: 'PV et comptes rendus',
      ),
      _ProjectModuleCardData(
        config: _sectionFor('stakeholders'),
        count: controller.countFor('stakeholders'),
        helper: 'Equipe chantier',
      ),
      _ProjectModuleCardData(
        config: const _ProjectSectionConfig(
          'activities',
          'Activites de controle',
          Icons.fact_check_rounded,
        ),
        count: _activitiesControlCount(controller),
        helper: 'Controle qualite',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PrimaryKpiGrid(
          items: [
            _ProjectKpiData(
              title: 'Lots',
              value: _lotsCount(controller),
              icon: Icons.layers_outlined,
              tone: const Color(0xFFF97316),
              subtitle: 'Lots associes',
              onTap: () => Get.toNamed('/lots'),
            ),
            _ProjectKpiData(
              title: 'Activites',
              value: _activitiesCount(controller),
              icon: Icons.task_alt_rounded,
              tone: const Color(0xFF2563EB),
              subtitle: 'Taches planifiees',
              onTap: () => Get.toNamed('/tasks'),
            ),
            _ProjectKpiData(
              title: 'Reserves',
              value: controller.countFor('reserves'),
              icon: Icons.report_problem_rounded,
              tone: const Color(0xFFDC2626),
              subtitle: 'Points ouverts',
              onTap: () => _openProjectSectionList(
                controller,
                _sectionFor('reserves'),
              ),
            ),
            _ProjectKpiData(
              title: 'Journaux',
              value: controller.countFor('journal'),
              icon: Icons.menu_book_rounded,
              tone: const Color(0xFF16A34A),
              subtitle: 'Journaux chantier',
              onTap: () => _openProjectSectionList(
                controller,
                _sectionFor('journal'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ProjectModulesPanel(
          modules: moduleCards,
          onOpen: (config) => _openProjectSectionList(controller, config),
        ),
      ],
    );
  }

  _ProjectSectionConfig _sectionFor(String key) {
    return sections.firstWhere(
      (section) => section.key == key,
      orElse: () => _fallbackSectionFor(key),
    );
  }
}

class _ProjectKpiData {
  const _ProjectKpiData({
    required this.title,
    required this.value,
    required this.icon,
    required this.tone,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final int value;
  final IconData icon;
  final Color tone;
  final String subtitle;
  final VoidCallback onTap;
}

class _PrimaryKpiGrid extends StatelessWidget {
  const _PrimaryKpiGrid({required this.items});

  final List<_ProjectKpiData> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 980
            ? 4
            : constraints.maxWidth > 620
                ? 2
                : 1;
        final spacing = columns == 1 ? 8.0 : 10.0;
        final width = columns == 1
            ? constraints.maxWidth
            : _gridItemWidth(constraints.maxWidth, columns, spacing);

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: _PrimaryKpiCard(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _PrimaryKpiCard extends StatefulWidget {
  const _PrimaryKpiCard({required this.item});

  final _ProjectKpiData item;

  @override
  State<_PrimaryKpiCard> createState() => _PrimaryKpiCardState();
}

class _PrimaryKpiCardState extends State<_PrimaryKpiCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.item.onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          height: 96,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovered
                  ? widget.item.tone.withValues(alpha: 0.34)
                  : colors.outlineVariant,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(
                  alpha: _hovered ? 0.08 : 0.04,
                ),
                blurRadius: _hovered ? 18 : 12,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.item.tone.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    Icon(widget.item.icon, color: widget.item.tone, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${widget.item.value}',
                style: GoogleFonts.inter(
                  fontSize: 27,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectModuleCardData {
  const _ProjectModuleCardData({
    required this.config,
    required this.count,
    required this.helper,
  });

  final _ProjectSectionConfig config;
  final int count;
  final String helper;
}

class _ProjectModulesPanel extends StatelessWidget {
  const _ProjectModulesPanel({required this.modules, required this.onOpen});

  final List<_ProjectModuleCardData> modules;
  final ValueChanged<_ProjectSectionConfig> onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _panelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SectionIcon(
                icon: Icons.dashboard_customize_outlined,
                size: 32,
                iconSize: 17,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Modules du projet',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Acces rapide aux donnees detaillees',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 1060
                  ? 4
                  : constraints.maxWidth > 760
                      ? 3
                      : constraints.maxWidth > 480
                          ? 2
                          : 1;
              final spacing = columns == 1 ? 8.0 : 10.0;
              final width = columns == 1
                  ? constraints.maxWidth
                  : _gridItemWidth(constraints.maxWidth, columns, spacing);

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final module in modules)
                    SizedBox(
                      width: width,
                      child: _CompactModuleCard(
                        module: module,
                        onTap: () => onOpen(module.config),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CompactModuleCard extends StatefulWidget {
  const _CompactModuleCard({required this.module, required this.onTap});

  final _ProjectModuleCardData module;
  final VoidCallback onTap;

  @override
  State<_CompactModuleCard> createState() => _CompactModuleCardState();
}

class _CompactModuleCardState extends State<_CompactModuleCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 74,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.primaryColor.withValues(alpha: 0.045)
                : colors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovered
                  ? AppColors.primaryColor.withValues(alpha: 0.26)
                  : colors.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              _SectionIcon(
                icon: widget.module.config.icon,
                size: 34,
                iconSize: 17,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.module.config.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.module.helper,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(minWidth: 34),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${widget.module.count}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectQuickOverview extends StatelessWidget {
  const _ProjectQuickOverview({required this.controller});

  final ProjectAdminDetailController controller;

  @override
  Widget build(BuildContext context) {
    final events = controller.listFor('events');
    final reserves = controller.listFor('reserves');
    final journals = controller.listFor('journal');
    final recentActivities = _recentActivities(controller);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vue rapide du projet',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 1100
                ? 3
                : constraints.maxWidth > 720
                    ? 2
                    : 1;

            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: _responsiveCardWidth(constraints.maxWidth, columns),
                  height: 226,
                  child: _QuickListCard(
                    title: 'Derniers evenements',
                    icon: Icons.event_note_rounded,
                    items: events,
                    onAdd: () => _handleCreate(
                      context,
                      controller,
                      const _ProjectSectionConfig(
                        'events',
                        'Evenements',
                        Icons.event_note_rounded,
                      ),
                    ),
                    onOpenAll: () => _openProjectSectionList(
                      controller,
                      const _ProjectSectionConfig(
                        'events',
                        'Evenements',
                        Icons.event_note_rounded,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: _responsiveCardWidth(constraints.maxWidth, columns),
                  height: 226,
                  child: _QuickListCard(
                    title: 'Dernieres reserves',
                    icon: Icons.report_problem_rounded,
                    items: reserves,
                    onAdd: () => _handleCreate(
                      context,
                      controller,
                      const _ProjectSectionConfig(
                        'reserves',
                        'Reserves',
                        Icons.report_problem_rounded,
                      ),
                    ),
                    onOpenAll: () => _openProjectSectionList(
                      controller,
                      const _ProjectSectionConfig(
                        'reserves',
                        'Reserves',
                        Icons.report_problem_rounded,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: _responsiveCardWidth(constraints.maxWidth, columns),
                  height: 226,
                  child: _QuickListCard(
                    title: 'Derniers journaux de chantier',
                    icon: Icons.menu_book_rounded,
                    items: journals,
                    onAdd: () => _handleCreate(
                      context,
                      controller,
                      const _ProjectSectionConfig(
                        'journal',
                        'Journal de chantier',
                        Icons.menu_book_rounded,
                      ),
                    ),
                    onOpenAll: () => _openProjectSectionList(
                      controller,
                      const _ProjectSectionConfig(
                        'journal',
                        'Journal de chantier',
                        Icons.menu_book_rounded,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        if (recentActivities.isNotEmpty) ...[
          const SizedBox(height: 8),
          _RecentActivityCard(activities: recentActivities),
        ],
      ],
    );
  }

  List<_RecentActivity> _recentActivities(
    ProjectAdminDetailController controller,
  ) {
    final activities = <_RecentActivity>[
      ...controller.listFor('events').whereType<Map<String, dynamic>>().map(
            (item) => _RecentActivity(
              icon: Icons.event_note_rounded,
              action: 'Evenement cree',
              user: _userFrom(item),
              subtitle: _titleFrom(item),
              dateText: _dateText(item),
            ),
          ),
      ...controller.listFor('reserves').whereType<Map<String, dynamic>>().map(
            (item) => _RecentActivity(
              icon: Icons.report_problem_rounded,
              action: 'Reserve ajoutee',
              user: _userFrom(item),
              subtitle: _titleFrom(item),
              dateText: _dateText(item),
            ),
          ),
      ...controller.listFor('journal').whereType<Map<String, dynamic>>().map(
            (item) => _RecentActivity(
              icon: Icons.menu_book_rounded,
              action: 'Journal cree',
              user: _userFrom(item),
              subtitle: _titleFrom(item),
              dateText: _dateText(item),
            ),
          ),
      ..._documentItems(controller).map(
        (item) => _RecentActivity(
          icon: Icons.insert_drive_file_outlined,
          action: 'Document televerse',
          user: _userFrom(item),
          subtitle: _titleFrom(item),
          dateText: _dateText(item),
        ),
      ),
    ];

    activities.sort((a, b) {
      final aDate = DateTime.tryParse(a.dateText);
      final bDate = DateTime.tryParse(b.dateText);
      if (aDate == null || bDate == null) return 0;
      return bDate.compareTo(aDate);
    });

    return activities.take(5).toList();
  }

  List<Map<String, dynamic>> _documentItems(
    ProjectAdminDetailController controller,
  ) {
    return [
      ...controller.listFor('referencePlans'),
      ...controller.listFor('contractualDocuments'),
      ...controller.listFor('referenceDocuments'),
      ...controller.listFor('galleries'),
    ].whereType<Map<String, dynamic>>().toList();
  }
}

class _QuickListCard extends StatelessWidget {
  const _QuickListCard({
    required this.title,
    required this.icon,
    required this.items,
    required this.onAdd,
    required this.onOpenAll,
  });

  final String title;
  final IconData icon;
  final List<dynamic> items;
  final VoidCallback onAdd;
  final VoidCallback onOpenAll;

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: _panelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SectionIcon(icon: icon, size: 30, iconSize: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              TextButton(onPressed: onOpenAll, child: const Text('Voir tout')),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: visibleItems.isEmpty
                ? Center(
                    child: _CompactEmptyState(
                      icon: icon,
                      message: _emptyMessageForTitle(title),
                      buttonLabel: _addLabelForTitle(title),
                      onAdd: onAdd,
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int index = 0;
                          index < visibleItems.length;
                          index++) ...[
                        _QuickListItem(
                          title: _titleFrom(
                            visibleItems[index] is Map<String, dynamic>
                                ? visibleItems[index] as Map<String, dynamic>
                                : <String, dynamic>{},
                          ),
                          subtitle: _subtitleFrom(
                            visibleItems[index] is Map<String, dynamic>
                                ? visibleItems[index] as Map<String, dynamic>
                                : <String, dynamic>{},
                          ),
                          icon: icon,
                        ),
                        if (index < visibleItems.length - 1)
                          const SizedBox(height: 5),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _QuickListItem extends StatelessWidget {
  const _QuickListItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primaryColor, size: 15),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompactEmptyState extends StatelessWidget {
  const _CompactEmptyState({
    required this.icon,
    required this.message,
    required this.buttonLabel,
    required this.onAdd,
  });

  final IconData icon;
  final String message;
  final String buttonLabel;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final messageBlock = Row(
          children: [
            _SectionIcon(icon: icon, size: 30, iconSize: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        );
        final action = OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded, size: 15),
          label: Text(buttonLabel),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            side: BorderSide(color: AppColors.primaryColor.withOpacity(0.26)),
          ),
        );

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceVariant.withOpacity(0.55),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [messageBlock, const SizedBox(height: 10), action],
                )
              : Row(
                  children: [
                    Expanded(child: messageBlock),
                    const SizedBox(width: 10),
                    action,
                  ],
                ),
        );
      },
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.activities});

  final List<_RecentActivity> activities;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: _panelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _SectionIcon(
                  icon: Icons.timeline_rounded, size: 30, iconSize: 16),
              const SizedBox(width: 8),
              Text(
                'Activite recente',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: activities.length,
              separatorBuilder: (_, __) => Divider(
                height: 8,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              itemBuilder: (context, index) =>
                  _RecentActivityItem(activity: activities[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentActivityItem extends StatelessWidget {
  const _RecentActivityItem({required this.activity});

  final _RecentActivity activity;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(activity.icon, color: AppColors.primaryColor, size: 15),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.action,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 2,
                children: [
                  Text(
                    activity.user,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    _displayActivityDate(activity.dateText),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  Text(
                    activity.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecentActivity {
  const _RecentActivity({
    required this.icon,
    required this.action,
    required this.user,
    required this.subtitle,
    required this.dateText,
  });

  final IconData icon;
  final String action;
  final String user;
  final String subtitle;
  final String dateText;
}

class _ProjectSection extends StatelessWidget {
  const _ProjectSection({required this.config, required this.controller});

  final _ProjectSectionConfig config;
  final ProjectAdminDetailController controller;

  @override
  Widget build(BuildContext context) {
    final items = controller.listFor(config.key);
    final isBusy = controller.sectionLoading[config.key] == true;
    final archive = config.key == 'archive'
        ? controller.sections['archive'] as Map<String, dynamic>?
        : null;

    return Container(
      decoration: _panelDecoration(context),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: ValueKey('${config.key}-${controller.activeSection.value}'),
          initiallyExpanded: controller.activeSection.value == config.key ||
              config.key == 'events' ||
              config.key == 'reserves',
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          leading: _SectionIcon(icon: config.icon),
          title: Text(
            config.title,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isBusy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                _StatusPill(
                  label: config.key == 'archive'
                      ? (archive?['archived'] == true ? 'Archive' : 'Actif')
                      : '${items.length}',
                  color: AppColors.primaryColor,
                ),
              if (controller.canUpload(config.key)) ...[
                const SizedBox(width: 8),
                _IconAction(
                  icon: Icons.add_rounded,
                  tooltip: 'Ajouter',
                  onPressed: () => _runAction(
                    context,
                    () => controller.uploadDocument(config.key),
                  ),
                ),
              ],
            ],
          ),
          children: [
            if (config.key == 'archive')
              _ArchiveBody(controller: controller)
            else if (items.isEmpty)
              _EmptySection(
                icon: config.icon,
                title: config.title,
                buttonLabel: _addLabelForSection(config),
                onAdd: controller.canCreate(config.key)
                    ? () => _handleCreate(context, controller, config)
                    : null,
              )
            else
              _SectionItemsLayout(
                items: items,
                sectionKey: config.key,
                config: config,
                controller: controller,
                isAdmin: true,
                maxItems: 6,
                compact: true,
              ),
            if (items.length > 6)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+ ${items.length - 6} autre(s) element(s)',
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProjectSectionListScreen extends StatelessWidget {
  const _ProjectSectionListScreen({
    super.key,
    required this.config,
    required this.controller,
  });

  final _ProjectSectionConfig config;
  final ProjectAdminDetailController controller;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      child: SafeArea(
        child: Obx(() {
          final items = controller.listFor(config.key);
          final isBusy = controller.sectionLoading[config.key] == true;
          final isAdmin =
              Get.find<AuthController>().currentUser.value?.isAdmin ?? false;

          return RefreshIndicator(
            onRefresh: () => controller.refreshSection(config.key),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                _SectionListHeader(
                  config: config,
                  count: items.length,
                  isBusy: isBusy,
                  canCreate: isAdmin && controller.canCreate(config.key),
                  onBack: Get.back,
                  onRefresh: () => controller.refreshSection(config.key),
                  onCreate: () => _handleCreate(context, controller, config),
                ),
                const SizedBox(height: 12),
                if (config.key == 'archive')
                  _ArchiveBody(controller: controller)
                else if (items.isEmpty)
                  _EmptySection(
                    icon: config.icon,
                    title: config.title,
                    buttonLabel: _addLabelForSection(config),
                    onAdd: isAdmin && controller.canCreate(config.key)
                        ? () => _handleCreate(context, controller, config)
                        : null,
                  )
                else
                  Column(
                    children: [
                      _SectionDigest(
                        config: config,
                        items: items,
                      ),
                      const SizedBox(height: 12),
                      _SectionItemsLayout(
                        items: items,
                        sectionKey: config.key,
                        config: config,
                        controller: controller,
                        isAdmin: isAdmin,
                      ),
                    ],
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _SectionListHeader extends StatelessWidget {
  const _SectionListHeader({
    required this.config,
    required this.count,
    required this.isBusy,
    required this.canCreate,
    required this.onBack,
    required this.onRefresh,
    required this.onCreate,
  });

  final _ProjectSectionConfig config;
  final int count;
  final bool isBusy;
  final bool canCreate;
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final titleBlock = Row(
          children: [
            _IconAction(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Retour',
              onPressed: onBack,
            ),
            const SizedBox(width: 12),
            _SectionIcon(icon: config.icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.title,
                    maxLines: compact ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: compact ? 18 : 20,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$count element(s)',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        final actions = Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [
            if (isBusy)
              const SizedBox(
                width: 34,
                height: 34,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              _IconAction(
                icon: Icons.refresh_rounded,
                tooltip: 'Actualiser',
                onPressed: onRefresh,
              ),
            if (canCreate)
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Ajouter'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
          ],
        );

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: _panelDecoration(context),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    titleBlock,
                    const SizedBox(height: 12),
                    Align(alignment: Alignment.centerRight, child: actions),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: titleBlock),
                    const SizedBox(width: 12),
                    actions,
                  ],
                ),
        );
      },
    );
  }
}

void _openProjectSectionList(
  ProjectAdminDetailController controller,
  _ProjectSectionConfig section,
) {
  Get.to(
    () => _ProjectSectionListScreen(config: section, controller: controller),
  );
}

void _handleCreate(
  BuildContext context,
  ProjectAdminDetailController controller,
  _ProjectSectionConfig config,
) {
  if (controller.canUpload(config.key)) {
    _runAction(context, () => controller.uploadDocument(config.key));
    return;
  }

  if (config.key == 'stakeholders') {
    _showInviteStakeholderDialog(context, controller);
    return;
  }

  _showAdminFormDialog(
    context: context,
    title: 'Ajouter - ${config.title}',
    fields: controller.fieldsFor(config.key),
    onSubmit: (values) => controller.createItem(config.key, values),
  );
}

void _showInviteStakeholderDialog(
  BuildContext context,
  ProjectAdminDetailController controller,
) {
  controller.loadCompanyUsers();

  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620, maxHeight: 620),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Obx(() {
              if (controller.isLoadingCompanyUsers.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final users = controller.companyUsers;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _SectionIcon(icon: Icons.group_add_rounded),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Inviter un membre',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: users.isEmpty
                        ? Center(
                            child: Text(
                              'Aucun utilisateur disponible dans la société.',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: users.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final user = users[index];
                              final name =
                                  '${_text(user['firstname'])} ${_text(user['lastname'])}'
                                      .trim();
                              final email = _text(user['email']);

                              return InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () async {
                                  await controller.inviteStakeholderUser(user);
                                  if (dialogContext.mounted) {
                                    Navigator.of(dialogContext).pop();
                                  }
                                  Get.snackbar(
                                    'Succès',
                                    'Invitation envoyée avec succès',
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outlineVariant,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: AppColors.primaryColor
                                            .withOpacity(0.12),
                                        child: Text(
                                          name.isNotEmpty
                                              ? name[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            color: AppColors.primaryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name.isEmpty
                                                  ? 'Utilisateur'
                                                  : name,
                                              style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            Text(
                                              email,
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      FilledButton.icon(
                                        onPressed: () async {
                                          await controller
                                              .inviteStakeholderUser(user);
                                          if (dialogContext.mounted) {
                                            Navigator.of(dialogContext).pop();
                                          }
                                          Get.snackbar(
                                            'Succès',
                                            'Invitation envoyée avec succès',
                                            snackPosition: SnackPosition.BOTTOM,
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.send_rounded,
                                          size: 16,
                                        ),
                                        label: const Text('Inviter'),
                                        style: FilledButton.styleFrom(
                                          backgroundColor:
                                              AppColors.primaryColor,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            }),
          ),
        ),
      );
    },
  );
}

void _handleEdit(
  BuildContext context,
  ProjectAdminDetailController controller,
  _ProjectSectionConfig config,
  Map<String, dynamic> item,
) {
  _showAdminFormDialog(
    context: context,
    title: 'Modifier - ${config.title}',
    fields: controller.fieldsFor(config.key, item: item),
    onSubmit: (values) => controller.updateItem(config.key, item, values),
  );
}

void _showAdminFormDialog({
  required BuildContext context,
  required String title,
  required List<ProjectAdminField> fields,
  required Future<void> Function(Map<String, dynamic> values) onSubmit,
}) {
  final controllers = {
    for (final field in fields)
      field.key: TextEditingController(text: field.value ?? ''),
  };
  var isSaving = false;

  showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: Theme.of(dialogContext).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              Future<void> submit() async {
                if (isSaving) return;
                setDialogState(() => isSaving = true);
                final values = {
                  for (final entry in controllers.entries)
                    entry.key: entry.value.text.trim(),
                };
                try {
                  await onSubmit(values);
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                  Get.snackbar(
                    'Succes',
                    'Action effectuee',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                } catch (e) {
                  Get.snackbar(
                    'Erreur',
                    '$e',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                } finally {
                  if (dialogContext.mounted) {
                    setDialogState(() => isSaving = false);
                  }
                }
              }

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _SectionIcon(icon: Icons.edit_rounded),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(Icons.close_rounded, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    ...fields.map(
                      (field) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextField(
                          controller: controllers[field.key],
                          maxLines: field.maxLines,
                          decoration: InputDecoration(
                            labelText: field.label,
                            filled: true,
                            fillColor: Theme.of(
                              context,
                            ).colorScheme.surfaceVariant,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outlineVariant,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppColors.primaryColor,
                                width: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isSaving
                              ? null
                              : () => Navigator.of(dialogContext).pop(),
                          child: const Text('Annuler'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: isSaving ? null : submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Enregistrer'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ),
  ).whenComplete(() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
  });
}

class _ArchiveBody extends StatelessWidget {
  const _ArchiveBody({required this.controller});

  final ProjectAdminDetailController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'L administrateur peut archiver ce projet sans dependre des permissions d invitation.',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: () => _runAction(context, controller.archiveProject),
          icon: const Icon(Icons.archive_outlined, size: 18),
          label: const Text('Archiver le projet'),
        ),
      ],
    );
  }
}

class _SectionDigest extends StatelessWidget {
  const _SectionDigest({
    required this.config,
    required this.items,
  });

  final _ProjectSectionConfig config;
  final List<dynamic> items;

  @override
  Widget build(BuildContext context) {
    final maps = items.whereType<Map<String, dynamic>>().toList();
    final latest = _latestItem(maps);
    final latestDate =
        latest == null ? 'Non renseigne' : _bestDisplayDate(latest, config.key);
    final latestAuthor = latest == null ? 'Utilisateur' : _userFrom(latest);
    final typeLabel = latest == null
        ? _moduleTypeLabel(config.key, config.title, null)
        : _moduleTypeLabel(config.key, config.title, latest);

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 960
            ? 4
            : constraints.maxWidth > 640
                ? 2
                : 1;
        final spacing = columns == 1 ? 8.0 : 10.0;
        final width = columns == 1
            ? constraints.maxWidth
            : _gridItemWidth(
                constraints.maxWidth,
                columns,
                spacing,
              );

        final tiles = [
          _DigestTile(
            icon: config.icon,
            label: 'Elements',
            value: '${items.length}',
          ),
          _DigestTile(
            icon: Icons.schedule_rounded,
            label: 'Derniere mise a jour',
            value: latestDate,
          ),
          _DigestTile(
            icon: Icons.person_outline_rounded,
            label: 'Auteur recent',
            value: latestAuthor,
          ),
          _DigestTile(
            icon: Icons.category_outlined,
            label: 'Type',
            value: typeLabel,
          ),
        ];

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final tile in tiles) SizedBox(width: width, child: tile),
          ],
        );
      },
    );
  }
}

class _DigestTile extends StatelessWidget {
  const _DigestTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          _SectionIcon(icon: icon, size: 30, iconSize: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
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

class _SectionItemsLayout extends StatelessWidget {
  const _SectionItemsLayout({
    required this.items,
    required this.sectionKey,
    required this.config,
    required this.controller,
    required this.isAdmin,
    this.maxItems,
    this.compact = false,
  });

  final List<dynamic> items;
  final String sectionKey;
  final _ProjectSectionConfig config;
  final ProjectAdminDetailController controller;
  final bool isAdmin;
  final int? maxItems;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final visibleItems =
        maxItems == null ? items : items.take(maxItems!).toList();
    if (visibleItems.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = compact ? 8.0 : 12.0;
        final columns = _sectionCardColumns(
          constraints.maxWidth,
          visibleItems.length,
          compact: compact,
        );
        final width = columns == 1
            ? constraints.maxWidth
            : _gridItemWidth(constraints.maxWidth, columns, spacing);

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in visibleItems)
              SizedBox(
                width: width,
                child: _DataRow(
                  item: item,
                  sectionKey: sectionKey,
                  config: config,
                  controller: controller,
                  isAdmin: isAdmin,
                  compact: compact,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.item,
    required this.sectionKey,
    required this.config,
    required this.controller,
    required this.isAdmin,
    this.compact = false,
  });

  final dynamic item;
  final String sectionKey;
  final _ProjectSectionConfig config;
  final ProjectAdminDetailController controller;
  final bool isAdmin;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final map = item is Map<String, dynamic>
        ? item as Map<String, dynamic>
        : <String, dynamic>{};
    final title = _titleFrom(map);
    final subtitle = _subtitleFrom(map);
    final isDocument = controller.isDocumentSection(sectionKey);
    final metaItems = _moduleMetaItems(
      map,
      sectionKey,
      config.title,
      isDocument: isDocument,
    );
    final actions = <Widget>[
      if (isAdmin)
        _IconAction(
          icon: Icons.visibility_outlined,
          tooltip: 'Voir detail',
          onPressed: () => _showDetailDialog(
            context,
            title,
            map,
            sectionKey: sectionKey,
          ),
        ),
      if (isAdmin && controller.canDownload(sectionKey))
        _IconAction(
          icon: Icons.download_rounded,
          tooltip: 'Telecharger',
          onPressed: () =>
              _runAction(context, () => controller.openDocument(map)),
        ),
      if (isAdmin && controller.canEdit(sectionKey))
        _IconAction(
          icon: Icons.edit_rounded,
          tooltip: 'Modifier',
          onPressed: () => _handleEdit(context, controller, config, map),
        ),
      if (isAdmin && controller.canDelete(sectionKey))
        _IconAction(
          icon: Icons.delete_outline,
          tooltip: 'Supprimer',
          color: const Color(0xFFDC2626),
          onPressed: () => _confirmDelete(context, controller, sectionKey, map),
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = compact || constraints.maxWidth < 420;
        final actionBar = Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: WrapAlignment.end,
          children: actions,
        );

        return Container(
          padding: EdgeInsets.all(compact ? 12 : 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.045),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionIcon(
                    icon: _itemIconFor(sectionKey, map, config.icon),
                    size: 36,
                    iconSize: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: compact ? 13 : 14,
                            height: 1.16,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            maxLines: compact ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              height: 1.25,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!narrow && actions.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    actionBar,
                  ],
                ],
              ),
              if (metaItems.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final meta in metaItems) _MetaChip(meta: meta),
                  ],
                ),
              ],
              if (narrow && actions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerRight, child: actionBar),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.meta});

  final _ModuleMeta meta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(meta.icon, size: 13, color: AppColors.primaryColor),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              meta.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleMeta {
  const _ModuleMeta(this.icon, this.value);

  final IconData icon;
  final String value;
}

class _CountTile extends StatefulWidget {
  const _CountTile({
    required this.config,
    required this.count,
    required this.onTap,
  });

  final _ProjectSectionConfig config;
  final int count;
  final VoidCallback onTap;

  @override
  State<_CountTile> createState() => _CountTileState();
}

class _CountTileState extends State<_CountTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.primaryColor.withOpacity(0.045)
                : colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered
                  ? AppColors.primaryColor.withOpacity(0.24)
                  : colors.outlineVariant,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF0F172A,
                ).withOpacity(_hovered ? 0.08 : 0.045),
                blurRadius: _hovered ? 18 : 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              _SectionIcon(icon: widget.config.icon, size: 30, iconSize: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.config.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${widget.count}',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: colors.onSurface,
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

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        color: color ?? const Color(0xFF475569),
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints.tightFor(width: 34, height: 34),
        style: IconButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionIcon extends StatelessWidget {
  const _SectionIcon({required this.icon, this.size = 34, this.iconSize = 18});

  final IconData icon;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.10),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, size: iconSize, color: AppColors.primaryColor),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({
    required this.icon,
    required this.title,
    required this.buttonLabel,
    this.onAdd,
  });

  final IconData icon;
  final String title;
  final String buttonLabel;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final content = Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: AppColors.primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aucun ${title.toLowerCase()} disponible',
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ajoutez un premier element pour completer ce projet.',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
        final action = onAdd == null
            ? null
            : FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(buttonLabel),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    content,
                    if (action != null) ...[const SizedBox(height: 12), action],
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: content),
                    if (action != null) ...[const SizedBox(width: 12), action],
                  ],
                ),
        );
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Reessayer')),
        ],
      ),
    );
  }
}

class _ProjectSectionConfig {
  const _ProjectSectionConfig(this.key, this.title, this.icon);

  final String key;
  final String title;
  final IconData icon;
}

Future<void> _confirmDelete(
  BuildContext context,
  ProjectAdminDetailController controller,
  String sectionKey,
  Map<String, dynamic> item,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Supprimer'),
      content: const Text('Confirmer la suppression de cet element ?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
          ),
          child: const Text('Supprimer'),
        ),
      ],
    ),
  );

  if (confirmed == true && context.mounted) {
    await _runAction(context, () => controller.deleteItem(sectionKey, item));
  }
}

void _showDetailDialog(
  BuildContext context,
  String title,
  Map<String, dynamic> item, {
  required String sectionKey,
}) {
  if (sectionKey == 'events') {
    _showEventDetailDialog(context, item);
    return;
  }
  final visibleEntries = _visibleDetailEntries(item);

  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: visibleEntries
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _EventInfoRow(
                      label: _labelizeKey(entry.key),
                      value: _displayDetailValue(entry.value),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    ),
  );
}

void _showEventDetailDialog(BuildContext context, Map<String, dynamic> event) {
  final eventTitle = _text(
    event['title'] ?? event['name'] ?? event['nom'],
    fallback: 'Evenement',
  );
  final activities = _eventActivities(event);

  showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: Theme.of(dialogContext).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _SectionIcon(icon: Icons.event_note_rounded),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        eventTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: const Color(0xFF94A3B8),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Divider(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  height: 1,
                ),
                const SizedBox(height: 18),
                _EventInfoRow(
                  label: 'Description',
                  value: _cleanValue(event['description']),
                ),
                _EventInfoRow(
                  label: 'Date',
                  value: _formatDateOnly(event['date']),
                ),
                _EventInfoRow(
                  label: 'Heure debut',
                  value: _cleanValue(event['startHour'] ?? event['heureDebut']),
                ),
                _EventInfoRow(
                  label: 'Heure fin',
                  value: _cleanValue(event['endHour'] ?? event['heureFin']),
                ),
                _EventInfoRow(label: 'Zone', value: _cleanValue(event['zone'])),
                _EventInfoRow(label: 'Projet', value: _eventProjectName(event)),
                const SizedBox(height: 18),
                Text(
                  'Activites concernees',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                if (activities.isEmpty)
                  Text(
                    'Aucune activite renseignee',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  ...activities.map(
                    (activity) => _EventActivityCard(activity: activity),
                  ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Fermer'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _EventInfoRow extends StatelessWidget {
  const _EventInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventActivityCard extends StatelessWidget {
  const _EventActivityCard({required this.activity});

  final Map<String, dynamic> activity;

  @override
  Widget build(BuildContext context) {
    final title = _cleanValue(
      activity['name'] ?? activity['nom'] ?? activity['title'],
    );
    final description = _cleanValue(activity['description']);
    final zone = _cleanValue(activity['zone'] ?? activity['localisation']);
    final delay = _cleanValue(
      activity['delay'] ?? activity['delai'] ?? activity['deadline'],
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (zone != 'Non renseigne' || delay != 'Non renseigne') ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (zone != 'Non renseigne')
                  _StatusPill(
                    label: 'Zone: $zone',
                    color: AppColors.primaryColor,
                  ),
                if (delay != 'Non renseigne')
                  _StatusPill(
                    label: 'Delai: $delay',
                    color: const Color(0xFF64748B),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> _runAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
    Get.snackbar(
      'Succes',
      'Action effectuee',
      snackPosition: SnackPosition.BOTTOM,
    );
  } catch (e) {
    Get.snackbar('Erreur', '$e', snackPosition: SnackPosition.BOTTOM);
  }
}

BoxDecoration _panelDecoration(BuildContext context) => BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF94A3B8).withOpacity(0.08),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    );

double _responsiveCardWidth(double totalWidth, int columns) {
  final spacing = 10 * (columns - 1);
  return (totalWidth - spacing) / columns;
}

double _gridItemWidth(double totalWidth, int columns, double spacing) {
  if (columns <= 1) return totalWidth;
  return (totalWidth - spacing * (columns - 1)) / columns;
}

int _sectionCardColumns(
  double totalWidth,
  int itemCount, {
  required bool compact,
}) {
  var columns = totalWidth > 1180
      ? (compact ? 2 : 3)
      : totalWidth > 760
          ? 2
          : 1;

  if (itemCount > 0 && itemCount < columns) columns = itemCount;
  return columns < 1 ? 1 : columns;
}

IconData _itemIconFor(
  String sectionKey,
  Map<String, dynamic> item,
  IconData fallback,
) {
  if (sectionKey == 'galleries') return Icons.image_rounded;
  if (sectionKey == 'referencePlans') return Icons.map_rounded;
  if (sectionKey == 'contractualDocuments') return Icons.gavel_rounded;
  if (sectionKey == 'referenceDocuments') return Icons.folder_copy_rounded;
  if (sectionKey == 'eventReports') return Icons.description_rounded;
  if (sectionKey == 'journal') return Icons.menu_book_rounded;
  if (sectionKey == 'reserves') return Icons.report_problem_rounded;
  if (sectionKey == 'events') return Icons.event_note_rounded;
  if (sectionKey == 'stakeholders') return Icons.person_outline_rounded;

  final type = _fileTypeFrom(item, sectionKey).toLowerCase();
  if (type.contains('image') || type == 'png' || type == 'jpg') {
    return Icons.image_rounded;
  }
  if (type == 'pdf') return Icons.picture_as_pdf_rounded;
  return fallback;
}

List<_ModuleMeta> _moduleMetaItems(
  Map<String, dynamic> item,
  String sectionKey,
  String title, {
  required bool isDocument,
}) {
  final meta = <_ModuleMeta>[
    _ModuleMeta(
        Icons.category_outlined, _moduleTypeLabel(sectionKey, title, item)),
  ];

  final date = _bestDisplayDate(item, sectionKey);
  if (date != 'Non renseigne') {
    meta.add(_ModuleMeta(Icons.schedule_rounded, date));
  }

  final author = _userFrom(item);
  if (author != 'Utilisateur') {
    meta.add(_ModuleMeta(Icons.person_outline_rounded, author));
  }

  if (isDocument) {
    final type = _fileTypeFrom(item, sectionKey);
    if (type.isNotEmpty && type != meta.first.value) {
      meta.add(_ModuleMeta(Icons.description_outlined, type));
    }

    final size = _formatFileSize(_fileSizeValue(item));
    if (size.isNotEmpty) {
      meta.add(_ModuleMeta(Icons.storage_rounded, size));
    }
  } else {
    final status = _usableText(
      item['status'] ?? item['state'] ?? item['etat'] ?? item['isLocked'],
    );
    if (status.isNotEmpty) {
      meta.add(_ModuleMeta(Icons.flag_outlined, status));
    }

    final priority = _usableText(item['priority'] ?? item['priorite']);
    if (priority.isNotEmpty) {
      meta.add(_ModuleMeta(Icons.priority_high_rounded, priority));
    }

    final location = _usableText(
      item['localisation'] ?? item['location'] ?? item['zone'],
    );
    if (location.isNotEmpty) {
      meta.add(_ModuleMeta(Icons.place_outlined, location));
    }

    final role = _usableText(item['role'] ?? item['function']);
    if (role.isNotEmpty) {
      meta.add(_ModuleMeta(Icons.badge_outlined, role));
    }
  }

  return meta.take(5).toList();
}

Map<String, dynamic> _fileMapFrom(Map<String, dynamic> item) {
  final file = item['file'];
  if (file is Map<String, dynamic>) return file;
  return item;
}

dynamic _fileSizeValue(Map<String, dynamic> item) {
  final file = _fileMapFrom(item);
  return file['size'] ??
      file['fileSize'] ??
      file['sizeInBytes'] ??
      item['size'] ??
      item['fileSize'] ??
      item['bytes'];
}

String _formatFileSize(dynamic value) {
  final bytes = num.tryParse(_text(value));
  if (bytes == null || bytes <= 0) return '';
  if (bytes < 1024) return '${bytes.round()} o';

  final units = ['Ko', 'Mo', 'Go'];
  var size = bytes / 1024;
  var unitIndex = 0;

  while (size >= 1024 && unitIndex < units.length - 1) {
    size = size / 1024;
    unitIndex++;
  }

  final decimals = size >= 10 ? 0 : 1;
  return '${size.toStringAsFixed(decimals)} ${units[unitIndex]}';
}

String _fileTypeFrom(Map<String, dynamic> item, String sectionKey) {
  final file = _fileMapFrom(item);
  final mime =
      _usableText(file['mimeType'] ?? file['mimetype'] ?? item['mime']);
  if (mime.contains('/')) {
    return mime.split('/').last.toUpperCase();
  }

  final explicit = _usableText(file['type'] ?? item['type']);
  if (explicit.isNotEmpty) return explicit;

  final name = _usableText(
    file['name'] ?? file['path'] ?? item['name'] ?? item['path'],
  );
  final lastSegment = name.split('/').last.split('\\').last;
  final dotIndex = lastSegment.lastIndexOf('.');
  if (dotIndex != -1 && dotIndex < lastSegment.length - 1) {
    return lastSegment.substring(dotIndex + 1).toUpperCase();
  }

  if (sectionKey == 'galleries') return 'Image';
  if (sectionKey == 'referencePlans') return 'Plan';
  return 'Fichier';
}

String _moduleTypeLabel(
  String sectionKey,
  String title,
  Map<String, dynamic>? item,
) {
  if (item != null &&
      (sectionKey == 'referencePlans' ||
          sectionKey == 'contractualDocuments' ||
          sectionKey == 'referenceDocuments' ||
          sectionKey == 'galleries')) {
    return _fileTypeFrom(item, sectionKey);
  }

  switch (sectionKey) {
    case 'events':
      return 'Evenement';
    case 'reserves':
      return 'Reserve';
    case 'referencePlans':
      return 'Plan';
    case 'eventReports':
      return 'Rapport';
    case 'journal':
      return 'Journal';
    case 'contractualDocuments':
      return 'Document contractuel';
    case 'referenceDocuments':
      return 'Document reference';
    case 'galleries':
      return 'Galerie';
    case 'stakeholders':
      return 'Membre';
    default:
      return title;
  }
}

Map<String, dynamic>? _latestItem(List<Map<String, dynamic>> items) {
  if (items.isEmpty) return null;
  final sorted = [...items];
  sorted.sort((a, b) => _dateScore(b).compareTo(_dateScore(a)));
  return sorted.first;
}

int _dateScore(Map<String, dynamic> item) {
  final candidates = [
    item['updatedAt'],
    item['createdAt'],
    item['date'],
    item['dateCreated'],
    item['startDate'],
    item['endDate'],
  ];

  for (final candidate in candidates) {
    final parsed = DateTime.tryParse(_text(candidate));
    if (parsed != null) return parsed.millisecondsSinceEpoch;
  }
  return 0;
}

String _bestDisplayDate(Map<String, dynamic> item, String sectionKey) {
  if (sectionKey == 'journal') {
    final journalDate = _journalDateText(item);
    if (journalDate.isNotEmpty) return journalDate;
  }

  final candidates = [
    item['updatedAt'],
    item['createdAt'],
    item['date'],
    item['dateCreated'],
    item['startDate'],
    item['endDate'],
  ];

  for (final candidate in candidates) {
    final value = _usableText(candidate);
    if (value.isNotEmpty) return _formatDateOnly(value);
  }
  return 'Non renseigne';
}

String _journalDateText(Map<String, dynamic> item) {
  final day = int.tryParse(_text(item['jour']));
  final month = int.tryParse(_text(item['mois']));
  final year = int.tryParse(_text(item['annee']));
  if (day == null || month == null || year == null) return '';
  return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
}

String _usableText(dynamic value) {
  final text = _cleanValue(value);
  if (text == 'Non renseigne' || text == 'null') return '';
  return text;
}

String _formatMoney(dynamic value) {
  final amount = num.tryParse(_text(value));
  if (amount == null || amount == 0) return 'Non renseigne';
  final rounded = amount.round().toString();
  final buffer = StringBuffer();
  for (int i = 0; i < rounded.length; i++) {
    final remaining = rounded.length - i;
    buffer.write(rounded[i]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write(' ');
  }
  return '${buffer.toString()} TND';
}

String _projectManagerName(ProjectAdminDetailController controller) {
  final candidates =
      controller.listFor('stakeholders').whereType<Map<String, dynamic>>();

  for (final item in candidates) {
    final role = _text(
      item['role'] ?? item['function'] ?? item['status'],
    ).toLowerCase();
    if (role.contains('chef') ||
        role.contains('manager') ||
        role.contains('owner')) {
      final name = _userFrom(item);
      if (name != 'Utilisateur') return name;
    }
  }

  if (candidates.isNotEmpty) {
    final name = _userFrom(candidates.first);
    if (name != 'Utilisateur') return name;
  }

  return 'Non renseigne';
}

String _userFrom(Map<String, dynamic> item) {
  final user = item['user'] ?? item['createdBy'] ?? item['author'];
  if (user is Map<String, dynamic>) {
    final name = [
      _text(user['firstname'] ?? user['firstName']),
      _text(user['lastname'] ?? user['lastName']),
    ].where((part) => part.isNotEmpty).join(' ');
    if (name.isNotEmpty) return name;
    final email = _text(user['email']);
    if (email.isNotEmpty) return email;
  }

  final directName = _text(
    item['userName'] ?? item['createdByName'] ?? item['authorName'],
  );
  if (directName.isNotEmpty) return directName;

  return 'Utilisateur';
}

String _displayActivityDate(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return _cleanValue(value);
  return _formatDateOnly(value);
}

String _emptyMessageForTitle(String title) {
  final normalized = title.toLowerCase();
  if (normalized.contains('document')) return 'Aucun document disponible';
  if (normalized.contains('journal')) return 'Aucun journal disponible';
  if (normalized.contains('reserve')) return 'Aucune reserve disponible';
  if (normalized.contains('evenement')) return 'Aucun evenement disponible';
  return 'Aucun element disponible';
}

String _addLabelForTitle(String title) {
  final normalized = title.toLowerCase();
  if (normalized.contains('document')) return 'Ajouter un document';
  if (normalized.contains('journal')) return 'Ajouter un journal';
  if (normalized.contains('reserve')) return 'Ajouter une reserve';
  if (normalized.contains('evenement')) return 'Ajouter un evenement';
  return 'Ajouter';
}

String _addLabelForSection(_ProjectSectionConfig config) {
  return _addLabelForTitle(config.title);
}

String _text(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? fallback : text;
}

String _cleanValue(dynamic value) {
  final text = _text(value);
  return text.isEmpty || text == 'null' ? 'Non renseigne' : text;
}

List<MapEntry<String, dynamic>> _visibleDetailEntries(
  Map<String, dynamic> item,
) {
  const hiddenKeys = {
    'id',
    'userId',
    'projectId',
    'fileId',
    'folderId',
    'createdAt',
    'updatedAt',
    'eventUsers',
    'eventSections',
    'eventActivities',
    'pvs',
    'project',
    'user',
    'file',
  };

  return item.entries
      .where((entry) {
        if (hiddenKeys.contains(entry.key)) return false;
        if (entry.value is Map || entry.value is List) return false;
        return _text(entry.value).isNotEmpty;
      })
      .take(24)
      .toList();
}

String _displayDetailValue(dynamic value) {
  final text = _text(value);
  final parsed = DateTime.tryParse(text);
  if (parsed == null) return _cleanValue(value);

  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  final hour = parsed.hour.toString().padLeft(2, '0');
  final minute = parsed.minute.toString().padLeft(2, '0');
  return '$day/$month/${parsed.year} a $hour:$minute';
}

String _labelizeKey(String key) {
  final words = key
      .replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'),
        (match) => '${match.group(1)} ${match.group(2)}',
      )
      .replaceAll('_', ' ')
      .split(' ')
      .where((word) => word.trim().isNotEmpty)
      .toList();

  if (words.isEmpty) return key;
  return words
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

String _formatDateOnly(dynamic value) {
  final text = _text(value);
  if (text.isEmpty) return 'Non renseigne';

  final parsed = DateTime.tryParse(text);
  if (parsed == null) return text;

  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  return '$day/$month/${parsed.year}';
}

String _eventProjectName(Map<String, dynamic> event) {
  final project = event['project'];
  if (project is Map<String, dynamic>) {
    return _cleanValue(project['name'] ?? project['nom'] ?? project['title']);
  }
  return _cleanValue(event['projectName']);
}

List<Map<String, dynamic>> _eventActivities(Map<String, dynamic> event) {
  final rawActivities = event['eventActivities'];
  if (rawActivities is! List) return [];

  return rawActivities.whereType<Map<String, dynamic>>().map((entry) {
    final activity =
        _nestedMap(entry, ['activity', 'task', 'activite']) ?? entry;
    return <String, dynamic>{
      'name': activity['name'] ?? activity['nom'] ?? entry['name'],
      'title': activity['title'] ?? entry['title'],
      'description':
          activity['description'] ?? entry['description'] ?? entry['details'],
      'zone': activity['zone'] ?? entry['zone'] ?? entry['localisation'],
      'delay': activity['delay'] ??
          activity['delai'] ??
          activity['deadline'] ??
          entry['delay'] ??
          entry['delai'] ??
          entry['deadline'],
    };
  }).toList();
}

Map<String, dynamic>? _nestedMap(
  Map<String, dynamic> source,
  List<String> keys,
) {
  for (final key in keys) {
    final value = source[key];
    if (value is Map<String, dynamic>) return value;
  }
  return null;
}

String _titleFrom(Map<String, dynamic> map) {
  final file = map['file'];
  final fileMap = file is Map<String, dynamic> ? file : null;
  final direct = _text(
    map['title'] ??
        map['name'] ??
        map['nom'] ??
        fileMap?['name'] ??
        map['path'] ??
        map['status'] ??
        map['id'],
  );
  if (direct.isNotEmpty) return direct;

  final user = map['user'];
  if (user is Map<String, dynamic>) {
    return '${_text(user['firstname'])} ${_text(user['lastname'])}'.trim();
  }

  return 'Element';
}

String _subtitleFrom(Map<String, dynamic> map) {
  final file = map['file'];
  final fileMap = file is Map<String, dynamic> ? file : null;
  final values = [
    map['description'],
    map['declaration'],
    map['date'],
    map['createdAt'],
    map['role'],
    map['zone'],
    fileMap?['path'],
  ].map((value) => _text(value)).where((value) => value.isNotEmpty).toList();

  return values.take(2).join(' - ');
}

String _dateText(Map<String, dynamic> map) {
  return _text(
    map['createdAt'] ??
        map['updatedAt'] ??
        map['date'] ??
        map['dateCreated'] ??
        map['jour'],
  );
}

int _lotsCount(ProjectAdminDetailController controller) {
  final lots = controller.project['projectLots'];
  if (lots is List) return lots.length;
  final lots2 = controller.project['lots'];
  if (lots2 is List) return lots2.length;
  return 0;
}

int _activitiesCount(ProjectAdminDetailController controller) {
  final directCount = controller.countFor('activities');
  if (directCount > 0) return directCount;

  int total = 0;
  for (final event in controller.listFor('events')) {
    if (event is Map<String, dynamic>) {
      final activities = event['eventActivities'];
      if (activities is List) total += activities.length;
    }
  }
  return total;
}

int _activitiesControlCount(ProjectAdminDetailController controller) {
  final directCount = controller.countFor('activities');
  if (directCount > 0) return directCount;
  return controller.countFor('eventReports');
}

int _documentsTotal(ProjectAdminDetailController controller) {
  final directCount = controller.countFor('documents');
  if (directCount > 0) return directCount;
  return _documentsCount(controller);
}

int _documentsCount(ProjectAdminDetailController controller) {
  return controller.countFor('referencePlans') +
      controller.countFor('contractualDocuments') +
      controller.countFor('referenceDocuments') +
      controller.countFor('galleries');
}

_ProjectSectionConfig _fallbackSectionFor(String key) {
  switch (key) {
    case 'events':
      return const _ProjectSectionConfig(
        'events',
        'Evenements',
        Icons.event_note_rounded,
      );
    case 'reserves':
      return const _ProjectSectionConfig(
        'reserves',
        'Reserves',
        Icons.report_problem_rounded,
      );
    case 'referencePlans':
      return const _ProjectSectionConfig(
        'referencePlans',
        'Plans de reference',
        Icons.map_rounded,
      );
    case 'eventReports':
      return const _ProjectSectionConfig(
        'eventReports',
        'Rapports',
        Icons.description_rounded,
      );
    case 'journal':
      return const _ProjectSectionConfig(
        'journal',
        'Journaux de chantier',
        Icons.menu_book_rounded,
      );
    case 'galleries':
      return const _ProjectSectionConfig(
        'galleries',
        'Galeries',
        Icons.photo_library_rounded,
      );
    case 'stakeholders':
      return const _ProjectSectionConfig(
        'stakeholders',
        'Parties prenantes',
        Icons.groups_rounded,
      );
    case 'activities':
      return const _ProjectSectionConfig(
        'activities',
        'Activites de controle',
        Icons.fact_check_rounded,
      );
    case 'documents':
      return const _ProjectSectionConfig(
        'documents',
        'Documents',
        Icons.folder_copy_rounded,
      );
    default:
      return _ProjectSectionConfig(key, key, Icons.widgets_outlined);
  }
}
