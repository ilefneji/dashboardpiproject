import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../lot/presentation/controllers/lot_controller.dart';
import '../../presentation/controllers/project_controller.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  ProjectFormDialog
// ═══════════════════════════════════════════════════════════════════════════

class ProjectFormDialog extends StatefulWidget {
  final bool isEditing;
  final int? projectId;
  final String? initialName;
  final String? initialDescription;
  final String? initialStartDate;
  final String? initialEndDate;
  final int? initialBudget;
  final String? initialLocalisation;
  final String? initialLatitude;
  final String? initialLongitude;
  final List<int> initialLotIds;

  const ProjectFormDialog({
    super.key,
    this.isEditing = false,
    this.projectId,
    this.initialName,
    this.initialDescription,
    this.initialStartDate,
    this.initialEndDate,
    this.initialBudget,
    this.initialLocalisation,
    this.initialLatitude,
    this.initialLongitude,
    this.initialLotIds = const [],
  });

  @override
  State<ProjectFormDialog> createState() => _ProjectFormDialogState();
}

// ═══════════════════════════════════════════════════════════════════════════
//  _ProjectFormDialogState
// ═══════════════════════════════════════════════════════════════════════════

class _ProjectFormDialogState extends State<ProjectFormDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _startDateCtrl;
  late final TextEditingController _endDateCtrl;
  late final TextEditingController _budgetCtrl;
  late final TextEditingController _localisationCtrl;

  String? _latitude;
  String? _longitude;
  final Set<int> _selectedLotIds = <int>{};
  bool _isLoading = false;

  late final ProjectController _projectController;
  late final LotController _lotController;

  @override
  void initState() {
    super.initState();
    _projectController = Get.find<ProjectController>();
    _lotController = Get.find<LotController>();

    _nameCtrl = TextEditingController(text: widget.initialName ?? '');
    _descCtrl = TextEditingController(text: widget.initialDescription ?? '');
    _startDateCtrl = TextEditingController(
      text: _normalizeDate(widget.initialStartDate ?? ''),
    );
    _endDateCtrl = TextEditingController(
      text: _normalizeDate(widget.initialEndDate ?? ''),
    );
    _budgetCtrl = TextEditingController(
      text: widget.initialBudget != null && widget.initialBudget! > 0
          ? widget.initialBudget.toString()
          : '',
    );
    _localisationCtrl =
        TextEditingController(text: widget.initialLocalisation ?? '');
    _latitude = widget.initialLatitude;
    _longitude = widget.initialLongitude;
    _selectedLotIds.addAll(widget.initialLotIds);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _startDateCtrl.dispose();
    _endDateCtrl.dispose();
    _budgetCtrl.dispose();
    _localisationCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        fontSize: 14,
        color: const Color(0xFF94A3B8),
      ),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 14, right: 10),
        child: Icon(
          icon,
          size: 20,
          color: const Color(0xFF94A3B8),
        ),
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        borderSide: const BorderSide(color: AppColors.primaryColor, width: 1.5),
      ),
    );
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(controller.text) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primaryColor,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _openMap() async {
    final result = await showDialog<Map<String, String>?>(
      context: context,
      builder: (_) => const _SelectMapPage(),
    );
    if (result != null && mounted) {
      setState(() {
        _localisationCtrl.text = result['name'] ?? '';
        _latitude = result['latitude'];
        _longitude = result['longitude'];
      });
    }
  }

  String _normalizeDate(String value) {
    final v = value.trim();
    if (v.isEmpty) return '';
    final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (regex.hasMatch(v)) return v;
    final parsed = DateTime.tryParse(v);
    if (parsed == null) return '';
    return DateFormat('yyyy-MM-dd').format(parsed);
  }

  Widget _buildLotSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FieldLabel(label: 'Lots associés'),
        const SizedBox(height: 6),
        Obx(() {
          final lots = _lotController.lots;
          if (lots.isEmpty) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.layers_rounded,
                    size: 18,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Aucun lot disponible',
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
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: lots.length,
                itemBuilder: (context, index) {
                  final lot = lots[index];
                  final isSelected = _selectedLotIds.contains(lot.safeId);
                  return CheckboxListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    title: Text(
                      lot.name,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    subtitle: lot.description.isNotEmpty
                        ? Text(
                            lot.description,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF94A3B8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    value: isSelected,
                    activeColor: AppColors.primaryColor,
                    onChanged: (_) {
                      setState(() {
                        if (isSelected) {
                          _selectedLotIds.remove(lot.safeId);
                        } else {
                          _selectedLotIds.add(lot.safeId);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    debugPrint(
        '>>> ProjectFormDialog.build called — isEditing=${widget.isEditing}');

    final mq = MediaQuery.of(context);
    final screenSize = mq.size;
    final isMobileLayout = screenSize.width < 600;
    final dialogPadding = isMobileLayout ? 16.0 : 28.0;
    final dialogRadius = isMobileLayout ? 0.0 : 16.0;

    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      insetPadding: isMobileLayout
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(dialogRadius),
      ),
      elevation: 0,
      child: SizedBox(
        width: isMobileLayout ? screenSize.width : 520,
        height: isMobileLayout ? screenSize.height : screenSize.height * 0.86,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            dialogPadding,
            dialogPadding + mq.padding.top,
            dialogPadding,
            dialogPadding + mq.padding.bottom,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const headerHeight = 72.0;
              const actionsHeight = 70.0;
              const spacingHeight = 48.0; // SizedBoxes + Dividers
              final bodyHeight = (constraints.maxHeight -
                      headerHeight -
                      actionsHeight -
                      spacingHeight)
                  .clamp(100.0, double.infinity);

              return Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ──────────────────────────────────────────────
                  SizedBox(
                    height: headerHeight,
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            widget.isEditing
                                ? Icons.edit_outlined
                                : Icons.work_outlined,
                            size: 20,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.isEditing
                                    ? 'Modifier le projet'
                                    : 'Ajouter un projet',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.isEditing
                                    ? 'Mettez à jour les informations ci-dessous'
                                    : 'Remplissez les informations ci-dessous',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              Navigator.of(context, rootNavigator: true).pop(),
                          icon: const Icon(Icons.close_rounded, size: 20),
                          color: const Color(0xFF94A3B8),
                          splashRadius: 20,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                  const Divider(color: Color(0xFFF1F5F9), height: 1),
                  const SizedBox(height: 12),

                  // ── Body scrollable (SizedBox + SingleChildScrollView) ──
                  SizedBox(
                    height: bodyHeight,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Name
                          const _FieldLabel(label: 'Nom du projet'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _nameCtrl,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF0F172A),
                            ),
                            decoration: _inputDecoration(
                              hint: 'nom du projet',
                              icon: Icons.work_outlined,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ── Description
                          const _FieldLabel(label: 'Description'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _descCtrl,
                            maxLines: 3,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF0F172A),
                            ),
                            decoration: _inputDecoration(
                              hint: 'Brève description du projet...',
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

                          // ── Start Date
                          const _FieldLabel(label: 'Date de début'),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () => _selectDate(_startDateCtrl),
                            child: AbsorbPointer(
                              child: TextField(
                                controller: _startDateCtrl,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFF0F172A),
                                ),
                                decoration: _inputDecoration(
                                  hint: 'YYYY-MM-DD',
                                  icon: Icons.calendar_today_rounded,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ── End Date
                          const _FieldLabel(label: 'Date de fin'),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () => _selectDate(_endDateCtrl),
                            child: AbsorbPointer(
                              child: TextField(
                                controller: _endDateCtrl,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFF0F172A),
                                ),
                                decoration: _inputDecoration(
                                  hint: 'YYYY-MM-DD',
                                  icon: Icons.calendar_today_rounded,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ── Budget
                          const _FieldLabel(label: 'Budget'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _budgetCtrl,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF0F172A),
                            ),
                            decoration: _inputDecoration(
                              hint: 'BUDGET',
                              icon: Icons.currency_exchange_rounded,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ── Localisation
                          const _FieldLabel(label: 'Localisation'),
                          const SizedBox(height: 6),
                          InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: _openMap,
                            child: AbsorbPointer(
                              child: TextField(
                                controller: _localisationCtrl,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFF0F172A),
                                ),
                                decoration: _inputDecoration(
                                  hint: 'Appuyez pour choisir sur la carte',
                                  icon: Icons.location_on_rounded,
                                ).copyWith(
                                  suffixIcon: const Padding(
                                    padding: EdgeInsets.only(right: 12.0),
                                    child: Icon(
                                      Icons.map_outlined,
                                      size: 20,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                  suffixIconConstraints: const BoxConstraints(
                                    minWidth: 0,
                                    minHeight: 0,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // ── Coordinates badge
                          if (_latitude != null && _longitude != null) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color:
                                      AppColors.primaryColor.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.gps_fixed_rounded,
                                    size: 14,
                                    color: AppColors.primaryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Lat: $_latitude  •  Lng: $_longitude',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.primaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => setState(() {
                                      _latitude = null;
                                      _longitude = null;
                                      _localisationCtrl.clear();
                                    }),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      size: 16,
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),

                          // ── Lots
                          _buildLotSelector(),

                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFF1F5F9), height: 1),
                  const SizedBox(height: 12),

                  // ── Actions ─────────────────────────────────────────────
                  SizedBox(
                    height: actionsHeight,
                    child: Flex(
                      direction:
                          isMobileLayout ? Axis.vertical : Axis.horizontal,
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: isMobileLayout ? double.infinity : null,
                          height: 44,
                          child: TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.of(
                                      context,
                                      rootNavigator: true,
                                    ).pop(),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF64748B),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side:
                                    const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                            child: Text(
                              'Annuler',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: isMobileLayout ? 0 : 12,
                          height: isMobileLayout ? 12 : 0,
                        ),
                        SizedBox(
                          width: isMobileLayout ? double.infinity : null,
                          height: 44,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _isLoading
                                ? null
                                : () async {
                                    final name = _nameCtrl.text.trim();
                                    final description = _descCtrl.text.trim();
                                    final startDate = _normalizeDate(
                                      _startDateCtrl.text,
                                    );
                                    final endDate =
                                        _normalizeDate(_endDateCtrl.text);
                                    final budgetStr = _budgetCtrl.text.trim();
                                    final localisation =
                                        _localisationCtrl.text.trim();

                                    if (name.isEmpty) {
                                      Get.snackbar(
                                        'Erreur',
                                        'Le nom est requis',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: AppColors.error,
                                        colorText: Colors.white,
                                      );
                                      return;
                                    }

                                    setState(() => _isLoading = true);

                                    try {
                                      final budget = budgetStr.isNotEmpty
                                          ? int.tryParse(budgetStr) ?? 0
                                          : 0;

                                      if (widget.isEditing &&
                                          widget.projectId != null) {
                                        await _projectController.updateProject(
                                          widget.projectId!,
                                          name: name,
                                          description: description,
                                          startDate: startDate,
                                          endDate: endDate,
                                          budget: budget,
                                          localisation: localisation,
                                          latitude: _latitude,
                                          longitude: _longitude,
                                          lotIds: _selectedLotIds.toList(),
                                        );
                                      } else {
                                        await _projectController.createProject(
                                          name: name,
                                          description: description,
                                          startDate: startDate,
                                          endDate: endDate,
                                          budget: budget,
                                          localisation: localisation,
                                          latitude: _latitude,
                                          longitude: _longitude,
                                          lotIds: _selectedLotIds.toList(),
                                        );
                                      }

                                      await _projectController.getAllProjects();

                                      if (mounted) {
                                        Navigator.of(
                                          context,
                                          rootNavigator: true,
                                        ).pop(true);
                                      }
                                    } finally {
                                      if (mounted) {
                                        setState(() => _isLoading = false);
                                      }
                                    }
                                  },
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    widget.isEditing
                                        ? Icons.save_outlined
                                        : Icons.add_rounded,
                                    size: 18,
                                  ),
                            label: Text(
                              widget.isEditing ? 'Enregistrer' : 'Ajouter',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── _FieldLabel ───────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF374151),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  _SelectMapPage
// ═══════════════════════════════════════════════════════════════
// ✅ Remove onLocationSelected entirely
class _SelectMapPage extends StatefulWidget {
  const _SelectMapPage();

  @override
  State<_SelectMapPage> createState() => _SelectMapPageState();
}

// ═══════════════════════════════════════════════════════════════
//  _SelectMapPageState
// ═══════════════════════════════════════════════════════════════
class _SelectMapPageState extends State<_SelectMapPage> with OSMMixinObserver {
  late MapController _mapController;

  static const double _defaultLat = 36.8065;
  static const double _defaultLng = 10.1815;

  GeoPoint? _selectedPoint;
  String? _selectedAddress;
  bool _isLoadingLocation = true;
  bool _isReverseGeocoding = false;
  bool _mapReady = false;
  bool _isTapProcessing = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController(
      initPosition: GeoPoint(latitude: _defaultLat, longitude: _defaultLng),
    );
    _mapController.addObserver(this);
  }

  @override
  void dispose() {
    _mapController.removeObserver(this);
    _mapController.dispose();
    super.dispose();
  }

  Widget _overlayFix(Widget child) {
    if (kIsWeb) {
      return PointerInterceptor(child: child);
    }
    return child;
  }

  @override
  Future<void> mapIsReady(bool isReady) async {
    if (isReady && mounted && !_mapReady) {
      setState(() {
        _mapReady = true;
        _isLoadingLocation = false;
      });
    }
  }

  @override
  void onSingleTap(GeoPoint position) {
    super.onSingleTap(position);
    debugPrint('✅ onSingleTap: ${position.latitude}, ${position.longitude}');
    if (_mapReady && mounted && !_isTapProcessing) {
      _onMapTap(position);
    }
  }

  @override
  void onLongTap(GeoPoint position) {
    super.onLongTap(position);
    debugPrint('✅ onLongTap: ${position.latitude}, ${position.longitude}');
    if (_mapReady && mounted && !_isTapProcessing) {
      _onMapTap(position);
    }
  }

  Future<void> _onMapTap(GeoPoint point) async {
    if (!mounted || _isTapProcessing) return;

    final previousPoint = _selectedPoint;

    setState(() {
      _isTapProcessing = true;
      _selectedPoint = point;
      _isReverseGeocoding = true;
      _selectedAddress = null;
    });

    debugPrint('📍 Processing tap: ${point.latitude}, ${point.longitude}');

    if (previousPoint != null) {
      try {
        await _mapController.removeMarkers([previousPoint]);
      } catch (_) {}
    }

    try {
      await _mapController.addMarker(
        point,
        markerIcon: const MarkerIcon(
          icon: Icon(Icons.location_pin, color: Colors.red, size: 48),
        ),
      );
      debugPrint('📌 Marker added');
    } catch (e) {
      debugPrint('⚠️ Marker error: $e');
    }

    String address = '${point.latitude.toStringAsFixed(5)}, '
        '${point.longitude.toStringAsFixed(5)}';

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?format=json'
        '&lat=${point.latitude}'
        '&lon=${point.longitude}'
        '&accept-language=fr',
      );

      debugPrint('🌐 Nominatim request: $uri');

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'ConstructionDashboard/1.0',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 8));

      debugPrint('📡 Nominatim status: ${response.statusCode}');
      debugPrint('📡 Nominatim body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final addr = data['address'] as Map<String, dynamic>?;

        if (addr != null) {
          final parts = <String>[];

          final road = addr['road'] as String?;
          if (road != null && road.trim().isNotEmpty) {
            parts.add(road.trim());
          }

          final suburb = (addr['suburb'] ?? addr['neighbourhood']) as String?;
          if (suburb != null && suburb.trim().isNotEmpty) {
            parts.add(suburb.trim());
          }

          final city = (addr['city'] ??
              addr['town'] ??
              addr['village'] ??
              addr['municipality']) as String?;
          if (city != null && city.trim().isNotEmpty) {
            parts.add(city.trim());
          }

          final state = addr['state'] as String?;
          if (state != null && state.trim().isNotEmpty) {
            parts.add(state.trim());
          }

          final country = addr['country'] as String?;
          if (country != null && country.trim().isNotEmpty) {
            parts.add(country.trim());
          }

          if (parts.isNotEmpty) {
            address = parts.join(', ');
          }

          debugPrint('🏠 Address resolved: $address');
        } else {
          final displayName = data['display_name'] as String?;
          if (displayName != null && displayName.isNotEmpty) {
            address = displayName;
            debugPrint('🏠 Using display_name: $address');
          }
        }
      } else {
        debugPrint('⚠️ Nominatim bad status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('⚠️ Nominatim error: $e — using coordinates fallback');
    }

    if (mounted) {
      setState(() {
        _selectedAddress = address;
        _isReverseGeocoding = false;
        _isTapProcessing = false;
      });
      debugPrint('🔎 _selectedAddress = $_selectedAddress');
      debugPrint('🔎 _selectedPoint   = $_selectedPoint');
    }
  }

  void _confirm() {
    debugPrint('🟢 _confirm called');

    if (_selectedPoint == null) return;

    final result = <String, String>{
      'name': _selectedAddress ??
          '${_selectedPoint!.latitude.toStringAsFixed(5)}, '
              '${_selectedPoint!.longitude.toStringAsFixed(5)}',
      'latitude': _selectedPoint!.latitude.toString(),
      'longitude': _selectedPoint!.longitude.toString(),
    };

    debugPrint('✅ Confirming: $result');
    Navigator.of(context, rootNavigator: true).pop(result);
  }

  void _close() {
    debugPrint('❌ Map closed without selection');
    Navigator.of(context, rootNavigator: true).pop(null);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: Stack(
          children: [
            Positioned.fill(
              child: OSMFlutter(
                controller: _mapController,
                onMapIsReady: (isReady) {
                  if (isReady && mounted && !_mapReady) {
                    setState(() {
                      _mapReady = true;
                      _isLoadingLocation = false;
                    });
                  }
                },
                osmOption: OSMOption(
                  enableRotationByGesture: false,
                  zoomOption: const ZoomOption(
                    initZoom: 13,
                    minZoomLevel: 3,
                    maxZoomLevel: 19,
                    stepZoom: 1.0,
                  ),
                  userLocationMarker: UserLocationMaker(
                    personMarker: const MarkerIcon(
                      icon: Icon(
                        Icons.my_location,
                        color: Colors.blue,
                        size: 32,
                      ),
                    ),
                    directionArrowMarker: const MarkerIcon(
                      icon: Icon(Icons.navigation, size: 32),
                    ),
                  ),
                ),
                mapIsLoading: const Center(child: CircularProgressIndicator()),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _overlayFix(
                SafeArea(
                  bottom: false,
                  child: Container(
                    color: Theme.of(context).colorScheme.surface,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF0F172A),
                          ),
                          onPressed: _close,
                        ),
                        Expanded(
                          child: Text(
                            'Choisir un emplacement',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_isLoadingLocation)
              Positioned.fill(
                child: Container(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.6),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
            if (_mapReady && _selectedPoint == null)
              Positioned(
                top: 72,
                left: 16,
                right: 16,
                child: _overlayFix(
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.touch_app_rounded,
                            size: 16,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tapez sur la carte pour choisir',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (_selectedPoint != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _overlayFix(
                  SafeArea(
                    top: false,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.10),
                            blurRadius: 16,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor.withOpacity(
                                    0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  color: AppColors.primaryColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _isReverseGeocoding
                                    ? Row(
                                        children: [
                                          const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Récupération de l\'adresse...',
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: const Color(0xFF94A3B8),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _selectedAddress ??
                                                'Adresse inconnue',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF0F172A),
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Lat: ${_selectedPoint!.latitude.toStringAsFixed(5)}'
                                            '  •  Lng: ${_selectedPoint!.longitude.toStringAsFixed(5)}',
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              color: const Color(0xFF94A3B8),
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                debugPrint('🔴 CONFIRM BUTTON CLICKED');
                                _confirm();
                              },
                              icon: _isReverseGeocoding
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.check_rounded, size: 18),
                              label: Text(
                                _isReverseGeocoding
                                    ? 'Recherche de l\'adresse...'
                                    : 'Confirmer cet emplacement',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
