// lib/features/journal/presentation/widgets/journal_status_badge.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 🏷️ JournalStatusBadge
// Displays a coloured pill for DRAFT / SUBMITTED / LOCKED / ARCHIVED
// ─────────────────────────────────────────────────────────────────────────────
class JournalStatusBadge extends StatelessWidget {
  final String status;
  const JournalStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    // ✅ Replaced Dart record map with a plain method — safer across SDK versions
    final cfg = _configFor(status.toUpperCase());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cfg.bg,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: cfg.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(cfg.icon, size: 13, color: cfg.fg),
          const SizedBox(width: 5),
          Text(
            cfg.label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cfg.fg,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeConfig _configFor(String key) {
    switch (key) {
      case 'SUBMITTED':
        return const _BadgeConfig(
          label: 'Envoyé',
          icon: Icons.check_circle_outline_rounded,
          bg: Color(0xFFF0FDF4),
          border: Color(0xFF86EFAC),
          fg: Color(0xFF166534),
        );
      case 'LOCKED':
        return const _BadgeConfig(
          label: 'Désactiver',
          icon: Icons.lock_outline_rounded,
          bg: Color(0xFFFFF1F2),
          border: Color(0xFFFCA5A5),
          fg: Color(0xFF991B1B),
        );
      case 'ARCHIVED':
        return const _BadgeConfig(
          label: 'Archivé',
          icon: Icons.archive_outlined,
          bg: Color(0xFFF8FAFC),
          border: Color(0xFFCBD5E1),
          fg: Color(0xFF64748B),
        );
      case 'DRAFT':
      default: // ✅ safe fallback
        return const _BadgeConfig(
          label: 'Brouillon',
          icon: Icons.edit_outlined,
          bg: Color(0xFFFFFBEB),
          border: Color(0xFFFCD34D),
          fg: Color(0xFF92400E),
        );
    }
  }
}

// ── Config model — replaces Dart records for broader SDK compatibility ────────
class _BadgeConfig {
  final String label;
  final IconData icon;
  final Color bg;
  final Color border;
  final Color fg;

  const _BadgeConfig({
    required this.label,
    required this.icon,
    required this.bg,
    required this.border,
    required this.fg,
  });
}
