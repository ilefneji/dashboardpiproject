import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dashboard_card.dart';
import '../../../../core/widgets/info_row.dart';
import '../../domain/entities/journal_chantier.dart';

/// Carte moderne et responsive pour un journal de chantier.
class JournalCard extends StatelessWidget {
  final JournalChantier journal;
  final String dayLabel;
  final DateTime date;
  final bool isToday;
  final bool isAdmin;
  final bool isReactivating;
  final VoidCallback? onTap;
  final VoidCallback? onReactivate;

  const JournalCard({
    super.key,
    required this.journal,
    required this.dayLabel,
    required this.date,
    required this.isToday,
    required this.isAdmin,
    this.isReactivating = false,
    this.onTap,
    this.onReactivate,
  });

  bool get _isLocked => journal.isLocked;
  bool get _isDraft => journal.isDraft;
  bool get _isSubmitted => journal.isSubmitted;
  bool get _isArchived => journal.isArchived;
  bool get _isClosed => journal.isClosed;

  Color _borderColor(BuildContext context) {
    if (_isLocked) return const Color(0xFFEF4444);
    if (_isSubmitted) return const Color(0xFF22C55E);
    if (_isArchived) return const Color(0xFF94A3B8);
    if (_isClosed) return const Color(0xFFF59E0B);
    if (_isDraft) return AppColors.primaryColor;
    return Theme.of(context).colorScheme.outlineVariant;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DashboardCard(
      onTap: onTap,
      borderColor: _borderColor(context),
      backgroundColor: _cardBackground(context),
      leading: _DayBadge(
        dayLabel: dayLabel,
        date: date,
        isToday: isToday,
        isLocked: _isLocked,
      ),
      title: _title,
      subtitle: _subtitle,
      description: _description,
      metadata: [
        InfoRow(
          icon: Icons.calendar_today_rounded,
          value: journal.dateLabel,
        ),
        if (journal.updatedAt != journal.createdAt)
          InfoRow(
            icon: Icons.access_time_rounded,
            label: 'Modifié',
            value: _formatDate(journal.updatedAt),
          ),
      ],
      chips: [
        StatusChip(
          label: _statusLabel,
          backgroundColor: _statusBackground(context),
          foregroundColor: _statusForeground,
          icon: _statusIcon,
        ),
        if (isAdmin)
          StatusChip(
            label: _isLocked ? 'Lecture seule' : 'Modifiable',
            backgroundColor: _isLocked
                ? const Color(0xFFFEE2E2)
                : const Color(0xFFD1FAE5),
            foregroundColor: _isLocked
                ? const Color(0xFFDC2626)
                : const Color(0xFF059669),
            icon: _isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
          ),
      ],
      trailing: isAdmin
          ? _AdminToggleButton(
              isLocked: _isLocked,
              isReactivating: isReactivating,
              onReactivate: onReactivate,
            )
          : null,
    );
  }

  Color _cardBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_isLocked) return isDark ? const Color(0xFF2A1518) : const Color(0xFFFFF1F2);
    if (isToday) return isDark ? const Color(0xFF0F1F2E) : const Color(0xFFF0F9FF);
    return Theme.of(context).colorScheme.surface;
  }

  String get _title {
    if (_isLocked) return 'Journal désactivé';
    final travaux = journal.travaux?.trim();
    if (travaux != null && travaux.isNotEmpty) return travaux;
    return 'Journal du ${journal.dateLabel}';
  }

  String? get _subtitle {
    final meteo = journal.meteo?.trim();
    if (meteo != null && meteo.isNotEmpty && meteo != 'N/A') return meteo;
    return null;
  }

  String? get _description {
    final parts = <String>[];
    final observations = journal.observations?.trim();
    if (observations != null && observations.isNotEmpty) {
      parts.add(observations);
    }
    final accidents = journal.accidents?.trim();
    if (accidents != null && accidents.isNotEmpty) {
      parts.add('Accident : $accidents');
    }
    if (parts.isEmpty) return null;
    return parts.join('  •  ');
  }

  String get _statusLabel {
    if (_isLocked) return 'Désactivé';
    if (_isSubmitted) return 'Envoyé';
    if (_isArchived) return 'Archivé';
    if (_isClosed) return 'Clôturé';
    if (_isDraft) return 'Brouillon';
    return journal.status;
  }

  Color _statusBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_isLocked) return isDark ? const Color(0xFF3F1D1D) : const Color(0xFFFEE2E2);
    if (_isSubmitted) return isDark ? const Color(0xFF143422) : const Color(0xFFD1FAE5);
    if (_isArchived) return isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6);
    if (_isClosed) return isDark ? const Color(0xFF3A2A12) : const Color(0xFFFEF3C7);
    return isDark ? const Color(0xFF172554) : const Color(0xFFDBEAFE);
  }

  Color get _statusForeground {
    if (_isLocked) return const Color(0xFFDC2626);
    if (_isSubmitted) return const Color(0xFF059669);
    if (_isArchived) return const Color(0xFF6B7280);
    if (_isClosed) return const Color(0xFFD97706);
    return const Color(0xFF2563EB);
  }

  IconData? get _statusIcon {
    if (_isLocked) return Icons.lock_rounded;
    if (_isSubmitted) return Icons.send_rounded;
    if (_isArchived) return Icons.archive_rounded;
    if (_isClosed) return Icons.check_circle_rounded;
    if (_isDraft) return Icons.edit_note_rounded;
    return null;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _DayBadge extends StatelessWidget {
  final String dayLabel;
  final DateTime date;
  final bool isToday;
  final bool isLocked;

  const _DayBadge({
    required this.dayLabel,
    required this.date,
    required this.isToday,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isLocked
        ? (isDark ? const Color(0xFF3F1D1D) : const Color(0xFFFEE2E2))
        : isToday
            ? AppColors.primaryColor
            : (isDark ? const Color(0xFF1F2937) : const Color(0xFFF1F5F9));

    final fg = isLocked
        ? const Color(0xFFDC2626)
        : isToday
            ? Colors.white
            : Theme.of(context).colorScheme.onSurfaceVariant;

    return Container(
      width: 48,
      height: 56,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday
              ? AppColors.primaryColor.withOpacity(0.4)
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            dayLabel,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
          Text(
            '${date.day}',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminToggleButton extends StatelessWidget {
  final bool isLocked;
  final bool isReactivating;
  final VoidCallback? onReactivate;

  const _AdminToggleButton({
    required this.isLocked,
    required this.isReactivating,
    this.onReactivate,
  });

  @override
  Widget build(BuildContext context) {
    if (isReactivating) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: isLocked ? const Color(0xFF059669) : const Color(0xFFD97706),
        ),
      );
    }

    final color = isLocked ? const Color(0xFF059669) : const Color(0xFFD97706);

    return GestureDetector(
      onTap: onReactivate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(
            Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.10,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isLocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              isLocked ? 'Activer' : 'Désactiver',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
