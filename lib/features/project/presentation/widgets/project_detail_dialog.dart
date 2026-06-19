import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/project_model.dart';
import '../../presentation/controllers/project_controller.dart';
import 'project_form_dialog.dart';

class ProjectDetailDialog extends StatefulWidget {
  final ProjectModel project;

  const ProjectDetailDialog({super.key, required this.project});

  @override
  State<ProjectDetailDialog> createState() => _ProjectDetailDialogState();
}

class _ProjectDetailDialogState extends State<ProjectDetailDialog> {
  late ProjectModel _project;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _project = widget.project; // ✅ show basic data immediately while loading
    _fetchFullProject();
  }

  Future<void> _fetchFullProject() async {
    try {
      final controller = Get.find<ProjectController>();
      final full = await controller.getProject(widget.project.id);

      if (!mounted) return;

      if (full != null) {
        setState(() {
          _project = full;
          _isLoading = false;
          _hasError = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ _fetchFullProject error: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ── Header ──────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.work_outlined,
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
                          'Détails du projet',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _project.name,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF94A3B8),
                          ),
                          overflow: TextOverflow.ellipsis,
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

              const SizedBox(height: 24),
              const Divider(color: Color(0xFFF1F5F9), height: 1),
              const SizedBox(height: 20),

              /// ── Body ─────────────────────────────────────────────
              if (_isLoading)

                /// ── Loading State ──────────────────────────────────
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_hasError)

                /// ── Error State ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 36,
                          color: Color(0xFFEF4444),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Impossible de charger les détails',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _hasError = false;
                            });
                            _fetchFullProject();
                          },
                          child: Text(
                            'Réessayer',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else

                /// ── Scrollable Content ─────────────────────────────
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 420),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// ── Nom ─────────────────────────────────────
                        _InfoRow(
                          icon: Icons.work_outline_rounded,
                          label: 'Nom',
                          value: _project.name.isNotEmpty ? _project.name : '—',
                        ),

                        const SizedBox(height: 14),

                        /// ── Description ─────────────────────────────
                        _InfoRow(
                          icon: Icons.description_outlined,
                          label: 'Description',
                          value: _project.description.isNotEmpty
                              ? _project.description
                              : '—',
                        ),

                        const SizedBox(height: 14),

                        /// ── Dates ────────────────────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: _InfoCard(
                                icon: Icons.calendar_today_rounded,
                                label: 'Date de début',
                                value: _project.startDate.isNotEmpty
                                    ? _formatDate(_project.startDate)
                                    : '—',
                                iconColor: const Color(0xFF10B981),
                                bgColor: const Color(0xFFECFDF5),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _InfoCard(
                                icon: Icons.event_rounded,
                                label: 'Date de fin',
                                value: _project.endDate.isNotEmpty
                                    ? _formatDate(_project.endDate)
                                    : '—',
                                iconColor: const Color(0xFFEF4444),
                                bgColor: const Color(0xFFFEF2F2),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        /// ── Budget ───────────────────────────────────
                        _InfoCard(
                          icon: Icons.currency_exchange_rounded,
                          label: 'Budget',
                          value: _project.budget != 0
                              ? '${_project.budget} TND'
                              : '—',
                          iconColor: const Color(0xFF8B5CF6),
                          bgColor: const Color(0xFFF5F3FF),
                          fullWidth: true,
                        ),

                        const SizedBox(height: 14),

                        /// ── Localisation ─────────────────────────────
                        _InfoCard(
                          icon: Icons.location_on_rounded,
                          label: 'Localisation',
                          value: _project.localisation.isNotEmpty
                              ? _project.localisation
                              : '—',
                          iconColor: const Color(0xFF3B82F6),
                          bgColor: const Color(0xFFEFF6FF),
                          fullWidth: true,
                        ),

                        /// ── Lots ─────────────────────────────────────
                        if (_project.lots.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _LotsSection(lots: _project.lots),
                        ],
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),
              const Divider(color: Color(0xFFF1F5F9), height: 1),
              const SizedBox(height: 20),

              /// ── Action Buttons ────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Color(0xFFE2E8F0), width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () =>
                          Navigator.of(context, rootNavigator: true).pop(),
                      child: Text(
                        'Fermer',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      // ✅ disable Modifier button while loading
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.of(context, rootNavigator: true).pop();
                              showDialog(
                                context: context,
                                useRootNavigator: true,
                                builder: (_) => ProjectFormDialog(
                                  isEditing: true,
                                  projectId: _project.id,
                                  initialName: _project.name,
                                  initialDescription: _project.description,
                                  initialStartDate: _project.startDate,
                                  initialEndDate: _project.endDate,
                                  initialBudget: _project.budget,
                                  initialLocalisation: _project.localisation,
                                  initialLatitude: _project.latitude,
                                  initialLongitude: _project.longitude,
                                  // ✅ always up-to-date after full fetch
                                  initialLotIds:
                                      _project.lots.map((l) => l.id).toList(),
                                ),
                              );
                            },
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
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
    );
  }

  String _formatDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '—';
    if (trimmed.contains('T')) return trimmed.split('T').first;
    final parsed = DateTime.tryParse(trimmed);
    if (parsed != null) {
      return '${parsed.year.toString().padLeft(4, '0')}-'
          '${parsed.month.toString().padLeft(2, '0')}-'
          '${parsed.day.toString().padLeft(2, '0')}';
    }
    return trimmed;
  }
}

// ── _LotsSection ──────────────────────────────────────────────────────────────
class _LotsSection extends StatelessWidget {
  final List<LotOption> lots;

  const _LotsSection({required this.lots});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.category_outlined,
                size: 16, color: Color(0xFF94A3B8)),
            const SizedBox(width: 8),
            Text(
              'Lots assignés',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${lots.length}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: lots.map((lot) => _LotChip(lot: lot)).toList(),
        ),
      ],
    );
  }
}

// ── _LotChip ──────────────────────────────────────────────────────────────────
class _LotChip extends StatelessWidget {
  final LotOption lot;

  const _LotChip({required this.lot});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.label_outline_rounded,
              size: 13, color: AppColors.primaryColor),
          const SizedBox(width: 5),
          Text(
            lot.name,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── _InfoRow ──────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 10),
        SizedBox(
          width: 90,
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
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }
}

// ── _InfoCard ─────────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color bgColor;
  final bool fullWidth;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.bgColor,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: iconColor.withOpacity(0.15), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
