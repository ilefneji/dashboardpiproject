// lib/features/journal/presentation/pages/journal_detail_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../domain/entities/journal_chantier.dart';
import '../controllers/journal_controller.dart';

class JournalDetailPage extends GetView<JournalController> {
  const JournalDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final journalId = Get.arguments?['journalId'] as String?;
    final isAdmin = Get.arguments?['isAdmin'] as bool? ?? false;

    if (journalId == null || journalId.isEmpty) {
      return AppShell(
        child: _PageFrame(
          child: _ErrorPage(
            title: 'Journal invalide',
            message: 'Aucun identifiant fourni.',
            onBack: Get.back,
          ),
        ),
      );
    }

    controller.selectJournalById(journalId);

    return AppShell(
      child: _PageFrame(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage.value.isNotEmpty) {
            return _ErrorPage(
              title: 'Erreur',
              message: controller.errorMessage.value,
              onBack: Get.back,
            );
          }

          final journal = controller.selectedJournal.value;

          if (journal == null) {
            return _ErrorPage(
              title: 'Journal introuvable',
              message: 'Impossible de charger ce journal.',
              onBack: Get.back,
            );
          }

          return _JournalDetailContent(
            journal: journal,
            isAdmin: isAdmin,
            controller: controller,
          );
        }),
      ),
    );
  }
}

class _PageFrame extends StatelessWidget {
  const _PageFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox.expand(child: child),
    );
  }
}

class _JournalDetailContent extends StatelessWidget {
  final JournalChantier journal;
  final bool isAdmin;
  final JournalController controller;

  const _JournalDetailContent({
    required this.journal,
    required this.isAdmin,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = journal.isLocked;
    final dateText =
        '${journal.jour.toString().padLeft(2, '0')}/${journal.mois.toString().padLeft(2, '0')}/${journal.annee}';

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              [
                _TopBar(
                  isAdmin: isAdmin,
                  isLocked: isLocked,
                  onBack: Get.back,
                  onToggleLock: () => controller.reactivateJournal(journal.id),
                ),
                const SizedBox(height: 10),
                _HeroCard(
                  title: 'Journal de chantier',
                  subtitle:
                      'Suivi quotidien des travaux et informations chantier',
                  date: dateText,
                  status: journal.status,
                  isLocked: isLocked,
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final desktop = constraints.maxWidth >= 900;
                    final infoCard = _InfoCard(journal: journal);
                    final summaryCard = _SummaryCard(journal: journal);

                    if (desktop) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 4, child: infoCard),
                          const SizedBox(width: 14),
                          Expanded(flex: 6, child: summaryCard),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        infoCard,
                        const SizedBox(height: 14),
                        summaryCard,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Détails du journal',
                  icon: Icons.article_rounded,
                  children: [
                    _JournalField(
                      icon: Icons.construction_rounded,
                      label: 'Travaux',
                      value: journal.travaux,
                    ),
                    _JournalField(
                      icon: Icons.wb_sunny_rounded,
                      label: 'Météo',
                      value: journal.meteo,
                    ),
                    _JournalField(
                      icon: Icons.warning_amber_rounded,
                      label: 'Accidents',
                      value: journal.accidents,
                    ),
                    _JournalField(
                      icon: Icons.inventory_2_rounded,
                      label: 'Matériaux',
                      value: journal.materiaux,
                    ),
                    _JournalField(
                      icon: Icons.fact_check_rounded,
                      label: 'Essais & Contrôle',
                      value: journal.essaisControle,
                    ),
                    _JournalField(
                      icon: Icons.science_rounded,
                      label: 'Expérience',
                      value: journal.experience,
                    ),
                    _JournalField(
                      icon: Icons.comment_rounded,
                      label: 'Observations',
                      value: journal.observations,
                    ),
                    _JournalField(
                      icon: Icons.local_shipping_rounded,
                      label: 'Approvisionnement',
                      value: journal.approvisionnement,
                    ),
                    _JournalField(
                      icon: Icons.groups_rounded,
                      label: 'Ressources',
                      value: journal.ressources,
                    ),
                    _JournalField(
                      icon: Icons.business_rounded,
                      label: 'Type organisme',
                      value: journal.organismeType,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  final bool isAdmin;
  final bool isLocked;
  final VoidCallback onBack;
  final VoidCallback onToggleLock;

  const _TopBar({
    required this.isAdmin,
    required this.isLocked,
    required this.onBack,
    required this.onToggleLock,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 0, bottom: 0),
      child: Row(
        children: [
          _RoundButton(
            icon: Icons.arrow_back_rounded,
            onTap: onBack,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Détail du journal',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _textPrimary(context),
              ),
            ),
          ),
          if (isAdmin) ...[
            const SizedBox(width: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor:
                    isLocked ? const Color(0xFF16A34A) : const Color(0xFFEA580C),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onToggleLock,
              icon: Icon(
                isLocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                size: 18,
              ),
              label: Text(isLocked ? 'Activer' : 'Désactiver'),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String date;
  final String status;
  final bool isLocked;

  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.status,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDark(context)
              ? [const Color(0xFF172033), const Color(0xFF0F172A)]
              : [Colors.white, const Color(0xFFFFF7ED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor(context)),
        boxShadow: _shadow(context),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.assignment_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: _textPrimary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: _textSecondary(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Badge(
                      icon: Icons.calendar_month_rounded,
                      label: date,
                      color: AppColors.primaryColor,
                    ),
                    _Badge(
                      icon: Icons.circle_rounded,
                      label: status,
                      color: statusColor,
                    ),
                    _Badge(
                      icon: isLocked
                          ? Icons.lock_rounded
                          : Icons.lock_open_rounded,
                      label: isLocked ? 'Verrouillé' : 'Modifiable',
                      color: isLocked
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF16A34A),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final JournalChantier journal;

  const _InfoCard({required this.journal});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Informations',
      icon: Icons.info_rounded,
      children: [
        _InfoRow(label: 'Statut', value: journal.status),
        _InfoRow(label: 'Créé le', value: _formatDateTime(journal.createdAt)),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final JournalChantier journal;

  const _SummaryCard({required this.journal});

  @override
  Widget build(BuildContext context) {
    final filled = [
      journal.travaux,
      journal.meteo,
      journal.accidents,
      journal.materiaux,
      journal.essaisControle,
      journal.experience,
      journal.observations,
      journal.approvisionnement,
      journal.ressources,
      journal.organismeType,
    ].where((v) => v != null && v.trim().isNotEmpty).length;

    return _SectionCard(
      title: 'Résumé',
      icon: Icons.analytics_rounded,
      children: [
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                icon: Icons.edit_note_rounded,
                label: 'Champs remplis',
                value: '$filled / 10',
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniStat(
                icon: journal.isLocked
                    ? Icons.lock_rounded
                    : Icons.lock_open_rounded,
                label: 'État',
                value: journal.isLocked ? 'Verrouillé' : 'Actif',
                color: journal.isLocked
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF16A34A),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final visibleChildren = children.where((child) {
      return child is! SizedBox;
    }).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor(context)),
        boxShadow: _shadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBox(icon: icon),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (visibleChildren.isEmpty)
            Text(
              'Aucune donnée disponible.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: _textSecondary(context),
              ),
            )
          else
            ...children,
        ],
      ),
    );
  }
}

class _JournalField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;

  const _JournalField({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _softColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBox(icon: icon, small: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _textSecondary(context),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value!,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary(context),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
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
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _textSecondary(context),
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(_isDark(context) ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: _textPrimary(context),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: _textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Badge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(_isDark(context) ? 0.16 : 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final bool small;

  const _IconBox({required this.icon, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: small ? 30 : 34,
      height: small ? 30 : 34,
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(
          _isDark(context) ? 0.16 : 0.09,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        color: AppColors.primaryColor,
        size: small ? 16 : 18,
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _cardColor(context),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            border: Border.all(color: _borderColor(context)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: _textPrimary(context)),
        ),
      ),
    );
  }
}

class _ErrorPage extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onBack;

  const _ErrorPage({
    required this.title,
    required this.message,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _cardColor(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _borderColor(context)),
            boxShadow: _shadow(context),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Color(0xFFDC2626),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: _textSecondary(context),
                ),
              ),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Retour'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

Color _statusColor(String status) {
  switch (status.toUpperCase()) {
    case 'SUBMITTED':
      return const Color(0xFF16A34A);
    case 'LOCKED':
      return const Color(0xFFDC2626);
    case 'ARCHIVED':
      return const Color(0xFF64748B);
    default:
      return AppColors.primaryColor;
  }
}

bool _isDark(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark;
}

Color _cardColor(BuildContext context) {
  return _isDark(context) ? const Color(0xFF111827) : Colors.white;
}

Color _softColor(BuildContext context) {
  return _isDark(context) ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
}

Color _borderColor(BuildContext context) {
  return _isDark(context) ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
}

Color _textPrimary(BuildContext context) {
  return _isDark(context) ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
}

Color _textSecondary(BuildContext context) {
  return _isDark(context) ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
}

List<BoxShadow> _shadow(BuildContext context) {
  return [
    BoxShadow(
      color: Colors.black.withOpacity(_isDark(context) ? 0.22 : 0.04),
      blurRadius: 22,
      offset: const Offset(0, 10),
      spreadRadius: -4,
    ),
  ];
}
