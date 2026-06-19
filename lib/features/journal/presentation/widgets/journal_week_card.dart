// lib/features/journal/presentation/widgets/journal_week_card.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/journal_chantier.dart';

class JournalWeekCard extends StatelessWidget {
  final String dayLabel;
  final DateTime date;
  final JournalChantier? journal;
  final bool isToday;
  final bool isAdmin;
  final bool isReactivating;
  final VoidCallback? onTap;
  final VoidCallback? onReactivate;

  const JournalWeekCard({
    super.key,
    required this.dayLabel,
    required this.date,
    required this.journal,
    required this.isToday,
    required this.isAdmin,
    this.isReactivating = false,
    this.onTap,
    this.onReactivate,
  });

  bool get _isLocked => journal?.isLocked ?? false;
  bool get _isDraft => journal?.isDraft ?? false;
  bool get _isSubmitted => journal?.isSubmitted ?? false;
  bool get _isArchived => journal?.isArchived ?? false;

  Color _cardColor(BuildContext context) {
    if (_isLocked) {
      return _isDark(context) ? const Color(0xFF2A1518) : const Color(0xFFFFF1F2);
    }
    if (isToday) {
      return _isDark(context) ? const Color(0xFF0F1F2E) : const Color(0xFFF0F9FF);
    }
    return _surface(context);
  }

  Color _borderColor(BuildContext context) {
    if (journal == null) return _border(context);
    if (_isLocked) return const Color(0xFFEF4444);
    if (_isSubmitted) return const Color(0xFF22C55E);
    if (_isArchived) return const Color(0xFF94A3B8);
    if (_isDraft) return AppColors.primaryColor;
    return _border(context);
  }

  @override
  Widget build(BuildContext context) {
    final tappable = journal != null;

    return GestureDetector(
      onTap: tappable ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: _cardColor(context),
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(
              color: _borderColor(context),
              width: 4,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isDark(context) ? 0.25 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              _DayBadge(
                dayLabel: dayLabel,
                date: date,
                isToday: isToday,
                isLocked: _isLocked,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _CardContent(
                  journal: journal,
                  isLocked: _isLocked,
                ),
              ),
              const SizedBox(width: 10),
              if (journal != null) ...[
                _JournalStatusBadge(isLocked: _isLocked),
                const SizedBox(width: 10),
                if (isAdmin)
                  _AdminToggleButton(
                    isLocked: _isLocked,
                    isReactivating: isReactivating,
                    onReactivate: onReactivate,
                  )
                else
                  _StatusBadge(status: journal!.status),
              ],
            ],
          ),
        ),
      ),
    );
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
    final bg = isLocked
        ? (_isDark(context) ? const Color(0xFF3F1D1D) : Colors.red.shade100)
        : isToday
            ? AppColors.primaryColor
            : _surfaceAlt(context);

    final fg = isLocked
        ? const Color(0xFFF87171)
        : isToday
            ? Colors.white
            : _textSecondary(context);

    return Container(
      width: 46,
      height: 52,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border(context)),
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

class _CardContent extends StatelessWidget {
  final JournalChantier? journal;
  final bool isLocked;

  const _CardContent({
    required this.journal,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    if (journal == null) {
      return Text(
        'Aucun journal',
        style: GoogleFonts.inter(
          fontSize: 13,
          color: _textSecondary(context),
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isLocked
              ? 'Journal désactivé'
              : (journal!.travaux?.trim().isNotEmpty == true
                  ? journal!.travaux!
                  : 'Journal du jour'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isLocked ? const Color(0xFFF87171) : _textPrimary(context),
          ),
        ),
        if (journal!.meteo != null && journal!.meteo!.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            journal!.meteo!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: _textSecondary(context),
            ),
          ),
        ],
        if (isLocked) ...[
          const SizedBox(height: 4),
          Text(
            'Lecture seule',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFFF87171),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
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
          color: isLocked ? Colors.green.shade600 : Colors.orange.shade600,
        ),
      );
    }

    return isLocked
        ? _ActionChip(
            label: 'Activer',
            icon: Icons.lock_open_rounded,
            color: Colors.green.shade600,
            onPressed: onReactivate,
          )
        : _ActionChip(
            label: 'Désactiver',
            icon: Icons.lock_rounded,
            color: Colors.orange.shade600,
            onPressed: onReactivate,
          );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(_isDark(context) ? 0.18 : 0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              label,
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

class _JournalStatusBadge extends StatelessWidget {
  final bool isLocked;

  const _JournalStatusBadge({
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isLocked
        ? (_isDark(context) ? const Color(0xFF3F1D1D) : Colors.red.shade50)
        : (_isDark(context) ? const Color(0xFF143422) : Colors.green.shade50);

    final fg = isLocked ? const Color(0xFFF87171) : const Color(0xFF22C55E);
    final label = isLocked ? 'Désactivé' : 'Activé';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final config = _configFor(context, status.toUpperCase());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: config.fg.withOpacity(0.25)),
      ),
      child: Text(
        config.label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: config.fg,
        ),
      ),
    );
  }

  _StatusConfig _configFor(BuildContext context, String status) {
    switch (status) {
      case 'SUBMITTED':
        return _StatusConfig(
          label: 'Envoyé',
          bg: _isDark(context) ? const Color(0xFF143422) : Colors.green.shade50,
          fg: const Color(0xFF22C55E),
        );

      case 'LOCKED':
        return _StatusConfig(
          label: 'Désactivé',
          bg: _isDark(context) ? const Color(0xFF3F1D1D) : Colors.red.shade50,
          fg: const Color(0xFFF87171),
        );

      case 'ARCHIVED':
        return _StatusConfig(
          label: 'Archivé',
          bg: _isDark(context) ? const Color(0xFF1F2937) : Colors.grey.shade100,
          fg: _isDark(context) ? const Color(0xFFCBD5E1) : Colors.grey.shade600,
        );

      case 'CLOSED':
        return _StatusConfig(
          label: 'Clôturé',
          bg: _isDark(context) ? const Color(0xFF3A2A12) : Colors.orange.shade50,
          fg: const Color(0xFFF59E0B),
        );

      case 'DRAFT':
      default:
        return _StatusConfig(
          label: 'Brouillon',
          bg: _isDark(context) ? const Color(0xFF172554) : Colors.blue.shade50,
          fg: const Color(0xFF60A5FA),
        );
    }
  }
}

class _StatusConfig {
  final String label;
  final Color bg;
  final Color fg;

  const _StatusConfig({
    required this.label,
    required this.bg,
    required this.fg,
  });
}

bool _isDark(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark;
}

Color _surface(BuildContext context) {
  return _isDark(context) ? const Color(0xFF111827) : Colors.white;
}

Color _surfaceAlt(BuildContext context) {
  return _isDark(context) ? const Color(0xFF1F2937) : const Color(0xFFF1F5F9);
}

Color _textPrimary(BuildContext context) {
  return _isDark(context) ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
}

Color _textSecondary(BuildContext context) {
  return _isDark(context) ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
}

Color _border(BuildContext context) {
  return _isDark(context) ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
}