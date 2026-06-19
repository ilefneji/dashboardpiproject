import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/organization.dart';
import '../controllers/organization_controller.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 🔧 Backend Type Options — matches OrganismeType enum exactly (all 4)
// ═══════════════════════════════════════════════════════════════════════════

const List<Map<String, String>> _organismeTypeOptions = [
  {'display': "Bureau d'Étude", 'backend': "Bureau d'Étude"},
  {'display': 'Bureau de Contrôle', 'backend': 'Bureau de Contrôle'},
  {'display': "Entreprise d'Exécution", 'backend': "Entreprise d'Exécution"},
  {'display': 'Autre', 'backend': 'Autre'}, // ✅ FIX: was missing
];

// ✅ Derived once — const-aligned
final List<String> _displayValues =
    _organismeTypeOptions.map((e) => e['display']!).toList();

/// Backend value → display label (for edit pre-fill)
String _getDisplayValue(String? backendValue) {
  if (backendValue == null || backendValue.isEmpty) return '';
  final match = _organismeTypeOptions.firstWhere(
    (e) => e['backend']!.toLowerCase() == backendValue.toLowerCase(),
    orElse: () => {'display': backendValue, 'backend': backendValue},
  );
  return match['display']!;
}

/// Display label → backend value (for submit payload)
String? _getBackendValue(String? displayValue) {
  if (displayValue == null || displayValue.isEmpty) return null;
  final match = _organismeTypeOptions.firstWhere(
    (e) => e['display'] == displayValue,
    orElse: () => {'display': displayValue, 'backend': displayValue},
  );
  return match['backend'];
}

// ═══════════════════════════════════════════════════════════════════════════
// 📄 OrganizationFormDialog
// ═══════════════════════════════════════════════════════════════════════════

class OrganizationFormDialog extends StatefulWidget {
  final Organization? organization;

  const OrganizationFormDialog({super.key, this.organization});

  @override
  State<OrganizationFormDialog> createState() => _OrganizationFormDialogState();
}

class _OrganizationFormDialogState extends State<OrganizationFormDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;

  String? _selectedType;
  bool _isSubmitting = false; // ✅ local flag — decoupled from controller

  // ─────────────────────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: widget.organization?.name ?? '',
    );
    _descCtrl = TextEditingController(
      text: widget.organization?.description ?? '',
    );

    // ✅ Pre-fill type for edit — normalize backend → display
    final rawType = widget.organization?.organismeType;
    final displayVal = (rawType != null && rawType.isNotEmpty)
        ? _getDisplayValue(rawType)
        : null;

    _selectedType = (displayVal != null && _displayValues.contains(displayVal))
        ? displayVal
        : null;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────
  // VALIDATION
  // ─────────────────────────────────────────────────────────────────

  String? _validateForm(OrganizationController controller) {
    final name = _nameCtrl.text.trim();

    if (name.isEmpty) return 'organization_name_required'.tr;
    if (name.length < 2) return 'name_too_short'.tr;

    // ✅ On edit — exclude self from duplicate check
    final excludeId = widget.organization?.id;
    if (controller.doesOrganizationNameExist(name, excludeId: excludeId)) {
      return 'organization_name_exists'.tr;
    }

    if (_selectedType == null) return 'please_select_organisme_type'.tr;

    return null; // ✅ valid
  }

  // ─────────────────────────────────────────────────────────────────
  // SUBMIT
  // ─────────────────────────────────────────────────────────────────

  Future<void> _submit(OrganizationController controller) async {
    FocusScope.of(context).unfocus();

    // ✅ Validate first — show one targeted snackbar, not a generic one
    final validationError = _validateForm(controller);
    if (validationError != null) {
      Get.snackbar(
        'error'.tr,
        validationError,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final name = _nameCtrl.text.trim();
      final description =
          _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim();
      final backendType = _getBackendValue(_selectedType);
      final isEdit = widget.organization != null;

      bool success;

      if (isEdit) {
        // ✅ Preserve all original fields — only patch what user changed
        success = await controller.updateOrganization(
          widget.organization!.copyWith(
            name: name,
            description: description,
            organismeType: backendType,
          ),
        );
      } else {
        // ✅ FIX: id is required non-nullable — pass 0 as create placeholder
        // ✅ FIX: do NOT send createdAt — backend generates it
        success = await controller.createOrganization(
          Organization(
            id: 0,
            name: name,
            description: description,
            organismeType: backendType,
          ),
        );
      }

      // ✅ FIX: only close if operation succeeded
      // controller already showed success/error snackbar — no duplicate here
      if (success && mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // ✅ FIX: this should rarely fire — controller handles errors internally
      // Only fires if something unexpected blew up outside controller
      debugPrint('❌ OrganizationFormDialog unexpected error: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // INPUT DECORATION
  // ─────────────────────────────────────────────────────────────────

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        fontSize: 14,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 14.0, right: 10.0),
        child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF374151)
              : const Color(0xFFE2E8F0),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF374151)
              : const Color(0xFFE2E8F0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OrganizationController>();
    final isEdit = widget.organization != null;

    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ══════════════════════════════════════════════
              // 🔷 Header
              // ══════════════════════════════════════════════
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isEdit ? Icons.edit_outlined : Icons.business_outlined,
                      size: 20,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit
                              ? 'edit_organization'.tr
                              : 'add_organization'.tr,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isEdit
                              ? 'update_organization_info'.tr
                              : 'fill_organization_info'.tr,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Close button
                  IconButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    splashRadius: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 24),

              // ══════════════════════════════════════════════
              // ✏️ Name Field
              // ══════════════════════════════════════════════
              const _FieldLabel(
                label: "Nom de l'organisation",
                required: true,
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _nameCtrl,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration(
                  hint: "Nom de l'organisation",
                  icon: Icons.business_outlined,
                ),
              ),

              const SizedBox(height: 16),

              // ══════════════════════════════════════════════
              // 📝 Description Field (optional)
              // ══════════════════════════════════════════════
              const _FieldLabel(label: 'Description'),
              const SizedBox(height: 6),
              TextField(
                controller: _descCtrl,
                maxLines: 3,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: _inputDecoration(
                  hint: "Brève description de l'organisation...",
                  icon: Icons.description_outlined,
                ).copyWith(
                  prefixIcon: null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ══════════════════════════════════════════════
              // 🏷️ Type Dropdown
              // ══════════════════════════════════════════════
              const _FieldLabel(
                label: "Type d'organisation",
                required: true,
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: (_selectedType != null &&
                        _displayValues.contains(_selectedType))
                    ? _selectedType
                    : null,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                decoration: _inputDecoration(
                  hint: 'Sélectionnez un type',
                  icon: Icons.category_outlined,
                ),
                hint: Text(
                  'Sélectionnez un type',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                borderRadius: BorderRadius.circular(10),
                items: _displayValues.map((display) {
                  return DropdownMenuItem<String>(
                    value: display,
                    child: Text(
                      display,
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedType = v),
              ),

              const SizedBox(height: 28),
              const Divider(height: 1),
              const SizedBox(height: 20),

              // ══════════════════════════════════════════════
              // 🔘 Action Buttons
              // ══════════════════════════════════════════════
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // ── Cancel ──────────────────────────────
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF374151)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                    child: Text(
                      'cancel'.tr,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // ── Submit ──────────────────────────────
                  SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.primaryColor.withOpacity(0.5),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed:
                          _isSubmitting ? null : () => _submit(controller),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              isEdit ? Icons.save_outlined : Icons.add_rounded,
                              size: 18,
                            ),
                      label: Text(
                        _isSubmitting
                            ? 'saving'.tr
                            : isEdit
                                ? 'save'.tr
                                : 'add'.tr,
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
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🏷️ _FieldLabel
// ═══════════════════════════════════════════════════════════════════════════

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool required;

  const _FieldLabel({required this.label, this.required = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 3),
          const Text(
            '*',
            style: TextStyle(
              color: Color(0xFFEF4444),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}
