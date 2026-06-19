// ═══════════════════════════════════════════════════════════════════════════
// 📄 task_control_list_screen.dart
// Shows Tasks as grid cards → tap → animated bottom sheet with TaskControls
// ═══════════════════════════════════════════════════════════════════════════

import 'package:constructiondashboard/core/widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../controllers/task_control_controller.dart';
import '../../../task/presentation/controllers/task_controller.dart';
import '../widgets/task_control_form_dialog.dart';
import '../../domain/entities/task_control.dart';
import '../../domain/entities/predefined_control_data.dart';
import '../../../task/domain/entities/task.dart';

class _TaskControlsViewData {
  final List<Task> tasks;
  final List<TaskControl> controls;

  const _TaskControlsViewData({
    required this.tasks,
    required this.controls,
  });
}

class _HeaderCounter {
  final int taskCount;
  final int controlCount;

  const _HeaderCounter(this.taskCount, this.controlCount);

  List<Object?> get tasks => List<Object?>.filled(taskCount, null);
  List<Object?> get taskControls => List<Object?>.filled(controlCount, null);
}

// ═══════════════════════════════════════════════════════════════════════════
// 🏠 Main Screen
// ═══════════════════════════════════════════════════════════════════════════
class TaskControlListScreen extends StatefulWidget {
  final bool embedded;

  const TaskControlListScreen({super.key, this.embedded = false});

  @override
  State<TaskControlListScreen> createState() => _TaskControlListScreenState();
}

class _TaskControlListScreenState extends State<TaskControlListScreen>
    with WidgetsBindingObserver {
  late TaskControlController controller;
  late TaskController taskController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = Get.find<TaskControlController>();
    taskController = Get.find<TaskController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.taskControls.isEmpty && !controller.isLoading.value) {
        controller.fetchTaskControls();
      }
      if (taskController.tasks.isEmpty && !taskController.isLoading.value) {
        taskController.fetchTasks();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      controller.fetchTaskControls(silent: controller.taskControls.isNotEmpty);
      taskController.fetchTasks(silent: taskController.tasks.isNotEmpty);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      child: Column(
        children: [
          // ── Header ──
          _buildHeader(context),
          // ── Body ──
          Expanded(
            child: Obx(() {
              if (taskController.isLoading.value) {
                return const _LoadingView();
              }
              final viewData = _buildViewData(
                taskController.tasks,
                controller.taskControls,
                controller.predefinedLots,
              );

              if (viewData.tasks.isEmpty) {
                return const _EmptyTasksView();
              }
              return _TaskGrid(
                tasks: viewData.tasks,
                allControls: viewData.controls,
                isLoadingCtrl: controller.isLoading.value,
                onAddControl: (taskId) =>
                    _showAddControlDialog(context, taskId),
              );
            }),
          ),
        ],
      ),
    );

    return widget.embedded ? content : AppShell(child: content);
  }

  // ── Header ──────────────────────────────────────────────────────────────
  // ── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Gradient Icon Badge ──
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
                Icons.checklist_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // ── Title + Subtitle ──
            Expanded(
              child: Obx(() {
                final viewData = _buildViewData(
                  this.taskController.tasks,
                  this.controller.taskControls,
                  this.controller.predefinedLots,
                );
                final taskController = _HeaderCounter(
                    viewData.tasks.length, viewData.controls.length);
                final controller = taskController;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Activités de contrôle',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${taskController.tasks.length} tâche(s) · '
                      '${controller.taskControls.length} contrôle(s)',
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

            // ── Refresh Button ──
            IconButton(
              onPressed: () {
                taskController.fetchTasks();
                controller.fetchTaskControls();
              },
              icon: const Icon(
                Icons.refresh_rounded,
                color: Color(0xFF64748B),
                size: 22,
              ),
              tooltip: 'Actualiser',
            ),
          ],
        ),
      ),
    );
  }

  // ── Add Control Dialog ───────────────────────────────────────────────────
  _TaskControlsViewData _buildViewData(
    List<Task> backendTasks,
    List<TaskControl> backendControls,
    List<ControlLot> predefinedLots,
  ) {
    final tasks = <Task>[...backendTasks];
    final controls = <TaskControl>[...backendControls];
    final taskByName = <String, Task>{};

    for (final task in backendTasks) {
      final key = _normalizeName(task.name);
      if (key.isNotEmpty) {
        taskByName.putIfAbsent(key, () => task);
      }
    }

    var taskSeed = 1;
    var controlSeed = 1;

    for (final lot in predefinedLots) {
      for (final activity in lot.activites) {
        final activityKey = _normalizeName(activity.nom);
        var task = taskByName[activityKey];

        if (task == null) {
          task = Task(
            id: -taskSeed,
            name: activity.nom,
            description: 'Lot: ${lot.nom}',
            lotName: lot.nom,
          );
          taskSeed++;
          taskByName[activityKey] = task;
          tasks.add(task);
        }

        final taskId = task.id ?? 0;
        final existingControls = controls
            .where((control) => control.taskId == taskId)
            .map((control) => _normalizeName(control.name ?? ''))
            .toSet();

        for (final control in activity.controles) {
          final controlKey = _normalizeName(control.titre);
          if (existingControls.contains(controlKey)) continue;

          controls.add(
            TaskControl(
              id: -controlSeed,
              name: control.titre,
              description: control.description,
              referencePath: control.reference,
              taskId: taskId,
            ),
          );
          controlSeed++;
          existingControls.add(controlKey);
        }
      }
    }

    return _TaskControlsViewData(tasks: tasks, controls: controls);
  }

  String _normalizeName(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[àáâãäå]'), 'a')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[ýÿ]'), 'y')
        .replaceAll('œ', 'oe')
        .replaceAll('æ', 'ae')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  void _showAddControlDialog(BuildContext context, int taskId) {
    controller.clearForm();
    controller.selectedTaskId.value = taskId;

    showDialog(
      context: context,
      builder: (ctx) => TaskControlFormDialog(
        isEditing: false,
        preselectedTaskId: taskId,
        onSave: () async {
          final success = await controller.createTaskControl();
          if (success) {
            await controller.fetchTaskControls();
            if (ctx.mounted) Navigator.of(ctx).pop();
          }
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🔲 Task Grid — 2-column responsive grid of task cards
// ═══════════════════════════════════════════════════════════════════════════
class _TaskGrid extends StatelessWidget {
  final List<Task> tasks;
  final List<TaskControl> allControls;
  final bool isLoadingCtrl;
  final void Function(int taskId) onAddControl;

  const _TaskGrid({
    required this.tasks,
    required this.allControls,
    required this.isLoadingCtrl,
    required this.onAddControl,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 320,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.35,
      ),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        // Filter controls that belong to this task
        final controls = allControls.where((c) => c.taskId == task.id).toList();

        return _TaskCard(
          task: task,
          controls: controls,
          onAddControl: () => onAddControl(task.id ?? 0),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🃏 Task Card — tap to reveal controls in animated bottom sheet
// ═══════════════════════════════════════════════════════════════════════════
class _TaskCard extends StatefulWidget {
  final Task task;
  final List<TaskControl> controls;
  final void Function() onAddControl;

  const _TaskCard({
    required this.task,
    required this.controls,
    required this.onAddControl,
  });

  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;

  // ── Avatar color derived from task name ──
  Color get _color {
    return AppColors.primaryColor;
  }

  void _openControlsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TaskControlsSheet(
        task: widget.task,
        controls: widget.controls,
        accentColor: _color,
        onAddControl: widget.onAddControl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.task.name;
    final ctrlCount = widget.controls.length;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _openControlsSheet(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  _hovered ? _color.withOpacity(0.45) : const Color(0xFFE8EBF2),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: _hovered
                    ? _color.withOpacity(0.12)
                    : Colors.black.withOpacity(0.04),
                blurRadius: _hovered ? 24 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _color,
                        ),
                      ),
                    ),
                    const Spacer(),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _hovered
                            ? _color.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: _hovered ? _color : const Color(0xFFCBD5E1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.3,
                  ),
                ),
                if (widget.task.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.task.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.checklist_rounded,
                              size: 13, color: _color),
                          const SizedBox(width: 5),
                          Text(
                            '$ctrlCount contrôle${ctrlCount != 1 ? 's' : ''}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Voir',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _hovered ? _color : const Color(0xFFCBD5E1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 📋 TaskControls Bottom Sheet — slides up when task is tapped
// ═══════════════════════════════════════════════════════════════════════════
class _TaskControlsSheet extends StatelessWidget {
  final Task task;
  final List<TaskControl> controls;
  final Color accentColor;
  final VoidCallback onAddControl;

  const _TaskControlsSheet({
    required this.task,
    required this.controls,
    required this.accentColor,
    required this.onAddControl,
  });

  @override
  Widget build(BuildContext context) {
    final isPredefinedTask = (task.id ?? 0) < 0;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // ── Drag handle ──
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Sheet header ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // Accent icon
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        (task.name.isNotEmpty)
                            ? task.name[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Task name + count
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.name,
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            '${controls.length} contrôle${controls.length != 1 ? 's' : ''}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Add button
                    if (!isPredefinedTask)
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          onAddControl();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_rounded,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Ajouter',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
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

              const SizedBox(height: 4),
              const Divider(color: Color(0xFFE8EBF2), height: 24),

              // ── Controls list or empty state ──
              Expanded(
                child: controls.isEmpty
                    ? _SheetEmptyState(
                        accentColor: accentColor,
                        onAdd: () {
                          Navigator.of(context).pop();
                          onAddControl();
                        })
                    : ListView.separated(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        itemCount: controls.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _ControlRow(
                          control: controls[i],
                          accentColor: accentColor,
                          index: i,
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🔲 Individual Control Row inside the sheet
// ═══════════════════════════════════════════════════════════════════════════
class _ControlRow extends StatelessWidget {
  final TaskControl control;
  final Color accentColor;
  final int index;

  const _ControlRow({
    required this.control,
    required this.accentColor,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isPredefinedControl = (control.id ?? 0) < 0;

    return AnimatedContainer(
      duration: Duration(milliseconds: 200 + index * 40),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EBF2), width: 1.2),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        onTap: () => _openControlDetailDialog(context, control, accentColor),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(Icons.check_circle_outline_rounded,
              color: accentColor, size: 18),
        ),
        title: Text(
          control.name ?? 'Contrôle',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: (control.description?.isNotEmpty == true)
            ? Text(
                control.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF94A3B8),
                ),
              )
            : null,
        trailing: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Edit button
              if (!isPredefinedControl)
                GestureDetector(
                  onTap: () {
                    final ctrl = Get.find<TaskControlController>();
                    ctrl.nameController.text = control.name ?? '';
                    ctrl.descriptionController.text = control.description ?? '';
                    ctrl.referencePathController.text =
                        control.referencePath ?? '';
                    ctrl.selectedTaskId.value = control.taskId ?? 0;

                    showDialog(
                      context: context,
                      builder: (_) => TaskControlFormDialog(
                        isEditing: true,
                        onSave: () async {
                          final updatedControl = TaskControl(
                            id: control.id,
                            name: ctrl.nameController.text,
                            description: ctrl.descriptionController.text,
                            referencePath: ctrl.referencePathController.text,
                            status: control.status,
                            taskId: ctrl.selectedTaskId.value,
                          );
                          final success =
                              await ctrl.updateTaskControl(updatedControl);
                          if (success && context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        preselectedTaskId: control.taskId,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child:
                        Icon(Icons.edit_rounded, color: accentColor, size: 14),
                  ),
                ),
              if (!isPredefinedControl) const SizedBox(width: 6),
              // Delete button
              if (!isPredefinedControl)
                GestureDetector(
                  onTap: () async {
                    final ctrl = Get.find<TaskControlController>();

                    final shouldDelete = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        backgroundColor:
                            Theme.of(dialogContext).colorScheme.surface,
                        surfaceTintColor: Colors.transparent,
                        title: Text('delete'.tr),
                        content: const Text(
                            'Supprimer cette activité de contrôle ?'),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            child: Text('cancel'.tr),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red[700],
                            ),
                            child: Text('delete'.tr),
                          ),
                        ],
                      ),
                    );

                    if (shouldDelete == true && control.id != null) {
                      final success = await ctrl.deleteTaskControl(control.id!);
                      if (success && context.mounted) {
                        await ctrl.fetchTaskControls();
                        Navigator.of(context).pop();
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.delete_outline_rounded,
                        color: Colors.red[700], size: 14),
                  ),
                ),
              if (!isPredefinedControl) const SizedBox(width: 6),
              // Link button
              if (control.referencePath?.isNotEmpty == true)
                Tooltip(
                  message: control.referencePath!,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0EA5E9).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.link_rounded,
                        color: Color(0xFF0EA5E9), size: 14),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openControlDetailDialog(
    BuildContext context,
    TaskControl control,
    Color accentColor,
  ) {
    final ctrl = Get.find<TaskControlController>();
    final hasFile = control.referencePath?.isNotEmpty == true;
    final fileName = hasFile ? control.referencePath!.split('/').last : '';

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Theme.of(dialogContext).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.check_circle_outline_rounded,
                        size: 20,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Details de l'activite de controle",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            control.name ?? '-',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: const Color(0xFF94A3B8),
                      splashRadius: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Divider(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    height: 1),
                const SizedBox(height: 24),
                _InfoRow(label: 'Nom', value: control.name ?? '-'),
                const SizedBox(height: 16),
                _InfoRow(
                  label: 'Description',
                  value: (control.description?.isNotEmpty == true)
                      ? control.description!
                      : '-',
                ),
                const SizedBox(height: 16),
                _InfoRow(
                  label: 'Activite',
                  value: control.taskId != null ? 'ID ${control.taskId}' : '-',
                ),
                const SizedBox(height: 24),
                Divider(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    height: 1),
                const SizedBox(height: 16),
                Text(
                  'Fichier',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                if (!hasFile)
                  Text(
                    'Aucun fichier',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF94A3B8),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Icon(Icons.insert_drive_file_rounded,
                              size: 16, color: accentColor),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Obx(() => _FileActionBtn(
                              icon: Icons.visibility_rounded,
                              color: const Color(0xFF0EA5E9),
                              loading: ctrl.isFileViewing.value,
                              onTap: () =>
                                  ctrl.viewFile(control.referencePath!),
                            )),
                        const SizedBox(width: 6),
                        Obx(() => _FileActionBtn(
                              icon: Icons.download_rounded,
                              color: const Color(0xFF8B5CF6),
                              loading: ctrl.isFileDownloading.value,
                              onTap: () =>
                                  ctrl.downloadFile(control.referencePath!),
                            )),
                      ],
                    ),
                  ),
                Obx(() {
                  if (ctrl.fileError.value.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      ctrl.fileError.value,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),
                Divider(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    height: 1),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: Text(
                          'Fermer',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          final formCtrl = Get.find<TaskControlController>();
                          formCtrl.setFormValues(control);
                          showDialog(
                            context: context,
                            builder: (_) => TaskControlFormDialog(
                              isEditing: true,
                              onSave: () async {
                                final updatedControl = TaskControl(
                                  id: control.id,
                                  name: formCtrl.nameController.text,
                                  description:
                                      formCtrl.descriptionController.text,
                                  referencePath:
                                      formCtrl.referencePathController.text,
                                  status: control.status,
                                  taskId: formCtrl.selectedTaskId.value,
                                );
                                final success = await formCtrl
                                    .updateTaskControl(updatedControl);
                                if (success && context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                              preselectedTaskId: control.taskId,
                            ),
                          );
                        },
                        child: Text(
                          'Modifier',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF475569),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _FileActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool loading;
  final VoidCallback onTap;

  const _FileActionBtn({
    required this.icon,
    required this.color,
    this.loading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: loading
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              )
            : Icon(icon, size: 14, color: color),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🫙 Empty states
// ═══════════════════════════════════════════════════════════════════════════
class _SheetEmptyState extends StatelessWidget {
  final Color accentColor;
  final VoidCallback onAdd;

  const _SheetEmptyState({required this.accentColor, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.playlist_add_check_rounded,
            size: 56,
            color: accentColor.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'Aucun contrôle pour cette tâche',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Appuyez sur " Ajouter" pour commencer',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTasksView extends StatelessWidget {
  const _EmptyTasksView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Aucune tâche disponible',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Les tâches apparaîtront ici une fois créées',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator(),
      );
}
