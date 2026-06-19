import 'package:constructiondashboard/core/widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../task/presentation/controllers/task_controller.dart';
import '../../domain/entities/task_control.dart';
import '../controllers/task_control_controller.dart';
import '../widgets/task_control_form_dialog.dart';

// ═══════════════════════════════════════════════════════════
// 📄 TaskControlPage
// ═══════════════════════════════════════════════════════════
class TaskControlPage extends StatefulWidget {
  // ✅ FIX #1: Changed to StatefulWidget
  const TaskControlPage({super.key});

  @override
  State<TaskControlPage> createState() => _TaskControlPageState();
}

class _TaskControlPageState extends State<TaskControlPage> {
  late TaskControlController controller;
  late TaskController taskController;

  // Pagination state
  final RxInt _currentPage = 1.obs;
  final int _itemsPerPage = 6;

  @override
  void initState() {
    super.initState();
    controller = Get.find<TaskControlController>();
    taskController =
        Get.find<TaskController>(); // ✅ FIX #3: TaskController fetched

    // ✅ FIX #2: Data is fetched here on screen open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchTaskControls();
      taskController.fetchTasks(); // ✅ FIX #3: Tasks loaded for dropdown
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      // ✅ FIX #5: Uses AppShell — matches app design system
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            _buildHeader(context),

            // ── Content ──
            Expanded(
              child: Obx(
                () => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _buildBody(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  HEADER
  // ─────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE8EBF2), width: 1),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title Row ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Title + subtitle
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          size: 20,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'taches_de_controle'.tr,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Obx(() => Text(
                        '${controller.taskControls.length} ${'task_controls_total'.tr}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF64748B),
                        ),
                      )),
                ],
              ),

              // ── Add Button ──
              ElevatedButton.icon(
                // ✅ FIX #4: FAB removed, button is in header — stays inside content area only
                onPressed: () => _showCreateTaskControlDialog(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  'add_task_control'.tr,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Search Bar ──
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller:
                  controller.searchController, // ✅ Uses fixed searchController
              onChanged: (val) {
                controller.searchTaskControls(val);
                _currentPage.value = 1; // ✅ Reset to page 1 on search
              },
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: 'search_task_controls'.tr,
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFFB0BAC8),
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Icon(
                    Icons.search_rounded,
                    color: AppColors.primaryColor.withOpacity(0.7),
                    size: 20,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 48),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  BODY
  // ─────────────────────────────────────────────
  Widget _buildBody(BuildContext context) {
    // ── Loading ──
    if (controller.isLoading.value) {
      return const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator(),
      );
    }

    // ── Error ──
    if (controller.errorMessage.value.isNotEmpty) {
      return Center(
        key: const ValueKey('error'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              controller.errorMessage.value,
              style: TextStyle(color: Colors.red[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: controller.fetchTaskControls,
              icon: const Icon(Icons.refresh),
              label: Text('retry'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // ── Empty State ──
    if (controller.taskControls.isEmpty) {
      return Center(
        key: const ValueKey('empty'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'no_task_controls'.tr,
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showCreateTaskControlDialog(context),
              icon: const Icon(Icons.add),
              label: Text('add_task_control'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ── No Search Results ──
    if (controller.filteredTaskControls.isEmpty) {
      return Center(
        key: const ValueKey('no-results'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'no_results_found'.tr,
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'try_different_search'.tr,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    // ── Pagination Helpers ──
    final totalPages = (controller.filteredTaskControls.length / _itemsPerPage)
        .ceil()
        .clamp(1, 999);
    final start = (_currentPage.value - 1) * _itemsPerPage;
    final end = (start + _itemsPerPage)
        .clamp(0, controller.filteredTaskControls.length);
    final pageItems = controller.filteredTaskControls.sublist(start, end);

    // ── List + Pagination ──
    return Stack(
      key: const ValueKey('list'),
      children: [
        RefreshIndicator(
          onRefresh: () async => controller.fetchTaskControls(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: pageItems.length,
            separatorBuilder: (_, __) => const SizedBox(height: 0),
            itemBuilder: (context, index) {
              final taskControl = pageItems[index];
              return _buildTaskControlCard(context, taskControl, controller);
            },
          ),
        ),

        // ── Floating Pagination Pill ──
        if (totalPages > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Obx(() => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                          color: const Color(0xFFE2E8F0), width: 1.2),
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
                        // Prev
                        _PaginationButton(
                          icon: Icons.chevron_left_rounded,
                          enabled: _currentPage.value > 1,
                          onTap: () => _currentPage.value--,
                        ),
                        const SizedBox(width: 4),
                        // Page numbers
                        ...List.generate(totalPages, (i) {
                          final page = i + 1;
                          final isActive = _currentPage.value == page;
                          return GestureDetector(
                            onTap: () => _currentPage.value = page,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.primaryColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$page',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: isActive
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isActive
                                      ? Colors.white
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(width: 4),
                        // Next
                        _PaginationButton(
                          icon: Icons.chevron_right_rounded,
                          enabled: _currentPage.value < totalPages,
                          onTap: () => _currentPage.value++,
                        ),
                      ],
                    ),
                  )),
            ),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  DIALOGS
  // ─────────────────────────────────────────────
  void _showCreateTaskControlDialog(BuildContext context) {
    controller.clearForm();
    showDialog(
      context: context,
      builder: (context) => TaskControlFormDialog(
        isEditing: false,
        onSave: () async {
          final success = await controller.createTaskControl();
          if (success) {
            Navigator.of(context).pop();
            Get.snackbar(
              'success'.tr,
              'task_control_created'.tr,
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: AppColors.success,
              colorText: Colors.white,
            );
          } else if (controller.formErrorMessage.value.isNotEmpty) {
            // ✅ FIX #8: Show error snackbar on failed create
            Get.snackbar(
              'error'.tr,
              controller.formErrorMessage.value,
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: AppColors.error,
              colorText: Colors.white,
            );
          }
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  CARD — will be expanded in Part 2
  // ─────────────────────────────────────────────
  Widget _buildTaskControlCard(
    BuildContext context,
    TaskControl taskControl,
    TaskControlController controller,
  ) {
    // ✅ Placeholder — Part 2 will fill this in
    return const SizedBox.shrink();
  }
}

// ═══════════════════════════════════════════════════════════
// 🔘 Pagination Button Widget
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled
              ? const Color(0xFFF4F6FA)
              : const Color(0xFFF4F6FA).withOpacity(0.4),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 18,
          color: enabled ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
// 🃏 Task Control Card
// ═══════════════════════════════════════════════════════════
  Widget _buildTaskControlCard(
    BuildContext context,
    TaskControl taskControl,
    TaskControlController controller,
  ) {
    // ✅ FIX #1: isHovered MUST be inside StatefulBuilder scope, not outside
    return StatefulBuilder(
      builder: (context, setCardState) {
        bool isHovered =
            false; // ✅ Moved inside builder — now properly reactive

        // ── Avatar color based on first char of name ──
        Color avatarColor() {
          final colors = [
            AppColors.primaryColor,
            const Color(0xFF7C3AED),
            const Color(0xFF0EA5E9),
            const Color(0xFF10B981),
            const Color(0xFFF59E0B),
          ];
          final name = taskControl.name ?? '';
          final idx =
              (name.isNotEmpty ? name.codeUnitAt(0) : 0) % colors.length;
          return colors[idx];
        }

        final hasDesc = taskControl.description != null &&
            taskControl.description!.trim().isNotEmpty;

        final hasRef = taskControl.referencePath != null &&
            taskControl.referencePath!.isNotEmpty;

        // ✅ FIX #7: Show only filename, not full server path
        final displayFileName =
            hasRef ? taskControl.referencePath!.split('/').last : '';

        return MouseRegion(
          onEnter: (_) => setCardState(() => isHovered = true),
          onExit: (_) => setCardState(() => isHovered = false),
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isHovered
                    ? AppColors.primaryColor.withOpacity(0.35)
                    : const Color(0xFFE8EBF2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isHovered
                      ? AppColors.primaryColor.withOpacity(0.10)
                      : const Color(0x06000000),
                  blurRadius: isHovered ? 20 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top Row: Avatar + Info + Actions ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ── Avatar ──
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: avatarColor(),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          (taskControl.name?.trim().isNotEmpty == true)
                              ? taskControl.name![0].toUpperCase()
                              : '?',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      // ── Name + Description + Chips ──
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Name
                            Text(
                              taskControl.name ?? 'tache_de_controle'.tr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),

                            // Description
                            if (hasDesc) ...[
                              const SizedBox(height: 3),
                              Text(
                                taskControl.description!.trim(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],

                            const SizedBox(height: 8),

                            // ── Chips ──
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                if (hasRef)
                                  _InfoChip(
                                    icon: Icons.attach_file_rounded,
                                    label: 'reference'.tr,
                                    color: const Color(0xFF0EA5E9),
                                  ),
                                _InfoChip(
                                  icon: Icons.task_alt_rounded,
                                  label: 'task_control'.tr,
                                  color: AppColors.primaryColor,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      // ── PopupMenu Actions ──
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            controller.setFormValues(taskControl);
                            showDialog(
                              context:
                                  context, // ✅ FIX #4: Use local context, not Get.context!
                              builder: (_) => TaskControlFormDialog(
                                isEditing: true,
                                onSave: () async {
                                  // ✅ FIX #3: Pass taskControl.id only, controller holds the updated form values
                                  final result = await controller
                                      .updateTaskControl(taskControl);
                                  if (result) {
                                    Navigator.of(context).pop(); // ✅ FIX #4
                                    Get.snackbar(
                                      'success'.tr,
                                      'task_control_updated'.tr,
                                      snackPosition: SnackPosition.BOTTOM,
                                      backgroundColor: AppColors.success,
                                      colorText: Colors.white,
                                    );
                                  } else if (controller
                                      .formErrorMessage.value.isNotEmpty) {
                                    Get.snackbar(
                                      'error'.tr,
                                      controller.formErrorMessage.value,
                                      snackPosition: SnackPosition.BOTTOM,
                                      backgroundColor: AppColors.error,
                                      colorText: Colors.white,
                                    );
                                  }
                                },
                              ),
                            );
                          } else if (value == 'delete') {
                            showDialog(
                              context: context, // ✅ FIX #4
                              builder: (_) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: Text(
                                  'confirm'.tr,
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700),
                                ),
                                content: Text(
                                  'confirm_delete_task_control'.tr,
                                  style: GoogleFonts.inter(fontSize: 14),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(), // ✅ FIX #4
                                    child: Text('cancel'.tr,
                                        style: GoogleFonts.inter()),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      Navigator.of(context).pop(); // ✅ FIX #4
                                      final result = await controller
                                          .deleteTaskControl(taskControl.id!);
                                      if (result) {
                                        Get.snackbar(
                                          'success'.tr,
                                          'task_control_deleted'.tr,
                                          snackPosition: SnackPosition.BOTTOM,
                                          backgroundColor: AppColors.success,
                                          colorText: Colors.white,
                                        );
                                      } else {
                                        // ✅ FIX #6: Show error on failed delete
                                        Get.snackbar(
                                          'error'.tr,
                                          controller
                                                  .errorMessage.value.isNotEmpty
                                              ? controller.errorMessage.value
                                              : 'failed_to_delete_task_control'
                                                  .tr,
                                          snackPosition: SnackPosition.BOTTOM,
                                          backgroundColor: AppColors.error,
                                          colorText: Colors.white,
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFEF4444),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text('delete'.tr,
                                        style: GoogleFonts.inter(
                                            color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                          } else if (value == 'view') {
                            // ✅ FIX #2: Guard against null before force unwrap
                            if (hasRef) {
                              controller.viewFile(taskControl.referencePath!);
                            }
                          } else if (value == 'download') {
                            // ✅ FIX #2: Guard against null before force unwrap
                            if (hasRef) {
                              controller
                                  .downloadFile(taskControl.referencePath!);
                            }
                          }
                        },
                        itemBuilder: (_) => [
                          // ── Edit ──
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit_rounded,
                                    size: 16, color: AppColors.primaryColor),
                                const SizedBox(width: 10),
                                Text('edit'.tr,
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          // ── View (only if ref exists) ──
                          if (hasRef)
                            PopupMenuItem(
                              value: 'view',
                              child: Row(
                                children: [
                                  const Icon(Icons.visibility_rounded,
                                      size: 16, color: Color(0xFF0EA5E9)),
                                  const SizedBox(width: 10),
                                  Text('view'.tr,
                                      style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          // ── Download (only if ref exists) ──
                          if (hasRef)
                            PopupMenuItem(
                              value: 'download',
                              child: Row(
                                children: [
                                  const Icon(Icons.download_rounded,
                                      size: 16, color: Color(0xFF10B981)),
                                  const SizedBox(width: 10),
                                  Text('download'.tr,
                                      style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          // ── Delete ──
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete_outline_rounded,
                                    size: 16, color: Color(0xFFEF4444)),
                                const SizedBox(width: 10),
                                Text('delete'.tr,
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFFEF4444))),
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
                          child: const Icon(
                            Icons.more_vert_rounded,
                            size: 18,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ── Reference Path Row (if exists) ──
                  if (hasRef) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.insert_drive_file_rounded,
                              size: 14, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              displayFileName, // ✅ FIX #7: Shows "report.pdf" not "/uploads/abc/report.pdf"
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF0EA5E9),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 🏷️ _InfoChip — FIX #5: Defined here (was missing entirely)
// ═══════════════════════════════════════════════════════════
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
