import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/organization.dart';
import '../controllers/organization_controller.dart';

class EditOrganizationPage extends StatefulWidget {
  final Organization organization;

  const EditOrganizationPage({super.key, required this.organization});

  @override
  State<EditOrganizationPage> createState() => _EditOrganizationPageState();
}

class _EditOrganizationPageState extends State<EditOrganizationPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  String? _selectedOrganismeType;

  // ✅ Display values — unique + sorted
  final List<String> _organismeTypes = [
    'Bureau d\'Étude',
    'Bureau de Contrôle',
    'Entreprise d\'Exécution',
  ];

  // ✅ Mapping: normalize backend values to display values
  static const Map<String, String> _normalizeBackendMap = {
    'bureau de controle': 'Bureau de Contrôle',
    'bureau d\'etude': "Bureau d'Étude",
    'entreprise d\'execution': "Entreprise d'Exécution",
  };

  // ✅ Helper: convert backend → display value
  String _getDisplayValue(String? backendValue) {
    if (backendValue == null) return '';
    final normalized = backendValue.toLowerCase();
    return _normalizeBackendMap[normalized] ?? backendValue;
  }

  // ✅ Helper: convert display → backend value
  String _getBackendValue(String? displayValue) {
    if (displayValue == null) return '';
    final reverseMap = <String, String>{};
    _normalizeBackendMap.forEach((backend, display) {
      reverseMap[display] = backend;
    });
    return reverseMap[displayValue] ?? displayValue;
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.organization.name);
    _descriptionController =
        TextEditingController(text: widget.organization.description ?? '');
    // Normalize backend value to display value
    _selectedOrganismeType =
        _getDisplayValue(widget.organization.organismeType);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OrganizationController>();

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'edit_organization'.tr,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header Card ───────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryColor.withOpacity(0.08),
                      AppColors.primaryColor.withOpacity(0.03),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primaryColor.withOpacity(0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.business_outlined,
                        color: AppColors.primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'edit_organization'.tr,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'update_organization_info'.tr,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Section: Informations Générales ───────────────────
              _buildSectionTitle('general_information'.tr, Icons.info_outline),
              const SizedBox(height: 16),

              // 1. Nom de l'organisation
              _buildTextField(
                controller: _nameController,
                label: 'organization_name'.tr,
                hint: 'enter_organization_name'.tr,
                icon: Icons.business,
                validator: (value) {
                  try {
                    if (value == null || value.trim().isEmpty) {
                      return 'please_enter_organization_name'.tr;
                    }
                    if (value.trim().length < 2) {
                      return 'name_too_short'.tr;
                    }

                    // ✅ Vérifier les doublons (sauf pour le nom actuel)
                    if (value.trim() != widget.organization.name) {
                      try {
                        final controller = Get.find<OrganizationController>();
                        if (controller
                            .doesOrganizationNameExist(value.trim())) {
                          return 'Organization with name "$value" already exists';
                        }
                      } catch (e) {
                        debugPrint('Controller error in validator: $e');
                      }
                    }

                    return null;
                  } catch (e) {
                    debugPrint('Validator error: $e');
                    return null;
                  }
                },
              ),
              const SizedBox(height: 20),

              // 2. Type d'organisme (Dropdown)
              _buildDropdownField(
                label: 'organisme_type'.tr,
                hint: 'select_organisme_type'.tr,
                icon: Icons.category_outlined,
                value: _selectedOrganismeType,
                items: _organismeTypes,
                onChanged: (value) {
                  setState(() => _selectedOrganismeType = value);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'please_select_organisme_type'.tr;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 3. Description de l'organisme ✅
              _buildTextField(
                controller: _descriptionController,
                label: 'organisme_description'.tr,
                hint: 'enter_organisme_description'.tr,
                icon: Icons.description_outlined,
                maxLines: 4,
                keyboardType: TextInputType.multiline,
                validator: (value) => null, // optional
              ),
              const SizedBox(height: 40),

              // ─── Buttons Row ────────────────────────────────────────
              Row(
                children: [
                  // Cancel Button
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: AppColors.textSecondary.withOpacity(0.3),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'cancel'.tr,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Save Button
                  Expanded(
                    child: Obx(() => SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: controller.isLoading.value
                                ? null
                                : () async {
                                    // ✅ تحقق من mounted قبل validation
                                    if (!mounted) return;

                                    if (_formKey.currentState!.validate()) {
                                      try {
                                        // ✅ حفظ القيم قبل async
                                        final name =
                                            _nameController.text.trim();
                                        final description =
                                            _descriptionController.text.trim();
                                        final organismeType = _getBackendValue(
                                            _selectedOrganismeType);

                                        final updatedOrganization =
                                            Organization(
                                          id: widget.organization.id,
                                          name: name,
                                          createdAt:
                                              widget.organization.createdAt,
                                          organismeType: organismeType,
                                          description: description,
                                        );

                                        await controller.updateOrganization(
                                            updatedOrganization);

                                        // ✅ تحقق من mounted
                                        if (!mounted) return;

                                        Get.back();
                                        Get.snackbar(
                                          'success'.tr,
                                          'organization_updated'.tr,
                                          backgroundColor: AppColors.success,
                                          colorText: AppColors.white,
                                          snackPosition: SnackPosition.BOTTOM,
                                          margin: const EdgeInsets.all(16),
                                          borderRadius: 12,
                                          icon: const Icon(Icons.check_circle,
                                              color: Colors.white),
                                        );
                                      } catch (e) {
                                        // ✅ تحقق من mounted قبل setState
                                        if (!mounted) return;

                                        Get.snackbar(
                                          'error'.tr,
                                          'failed_to_update_organization'.tr,
                                          backgroundColor: AppColors.error,
                                          colorText: AppColors.white,
                                          snackPosition: SnackPosition.BOTTOM,
                                          margin: const EdgeInsets.all(16),
                                          borderRadius: 12,
                                          icon: const Icon(Icons.error_outline,
                                              color: Colors.white),
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              disabledBackgroundColor:
                                  AppColors.primaryColor.withOpacity(0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: controller.isLoading.value
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.save_outlined,
                                          color: Colors.white, size: 20),
                                      const SizedBox(width: 10),
                                      Text(
                                        'save'.tr,
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        )),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Section Title Widget ─────────────────────────────────────────────
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Divider(
            color: AppColors.textSecondary.withOpacity(0.3),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  // ─── Text Field Widget ────────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
            prefixIcon: Icon(icon, color: AppColors.primaryColor, size: 20),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceVariant,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primaryColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  // ─── Dropdown Field Widget ────────────────────────────────────────────
  Widget _buildDropdownField({
    required String label,
    required String hint,
    required IconData icon,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required String? Function(String?) validator,
  }) {
    // ✅ Fix 1: Eliminate duplicates
    final uniqueItems = items.toSet().toList();

    // ✅ Fix 2: Ensure value is in items, otherwise set to null
    final validValue =
        value != null && uniqueItems.contains(value) ? value : null;

    // ✅ Fix 3: Show loading if list is empty
    if (uniqueItems.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.textSecondary.withOpacity(0.3),
              ),
              borderRadius: BorderRadius.circular(10),
              color: Theme.of(context).colorScheme.surfaceVariant,
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(
                  'loading'.tr,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: validValue,
          items: uniqueItems
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(item),
                ),
              )
              .toList(),
          onChanged: onChanged,
          validator: validator,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
            prefixIcon: Icon(icon, color: AppColors.primaryColor, size: 20),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceVariant,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primaryColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
