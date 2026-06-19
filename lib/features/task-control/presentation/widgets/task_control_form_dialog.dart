// ═══════════════════════════════════════════════════════════════════════════
// 📄 task_control_form_dialog.dart  — Complete Production Version
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../controllers/task_control_controller.dart';
import '../../../task/presentation/controllers/task_controller.dart';

class TaskControlFormDialog extends StatelessWidget {
  final bool isEditing;
  final VoidCallback onSave;
  final int? preselectedTaskId;

  const TaskControlFormDialog({
    super.key,
    required this.isEditing,
    required this.onSave,
    this.preselectedTaskId,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TaskControlController>();
    final taskController = Get.find<TaskController>();

    // ── Pre-set taskId into controller the moment dialog opens ──
    // This ensures createTaskControl() always has the correct taskId
    // even if the user never touches the dropdown.
    if (preselectedTaskId != null) {
      // Use addPostFrameCallback to avoid setState-during-build issues
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.selectedTaskId.value = preselectedTaskId!;
      });
    }

    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ══════════════════════════════════════
                // 🔷 Dialog Header
                // ══════════════════════════════════════
                _DialogHeader(isEditing: isEditing),
                const SizedBox(height: 24),

                // ══════════════════════════════════════
                // 🔒 Task Selector / Locked Badge
                // ══════════════════════════════════════
                _TaskSelectorField(
                  controller: controller,
                  taskController: taskController,
                  preselectedTaskId: preselectedTaskId,
                  isEditing: isEditing,
                ),
                const SizedBox(height: 16),

                // ══════════════════════════════════════
                // 📋 Predefined Control Selector (Lot → Activity → Control)
                // ══════════════════════════════════════
                _PredefinedControlSelector(controller: controller),
                const SizedBox(height: 16),

                // ══════════════════════════════════════
                // ✏️ Name Field
                // ══════════════════════════════════════
                _FormLabel(label: 'name'.tr, required: true),
                const SizedBox(height: 6),
                TextField(
                  controller: controller.nameController,
                  decoration: _inputDecoration(
                    hint: 'task_control_name_hint'.tr,
                    icon: Icons.label_outline_rounded,
                  ),
                ),
                const SizedBox(height: 16),

                // ══════════════════════════════════════
                // 📝 Description Field
                // ══════════════════════════════════════
                _FormLabel(label: 'description'.tr),
                const SizedBox(height: 6),
                TextField(
                  controller: controller.descriptionController,
                  maxLines: 4,
                  decoration: _inputDecoration(
                    hint: 'task_control_description_hint'.tr,
                    icon: Icons.notes_rounded,
                  ),
                ),
                const SizedBox(height: 16),

                // ══════════════════════════════════════
                // 📎 File Upload Section
                // ══════════════════════════════════════
                _FormLabel(label: 'reference_file'.tr),
                const SizedBox(height: 6),
                _FileUploadSection(controller: controller),
                const SizedBox(height: 20),

                // ══════════════════════════════════════
                // ❌ Form Error Message
                // ══════════════════════════════════════
                Obx(() {
                  final msg = controller.formErrorMessage.value;
                  if (msg.isEmpty) return const SizedBox.shrink();
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: Color(0xFFEF4444), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            msg,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                // ══════════════════════════════════════
                // 🔘 Action Buttons
                // ══════════════════════════════════════
                _DialogActions(
                  isEditing: isEditing,
                  controller: controller,
                  onSave: onSave,
                  context: context,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Shared input decoration ──────────────────────────────────────────────
  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          GoogleFonts.inter(fontSize: 13, color: const Color(0xFFCBD5E1)),
      prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
      filled: true,
      fillColor: AppColors.cardWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
        borderSide: const BorderSide(color: AppColors.primaryColor, width: 1.5),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🔷 Dialog Header
// ═══════════════════════════════════════════════════════════════════════════
class _DialogHeader extends StatelessWidget {
  final bool isEditing;
  const _DialogHeader({required this.isEditing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Icon badge
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(
            isEditing ? Icons.edit_rounded : Icons.add_task_rounded,
            color: AppColors.primaryColor,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),

        // Title + subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'edit_task_control'.tr : 'add_task_control'.tr,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                isEditing
                    ? 'update_task_control_subtitle'.tr
                    : 'create_task_control_subtitle'.tr,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),

        // Close button
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.close_rounded,
                size: 16, color: Color(0xFF64748B)),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🔒 Task Selector Field
// ═══════════════════════════════════════════════════════════════════════════
class _TaskSelectorField extends StatelessWidget {
  final TaskControlController controller;
  final TaskController taskController;
  final int? preselectedTaskId;
  final bool isEditing;

  const _TaskSelectorField({
    required this.controller,
    required this.taskController,
    required this.preselectedTaskId,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FormLabel(label: 'task'.tr, required: true),
        const SizedBox(height: 6),

        // ── LOCKED: Opened from task card bottom sheet ──
        if (preselectedTaskId != null) ...[
          Obx(() {
            final task = taskController.tasks
                .firstWhereOrNull((t) => t.id == preselectedTaskId);
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0EA5E9), width: 1.5),
              ),
              child: Row(
                children: [
                  // Lock icon
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0EA5E9).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.lock_rounded,
                        size: 13, color: Color(0xFF0EA5E9)),
                  ),
                  const SizedBox(width: 10),

                  // Task name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task?.name ?? 'Tâche #$preselectedTaskId',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0369A1),
                          ),
                        ),
                        if (task?.description?.isNotEmpty == true)
                          Text(
                            task!.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF7DD3FC),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // "Fixed" chip
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0EA5E9).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'fixed'.tr,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0EA5E9),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // ── EDITABLE: Opened from global FAB or edit mode ──
        ] else ...[
          Obx(() {
            final tasks = taskController.tasks;

            // Determine the value to show:
            // - 0 means nothing selected → show null in dropdown
            final currentVal = controller.selectedTaskId.value != 0
                ? controller.selectedTaskId.value
                : null;

            return DropdownButtonFormField<int>(
              value: currentVal,
              isExpanded: true,
              dropdownColor: Colors.white,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF94A3B8)),
              decoration: InputDecoration(
                hintText: 'select_task_hint'.tr,
                hintStyle: GoogleFonts.inter(
                    fontSize: 13, color: const Color(0xFFCBD5E1)),
                prefixIcon: const Icon(Icons.task_alt_rounded,
                    size: 18, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
                  borderSide:
                      const BorderSide(color: AppColors.primaryColor, width: 1.5),
                ),
              ),
              items: tasks.map((task) {
                return DropdownMenuItem<int>(
                  value: task.id,
                  child: Text(
                    task.name,
                    style: GoogleFonts.inter(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) controller.selectedTaskId.value = val;
              },
            );
          }),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 📎 File Upload Section
// ═══════════════════════════════════════════════════════════════════════════
class _FileUploadSection extends StatelessWidget {
  final TaskControlController controller;
  const _FileUploadSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hasFile = controller.uploadedFilePath.value.isNotEmpty;
      final isUploading = controller.isFileUploading.value;
      final fileError = controller.fileError.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── File preview (when file is selected) ──
          if (hasFile) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                children: [
                  // File icon
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.insert_drive_file_rounded,
                        color: Color(0xFF22C55E), size: 18),
                  ),
                  const SizedBox(width: 10),

                  // File name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.uploadedFileName.value.isNotEmpty
                              ? controller.uploadedFileName.value
                              : controller.uploadedFilePath.value
                                  .split('/')
                                  .last,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF15803D),
                          ),
                        ),
                        Text(
                          'file_attached'.tr,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF86EFAC),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // View button
                  _FileActionBtn(
                    icon: Icons.visibility_rounded,
                    color: const Color(0xFF0EA5E9),
                    loading: controller.isFileViewing.value,
                    onTap: () =>
                        controller.viewFile(controller.uploadedFilePath.value),
                  ),
                  const SizedBox(width: 6),

                  // Download button
                  _FileActionBtn(
                    icon: Icons.download_rounded,
                    color: const Color(0xFF8B5CF6),
                    loading: controller.isFileDownloading.value,
                    onTap: () => controller
                        .downloadFile(controller.uploadedFilePath.value),
                  ),
                  const SizedBox(width: 6),

                  // Clear/remove button
                  _FileActionBtn(
                    icon: Icons.delete_outline_rounded,
                    color: const Color(0xFFEF4444),
                    onTap: controller.clearFile,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // ── Upload button ──
          GestureDetector(
            onTap: isUploading ? null : controller.pickAndUploadFile,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isUploading
                    ? const Color(0xFFF8FAFC)
                    : AppColors.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isUploading
                      ? const Color(0xFFE2E8F0)
                      : AppColors.primaryColor.withOpacity(0.3),
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isUploading) ...[
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'uploading'.tr,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ] else ...[
                    Icon(
                      hasFile
                          ? Icons.swap_horiz_rounded
                          : Icons.upload_file_rounded,
                      size: 18,
                      color: AppColors.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hasFile ? 'replace_file'.tr : 'upload_file'.tr,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── File error ──
          if (fileError.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 13, color: Color(0xFFF59E0B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    fileError,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFFD97706),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🔘 Dialog Action Buttons
// ═══════════════════════════════════════════════════════════════════════════
class _DialogActions extends StatelessWidget {
  final bool isEditing;
  final TaskControlController controller;
  final VoidCallback onSave;
  final BuildContext context;

  const _DialogActions({
    required this.isEditing,
    required this.controller,
    required this.onSave,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Cancel
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'cancel'.tr,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Save / Update
        Expanded(
          flex: 2,
          child: Obx(() {
            final isLoading = controller.isLoading.value;
            final isUploading = controller.isFileUploading.value;
            final disabled = isLoading || isUploading;

            return ElevatedButton(
              onPressed: disabled ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppColors.primaryColor.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading) ...[
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ] else ...[
                    Icon(
                      isEditing ? Icons.check_rounded : Icons.add_rounded,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    isLoading
                        ? 'saving'.tr
                        : isEditing
                            ? 'update'.tr
                            : 'save'.tr,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 📋 Predefined Control Selector (Lot → Activity → Control)
// ═══════════════════════════════════════════════════════════════════════════
class _PredefinedControlSelector extends StatelessWidget {
  final TaskControlController controller;

  const _PredefinedControlSelector({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    InputDecoration dropdownDecoration({required String hint, required IconData icon}) {
      return InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFCBD5E1)),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
        filled: true,
        fillColor: isDark ? theme.colorScheme.surfaceVariant : AppColors.cardWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
          borderSide: const BorderSide(color: AppColors.primaryColor, width: 1.5),
        ),
      );
    }

    Widget emptyMessage(String text) {
      return Padding(
        padding: const EdgeInsets.only(top: 6, left: 4),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF94A3B8),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Obx(() {
      final lots = controller.predefinedLots;
      final activities = controller.activitiesForSelectedLot;
      final controls = controller.controlsForSelectedActivity;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FormLabel(label: 'lot_de_controle'.tr),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: controller.selectedLotId.value.isEmpty
                ? null
                : controller.selectedLotId.value,
            isExpanded: true,
            dropdownColor: isDark ? theme.colorScheme.surface : Colors.white,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8)),
            decoration: dropdownDecoration(
              hint: 'select_lot_hint'.tr,
              icon: Icons.folder_copy_rounded,
            ),
            items: lots.map((lot) {
              return DropdownMenuItem<String>(
                value: lot.id,
                child: Text(
                  lot.nom,
                  style: GoogleFonts.inter(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: lots.isEmpty
                ? null
                : (val) {
                    if (val != null) controller.selectedLotId.value = val;
                  },
          ),
          if (lots.isEmpty) emptyMessage('no_predefined_lots'.tr),
          const SizedBox(height: 12),

          _FormLabel(label: 'activite_de_controle'.tr),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: controller.selectedActivityId.value.isEmpty
                ? null
                : controller.selectedActivityId.value,
            isExpanded: true,
            dropdownColor: isDark ? theme.colorScheme.surface : Colors.white,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8)),
            decoration: dropdownDecoration(
              hint: 'select_activity_hint'.tr,
              icon: Icons.format_list_bulleted_rounded,
            ),
            items: activities.map((activity) {
              return DropdownMenuItem<String>(
                value: activity.id,
                child: Text(
                  activity.nom,
                  style: GoogleFonts.inter(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: controller.selectedLotId.value.isEmpty || activities.isEmpty
                ? null
                : (val) {
                    if (val != null) controller.selectedActivityId.value = val;
                  },
          ),
          if (controller.selectedLotId.value.isNotEmpty && activities.isEmpty)
            emptyMessage('no_activities_for_lot'.tr),
          const SizedBox(height: 12),

          _FormLabel(label: 'controle_predefini'.tr),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: controller.selectedPredefinedControlId.value.isEmpty
                ? null
                : controller.selectedPredefinedControlId.value,
            isExpanded: true,
            dropdownColor: isDark ? theme.colorScheme.surface : Colors.white,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8)),
            decoration: dropdownDecoration(
              hint: 'select_predefined_control_hint'.tr,
              icon: Icons.checklist_rounded,
            ),
            items: controls.map((control) {
              return DropdownMenuItem<String>(
                value: control.id,
                child: Text(
                  control.titre,
                  style: GoogleFonts.inter(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: controller.selectedActivityId.value.isEmpty || controls.isEmpty
                ? null
                : (val) {
                    if (val != null) controller.selectedPredefinedControlId.value = val;
                  },
          ),
          if (controller.selectedActivityId.value.isNotEmpty && controls.isEmpty)
            emptyMessage('no_controls_for_activity'.tr),
        ],
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🏷️ Form Label
// ═══════════════════════════════════════════════════════════════════════════
class _FormLabel extends StatelessWidget {
  final String label;
  final bool required;

  const _FormLabel({required this.label, this.required = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
        if (required) ...[
          const SizedBox(width: 3),
          const Text('*',
              style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🔘 File Action Button (view / download / delete)
// ═══════════════════════════════════════════════════════════════════════════
class _FileActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool loading;

  const _FileActionBtn({
    required this.icon,
    required this.color,
    required this.onTap,
    this.loading = false,
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
                width: 13,
                height: 13,
                child:
                    CircularProgressIndicator(strokeWidth: 1.5, color: color),
              )
            : Icon(icon, size: 15, color: color),
      ),
    );
  }
}
