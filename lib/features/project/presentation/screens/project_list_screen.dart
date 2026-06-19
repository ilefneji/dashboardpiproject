import 'package:constructiondashboard/core/widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../controllers/project_controller.dart';
import '../../data/models/project_model.dart';
import '../widgets/project_form_dialog.dart';

// ═══════════════════════════════════════════════════════════
// 📋 ProjectListScreen
// ═══════════════════════════════════════════════════════════
class ProjectListScreen extends StatefulWidget {
  final bool showArchived;
  final bool embedded;

  const ProjectListScreen({
    super.key,
    this.showArchived = false,
    this.embedded = false,
  });

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  late final ProjectController controller;
  final List<Worker> _workers = [];
  bool _refreshScheduled = false;

  @override
  void initState() {
    super.initState();
    controller = Get.find<ProjectController>();
    _workers.addAll([
      ever(controller.isLoading, (_) => _refreshUi()),
      ever(controller.hasError, (_) => _refreshUi()),
      ever(controller.error, (_) => _refreshUi()),
      ever(controller.filteredProjects, (_) => _refreshUi()),
    ]);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.projects.isEmpty && !controller.isLoading.value) {
        controller.getAllProjects();
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
    if (!mounted) return;

    if (SchedulerBinding.instance.schedulerPhase !=
        SchedulerPhase.persistentCallbacks) {
      setState(() {});
      return;
    }

    if (_refreshScheduled) return;
    _refreshScheduled = true;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _refreshScheduled = false;
      if (mounted) setState(() {});
    });
  }

  Future<void> _refreshProjects() async {
    await controller.getAllProjects();
  }

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      child: RefreshIndicator(
        onRefresh: _refreshProjects,
        child: Column(
          children: [
            _PageHeader(
              controller: controller,
              showArchived: widget.showArchived,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildBody(context, controller),
              ),
            ),
          ],
        ),
      ),
    );

    return widget.embedded ? content : AppShell(child: content);
  }

  Widget _buildBody(BuildContext context, ProjectController controller) {
    if (controller.isLoading.value) {
      return const _LoadingView(key: ValueKey('loading'));
    }

    if (controller.hasError.value && controller.error.value.isNotEmpty) {
      return _ErrorView(
        key: const ValueKey('error'),
        message: controller.error.value,
        onRetry: controller.getAllProjects,
      );
    }

    if (controller.filteredProjects.isEmpty) {
      return _EmptyView(
        key: const ValueKey('empty'),
        controller: controller,
        showArchived: widget.showArchived,
      );
    }

    final visibleProjects = controller.filteredProjects.where((project) {
      return widget.showArchived
          ? project.isActive == false
          : project.isActive != false;
    }).toList();

    if (visibleProjects.isEmpty) {
      return _EmptyView(
        key: const ValueKey('empty-filtered'),
        controller: controller,
        showArchived: widget.showArchived,
      );
    }

    return _ProjectList(
      key: const ValueKey('list'),
      controller: controller,
      projects: visibleProjects,
      showArchived: widget.showArchived,
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 🔝 Page Header — StatefulWidget owns the TextEditingController
// ═══════════════════════════════════════════════════════════
class _PageHeader extends StatefulWidget {
  final ProjectController controller;
  final bool showArchived;

  const _PageHeader({required this.controller, required this.showArchived});

  @override
  State<_PageHeader> createState() => _PageHeaderState();
}

class _PageHeaderState extends State<_PageHeader> {
  // ✅ Owned here — Flutter manages its full lifecycle safely
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    // ✅ Disposed with the widget — never touched by GetX
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.showArchived ? 'Archives projets' : 'projects'.tr;

    final header = Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF94A3B8).withOpacity(0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF94A3B8).withOpacity(0.12),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title Row ──────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor.withOpacity(0.28),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.work_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                // Title + Count
                Expanded(
                  child: Obx(() {
                    final visibleCount = _visibleCount();
                    final _ = widget.controller.filteredProjects.length;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$visibleCount ${widget.showArchived ? 'projet(s) archive(s)' : 'projects'.tr}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Search Field ────────────────────────────────
            TextField(
              // ✅ Uses local controller — never disposed by GetX
              controller: _searchController,
              onChanged: widget.controller.searchProjects,
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFFCBD5E1),
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: Color(0xFF94A3B8),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primaryColor,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return header;
  }

  int _visibleCount() {
    return widget.controller.filteredProjects.where((project) {
      return widget.showArchived
          ? project.isActive == false
          : project.isActive != false;
    }).length;
  }
}

// ═══════════════════════════════════════════════════════════
// 📋 Project List
// ═══════════════════════════════════════════════════════════
class _ProjectList extends StatefulWidget {
  final ProjectController controller;
  final List<ProjectModel> projects;
  final bool showArchived;

  const _ProjectList({
    super.key,
    required this.controller,
    required this.projects,
    required this.showArchived,
  });

  @override
  State<_ProjectList> createState() => _ProjectListState();
}

class _ProjectListState extends State<_ProjectList> {
  static const int _pageSize = 8;
  int _currentPage = 0;
  Worker? _filteredProjectsWorker;
  bool _pageResetScheduled = false;

  @override
  void initState() {
    super.initState();
    // ✅ Reset to page 0 whenever the filtered list changes
    _filteredProjectsWorker =
        ever(widget.controller.filteredProjects, (_) => _resetPage());
  }

  @override
  void dispose() {
    _filteredProjectsWorker?.dispose();
    super.dispose();
  }

  // Reset pagination after filter changes without rebuilding during build.
  void _resetPage() {
    if (!mounted || _currentPage == 0) return;

    if (SchedulerBinding.instance.schedulerPhase !=
        SchedulerPhase.persistentCallbacks) {
      setState(() => _currentPage = 0);
      return;
    }

    if (_pageResetScheduled) return;
    _pageResetScheduled = true;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _pageResetScheduled = false;
      if (mounted) setState(() => _currentPage = 0);
    });
  }

  Future<void> _openCreateDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const ProjectFormDialog(isEditing: false),
    );

    await Future.delayed(const Duration(milliseconds: 250));

    if (mounted) {
      await widget.controller.getAllProjects();
      widget.controller.filteredProjects.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.projects;

    if (items.isEmpty) {
      return _EmptyView(
        controller: widget.controller,
        showArchived: widget.showArchived,
      );
    }

    final totalPages = (items.length / _pageSize).ceil();
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, items.length);
    final pageItems = items.sublist(start, end);
    final list = ListView.separated(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 14, bottom: 88),
      itemCount: pageItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return _ProjectCard(project: pageItems[index]);
      },
    );

    return Stack(
      children: [
        // ── List ──────────────────────────────────────────
        list,

        // ── Pagination ────────────────────────────────────
        if (totalPages > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: widget.showArchived ? 0 : 80,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF94A3B8).withOpacity(0.15),
                      blurRadius: 16,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PaginationButton(
                      icon: Icons.chevron_left_rounded,
                      enabled: _currentPage > 0,
                      onTap: () => setState(() => _currentPage--),
                    ),
                    const SizedBox(width: 8),
                    ...List.generate(totalPages, (i) {
                      final isActive = i == _currentPage;
                      return GestureDetector(
                        onTap: () => setState(() => _currentPage = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: isActive ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.primaryColor
                                : const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(width: 8),
                    _PaginationButton(
                      icon: Icons.chevron_right_rounded,
                      enabled: _currentPage < totalPages - 1,
                      onTap: () => setState(() => _currentPage++),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // ── FAB ───────────────────────────────────────────
        if (!widget.showArchived)
          Positioned(
            bottom: 24,
            right: 24,
            child: GestureDetector(
              onTap: _openCreateDialog, // ✅ ONLY LINE THAT CHANGED
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 28,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 💳 Project Card
// ═══════════════════════════════════════════════════════════
class _ProjectCard extends StatefulWidget {
  final ProjectModel project;

  const _ProjectCard({required this.project});

  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProjectController>();
    final isArchived = widget.project.isActive == false;
    final colors = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Get.toNamed('/projects/${widget.project.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? AppColors.primaryColor.withOpacity(0.28)
                  : colors.outlineVariant,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? AppColors.primaryColor.withOpacity(0.08)
                    : colors.shadow.withOpacity(
                        Theme.of(context).brightness == Brightness.dark
                            ? 0.12
                            : 0.035,
                      ),
                blurRadius: _isHovered ? 14 : 8,
                offset: Offset(0, _isHovered ? 4 : 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.work_rounded,
                    color: AppColors.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.project.name,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.project.description,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: colors.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isArchived)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.primaryColor.withOpacity(0.18),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.primaryColor,
                          size: 13,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Archivé',
                          style: GoogleFonts.inter(
                            color: AppColors.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  PopupMenuButton<String>(
                    // ✅ FIX — async + await sur chaque action
                    onSelected: (value) async {
                      if (value == 'edit') {
                        // ✅ await showDialog — attend la fermeture
                        await showDialog(
                          context: context,
                          builder: (_) => ProjectFormDialog(
                            isEditing: true,
                            projectId: widget.project.id,
                            initialName: widget.project.name,
                            initialDescription: widget.project.description,
                            initialStartDate: widget.project.startDate,
                            initialEndDate: widget.project.endDate,
                            initialBudget: widget.project.budget,
                            initialLocalisation: widget.project.localisation,
                            initialLatitude: widget.project.latitude,
                            initialLongitude: widget.project.longitude,
                            initialLotIds: widget.project.lotIds,
                          ),
                        );

                        // ✅ Rafraîchit après fermeture du dialog d'édition
                        await controller.getAllProjects();
                      } else if (value == 'archive') {
                        await controller.archiveProject(widget.project.id);
                      } else if (value == 'delete') {
                        await showDialog(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            backgroundColor: Theme.of(
                              dialogContext,
                            ).colorScheme.surface,
                            surfaceTintColor: Colors.transparent,
                            title: const Text('Supprimer le projet'),
                            content: Text(
                              'Êtes-vous sûr de vouloir supprimer "${widget.project.name}"?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(),
                                child: const Text('Annuler'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final success = await controller
                                      .deleteProject(widget.project.id);
                                  if (success && dialogContext.mounted) {
                                    Navigator.of(dialogContext).pop();
                                  }
                                  // ✅ deleteProject appelle déjà getAllProjects()
                                  // en interne — rien à ajouter ici
                                },
                                child: const Text(
                                  'Supprimer',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.edit_rounded,
                              size: 16,
                              color: AppColors.primaryColor,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Modifier',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'archive',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.archive_outlined,
                              size: 16,
                              color: AppColors.primaryColor,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Archiver',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.delete_outline_rounded,
                              size: 16,
                              color: Color(0xFFEF4444),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Supprimer',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    color: Theme.of(context).colorScheme.surface,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.more_vert_rounded,
                        size: 18,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 🔘 Pagination Button
// ═══════════════════════════════════════════════════════════
class _PaginationButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PaginationButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 18,
          color: enabled ? const Color(0xFF64748B) : Colors.grey[300],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 📭 Empty View
// ═══════════════════════════════════════════════════════════
class _EmptyView extends StatelessWidget {
  final ProjectController controller;
  final bool showArchived;

  const _EmptyView({
    super.key,
    required this.controller,
    this.showArchived = false,
  });

  Future<void> _openCreateDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const ProjectFormDialog(isEditing: false),
    );

    await controller.getAllProjects();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          key: key,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  showArchived
                      ? Icons.inventory_2_outlined
                      : Icons.work_outline_rounded,
                  size: 64,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  showArchived
                      ? 'Aucun projet archivé'
                      : 'Aucun projet disponible',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  showArchived
                      ? 'Les projets archivés apparaîtront ici.'
                      : 'Créez votre premier projet pour commencer.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!showArchived)
          Positioned(
            bottom: 24,
            right: 24,
            child: GestureDetector(
              onTap: () => _openCreateDialog(context),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 28,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ⏳ Loading View
// ═══════════════════════════════════════════════════════════
class _LoadingView extends StatelessWidget {
  const _LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

// ═══════════════════════════════════════════════════════════
// ❌ Error View
// ═══════════════════════════════════════════════════════════
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon ──
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 30,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 16),

            // ── Title ──
            Text(
              'Une erreur est survenue',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // ── Message ──
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF94A3B8),
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),

            // ── Retry Button ──
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Réessayer',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
