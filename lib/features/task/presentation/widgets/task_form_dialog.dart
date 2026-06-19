import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../controllers/task_controller.dart';
import '../../../lot/presentation/controllers/lot_controller.dart';

class TaskFormDialog extends StatelessWidget {
  final bool isEditing;
  final VoidCallback onSave;

  const TaskFormDialog({
    super.key,
    this.isEditing = false,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final TaskController controller = Get.find<TaskController>();

    try {
      final lotController = Get.find<LotController>();
      if (lotController.lots.isEmpty && !lotController.isLoading.value) {
        lotController.fetchLots();
      }
    } catch (_) {
      // LotController not registered
    }

    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              _buildHeader(context),

              const SizedBox(height: 24),

              // ── Fields ──
              _buildLabel('task_name'.tr),
              const SizedBox(height: 8),
              _buildTextField(
                controller: controller.nameController,
                hint: 'enter_task_name'.tr,
                icon: Icons.assignment_rounded,
              ),

              const SizedBox(height: 16),

              _buildLabel('task_description'.tr),
              const SizedBox(height: 8),
              _buildTextField(
                controller: controller.descriptionController,
                hint: 'enter_task_description'.tr,
                icon: Icons.notes_rounded,
                maxLines: 3,
              ),

              const SizedBox(height: 16),

              // ── Lot Picker ──
              _buildLabel('lot'.tr),
              const SizedBox(height: 8),
              _LotSelector(controller: controller),

              const SizedBox(height: 24),

              // ── Actions ──
              _buildActions(context, controller),
            ],
          ),
        ),
      ),
    );
  }

  // ── Dialog Header ──
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withOpacity(0.28),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            isEditing ? Icons.edit_rounded : Icons.add_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'edit_task'.tr : 'add_task'.tr,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isEditing ? 'update_task_details'.tr : 'fill_task_details'.tr,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.close_rounded,
              size: 18,
              color: Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }

  // ── Section Label ──
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF374151),
      ),
    );
  }

  // ── Styled TextField ──
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: const Color(0xFFCBD5E1),
        ),
        prefixIcon: maxLines == 1
            ? Icon(icon, size: 18, color: const Color(0xFF94A3B8))
            : null,
        filled: true,
        fillColor: AppColors.cardWhite,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: maxLines > 1 ? 14 : 0,
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
          borderSide: const BorderSide(color: AppColors.primaryColor, width: 1.5),
        ),
      ),
    );
  }

  // ── Action Buttons ──
  Widget _buildActions(BuildContext context, TaskController controller) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'cancel'.tr,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Obx(() {
            final isLoading = controller.isLoading.value;
            return ElevatedButton(
              onPressed: isLoading ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isEditing ? 'update'.tr : 'save'.tr,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            );
          }),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ✅ Lot Selector Widget
// ═══════════════════════════════════════════════════════════
class _LotSelector extends StatefulWidget {
  final TaskController controller;

  const _LotSelector({required this.controller});

  @override
  State<_LotSelector> createState() => _LotSelectorState();
}

class _LotSelectorState extends State<_LotSelector> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Correctly observe the RxList and Rx<Lot?>
    return Obx(() {
      final lots = widget.controller.availableLots; // getter from LotController
      final selected =
          widget.controller.selectedLot.value; // ✅ this IS observable
      final selectedLotId = widget.controller.selectedLotId.value;
      final query = _searchCtrl.text.trim().toLowerCase();
      final filteredLots = query.isEmpty
          ? lots
          : lots.where((lot) {
              return lot.name.toLowerCase().contains(query) ||
                  lot.description.toLowerCase().contains(query);
            }).toList();

      if (lots.isEmpty) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.layers_rounded,
                  size: 18, color: Color(0xFF94A3B8)),
              const SizedBox(width: 10),
              Text(
                'Aucun lot',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFFCBD5E1),
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        constraints: const BoxConstraints(maxHeight: 240),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Rechercher un lot',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFFB0BAC8),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: AppColors.primaryColor.withOpacity(0.7),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.primaryColor,
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: filteredLots.isEmpty
                    ? Center(
                        child: Text(
                          'Aucun lot trouvé',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemCount: filteredLots.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          color: Color(0xFFE2E8F0),
                          indent: 16,
                          endIndent: 16,
                        ),
                        itemBuilder: (context, index) {
                          final lot = filteredLots[index];
                          final isSelected =
                              selectedLotId == lot.id || selected?.id == lot.id;

                          return InkWell(
                            onTap: () {
                              widget.controller.selectedLot.value =
                                  isSelected ? null : lot;
                              widget.controller.selectedLotId.value =
                                  isSelected ? null : lot.id;
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? AppColors.primaryColor
                                          : Colors.white,
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primaryColor
                                            : const Color(0xFFCBD5E1),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check_rounded,
                                            size: 12, color: Colors.white)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryColor
                                          .withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.layers_rounded,
                                      size: 16,
                                      color: AppColors.primaryColor
                                          .withOpacity(0.7),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          lot.name,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? AppColors.primaryColor
                                                : const Color(0xFF0F172A),
                                          ),
                                        ),
                                        if (lot.description
                                            .trim()
                                            .isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            lot.description,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              color: const Color(0xFF94A3B8),
                                            ),
                                          ),
                                        ],
                                      ],
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
          ),
        ),
      );
    });
  }
}
