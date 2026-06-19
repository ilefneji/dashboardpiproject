// lib/features/journal/presentation/pages/journal_list_page.dart

import 'package:constructiondashboard/core/widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/responsive_card_grid.dart';
import '../../domain/entities/journal_chantier.dart';
import '../controllers/journal_controller.dart';
import '../widgets/journal_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 📄 JournalListPage
// ─────────────────────────────────────────────────────────────────────────────
class JournalListPage extends GetView<JournalController> {
  final bool embedded;

  const JournalListPage({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      child: Column(
        children: [
          _PageHeader(controller: controller),
          Expanded(
            child: Obx(() => _buildBody(context)),
          ),
        ],
      ),
    );

    return embedded ? content : AppShell(child: content);
  }

  Widget _buildBody(BuildContext context) {
    if (controller.isLoadingProjects.value) {
      return const _LoadingView(
        key: ValueKey('loading-projects'),
        message: 'Chargement des projets...',
      );
    }

    if (controller.allProjects.isEmpty) {
      return _EmptyView(
        key: const ValueKey('no-projects'),
        icon: Icons.folder_off_outlined,
        title: 'Aucun projet disponible',
        subtitle: 'Aucun projet ne vous est assigné pour le moment.',
        onRetry: controller.loadWeekJournals,
      );
    }

    if (controller.selectedProject.value == null) {
      return _ProjectPickerView(
        key: const ValueKey('project-picker'),
        controller: controller,
      );
    }

    if (controller.isLoading.value) {
      return const _LoadingView(
        key: ValueKey('loading-journals'),
        message: 'Chargement des journaux...',
      );
    }

    if (controller.errorMessage.value.isNotEmpty) {
      return _ErrorView(
        key: const ValueKey('error'),
        message: controller.errorMessage.value,
        onRetry: controller.loadWeekJournals,
      );
    }

    if (controller.selectedDateFilter.value != null) {
      final selectedDate = controller.selectedDateFilter.value!;

      final filteredEntries = controller.weekJournals
          .asMap()
          .entries
          .where(
            (entry) =>
                entry.value != null &&
                _isSameDay(controller.currentWeekDays[entry.key], selectedDate),
          )
          .map((entry) => MapEntry(entry.key, entry.value!))
          .toList();

      if (filteredEntries.isEmpty) {
        return _EmptyView(
          key: const ValueKey('empty-date-filter'),
          icon: Icons.event_busy_outlined,
          title: 'Aucun journal pour cette date',
          subtitle: 'Aucun journal ne correspond à la date sélectionnée.',
          onRetry: controller.loadWeekJournals,
        );
      }

      return ResponsiveCardGrid<MapEntry<int, JournalChantier>>(
        key: const ValueKey('filtered-journals'),
        items: filteredEntries,
        itemBuilder: (context, entry, index) {
          return _buildFilteredJournalCard(
            context: context,
            slotIndex: entry.key,
            journal: entry.value,
          );
        },
      );
    }

    final hasAnyJournal = controller.visibleJournals.isNotEmpty;
    if (!hasAnyJournal) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.menu_book_outlined,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun journal cette semaine',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Créer automatiquement le journal du jour.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  await controller.getOrCreateTodayForSelectedProject();
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Créer le journal du jour'),
              ),
            ],
          ),
        ),
      );
    }

    return _WeekGrid(
      key: const ValueKey('week'),
      controller: controller,
    );
  }

  Widget _buildFilteredJournalCard({
    required BuildContext context,
    required int slotIndex,
    required JournalChantier journal,
  }) {
    final date = controller.currentWeekDays[slotIndex];
    const canTap = true;
    return JournalCard(
      journal: journal,
      dayLabel: controller.dayLabel(slotIndex),
      date: date,
      isToday: _isSameDay(date, DateTime.now()),
      isAdmin: controller.isAdmin,
      isReactivating: controller.isJournalReactivating(journal.id),
      onTap: canTap
          ? () {
              debugPrint('CLICK JOURNAL: ${journal.id}');
              Get.toNamed(
                '/journal-detail',
                arguments: {
                  'journalId': journal.id,
                  'isAdmin': controller.isAdmin,
                },
              );
            }
          : null,
      onReactivate:
          controller.isAdmin ? () => _handleReactivate(context, journal) : null,
    );
  }

  void _handleReactivate(BuildContext context, JournalChantier journal) {
    if (journal.isLocked) {
      controller.reactivateJournal(journal.id);
    } else {
      _confirmLock(context, journal);
    }
  }

  void _confirmLock(BuildContext context, JournalChantier journal) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(journal.isLocked
            ? 'Activer le journal ?'
            : 'Désactiver le journal ?'),
        content: Text(
          journal.isLocked
              ? 'Ce journal sera réactivé. L\'utilisateur pourra à nouveau le modifier.'
              : 'Ce journal sera désactivé.\n'
                  'L\'utilisateur ne pourra plus le modifier jusqu\'à '
                  'ce qu\'un administrateur le réactive.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: journal.isLocked ? Colors.green : Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              controller.reactivateJournal(journal.id);
            },
            child: Text(
              journal.isLocked ? 'Activer' : 'Désactiver',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 🔝 Page Header
// ═══════════════════════════════════════════════════════════════════════════════
class _PageHeader extends StatelessWidget {
  final JournalController controller;

  const _PageHeader({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final days = controller.currentWeekDays;
    final weekFrom = days.first;
    final weekTo = days.last;
    final weekLabel = '${weekFrom.day} ${_monthShort(weekFrom.month)}'
        ' – ${weekTo.day} ${_monthShort(weekTo.month)} ${weekTo.year}';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF94A3B8).withOpacity(0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF94A3B8).withOpacity(0.12),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
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
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Obx(() {
                    final filled =
                        controller.weekJournals.where((j) => j != null).length;
                    final projectName =
                        controller.selectedProject.value?.name ?? '';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'journal_chantier'.tr,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (projectName.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(
                                Icons.folder_outlined,
                                size: 12,
                                color: AppColors.primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  projectName,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ),
                              if (controller.allProjects.length > 1) ...[
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: controller.clearSelectedProject,
                                  child: Text(
                                    '(changer)',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: const Color(0xFF94A3B8),
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                        ],
                        Text(
                          '$weekLabel  •  $filled/7 ${'journals'.tr}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
                Obx(() {
                  if (controller.isLoading.value ||
                      controller.isLoadingProjects.value) {
                    return const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }

                  return IconButton(
                    onPressed: () async {
                      await controller.loadWeekJournals();
                    },
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 22,
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller.searchController,
              onChanged: controller.searchJournals,
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFFCBD5E1),
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: Color(0xFF94A3B8),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
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
                  borderSide: const BorderSide(
                    color: AppColors.primaryColor,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Obx(() {
              final selectedDate = controller.selectedDateFilter.value;

              return Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final firstDate = controller.currentWeekDays.first;
                        final lastDate = controller.currentWeekDays.last;

                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? firstDate,
                          firstDate: firstDate,
                          lastDate: lastDate,
                          locale: const Locale('fr'),
                          builder: (context, child) {
                            final baseTheme = Theme.of(context);
                            return Theme(
                              data: baseTheme.copyWith(
                                dialogBackgroundColor:
                                    baseTheme.colorScheme.surface,
                                canvasColor: baseTheme.colorScheme.surface,
                                colorScheme: baseTheme.colorScheme.copyWith(
                                  surface: baseTheme.colorScheme.surface,
                                  primary: AppColors.primaryColor,
                                  onPrimary: Colors.white,
                                  onSurface: baseTheme.colorScheme.onSurface,
                                ),
                                datePickerTheme: DatePickerThemeData(
                                  backgroundColor:
                                      baseTheme.colorScheme.surface,
                                  headerBackgroundColor:
                                      baseTheme.colorScheme.surfaceVariant,
                                  headerForegroundColor:
                                      baseTheme.colorScheme.onSurface,
                                  dayForegroundColor:
                                      const MaterialStatePropertyAll<Color>(
                                    Color(0xFF0F172A),
                                  ),
                                  weekdayStyle: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                textButtonTheme: TextButtonThemeData(
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.primaryColor,
                                    textStyle: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              child: child ?? const SizedBox.shrink(),
                            );
                          },
                        );

                        if (picked != null) {
                          controller.filterByDate(picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                              color: Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                selectedDate == null
                                    ? 'Filtrer par date'
                                    : _formatDate(selectedDate),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: selectedDate == null
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (selectedDate != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: controller.clearDateFilter,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.15),
                          ),
                        ),
                        child: Text(
                          'Effacer',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  String _monthShort(int month) {
    const months = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Jun',
      'Jul',
      'Aoû',
      'Sep',
      'Oct',
      'Nov',
      'Déc',
    ];
    return months[month - 1];
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 🗂️ Project Picker
// ═══════════════════════════════════════════════════════════════════════════════
class _ProjectPickerView extends StatelessWidget {
  final JournalController controller;

  const _ProjectPickerView({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sélectionner un projet',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choisissez un projet pour afficher ses journaux de chantier.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: controller.allProjects.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final project = controller.allProjects[index];

                return GestureDetector(
                  onTap: () => controller.selectProject(project),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF94A3B8).withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            project.name ?? 'Projet sans nom',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFFCBD5E1),
                          size: 20,
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
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 📅 Week Grid
// ✅ Wrapped in Obx so weekJournals.refresh() triggers rebuild instantly
// ═══════════════════════════════════════════════════════════════════════════════
class _WeekGrid extends StatelessWidget {
  final JournalController controller;

  const _WeekGrid({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final journals = controller.visibleJournals;

      if (journals.isEmpty) {
        return const Center(
          child: Text('Aucun journal'),
        );
      }

      return ResponsiveCardGrid<JournalChantier>(
        items: journals,
        itemBuilder: (context, journal, index) {
          final date = DateTime(
            journal.annee,
            journal.mois,
            journal.jour,
          );

          final today = _isSameDay(date, DateTime.now());

          return JournalCard(
            journal: journal,
            dayLabel: controller.dayLabel(date.weekday - 1),
            date: date,
            isToday: today,
            isAdmin: controller.isAdmin,
            isReactivating: controller.isJournalReactivating(journal.id),
            onTap: () {
              debugPrint('NAVIGATE TO DETAIL ${journal.id}');
              Get.toNamed(
                '/journal-detail',
                arguments: {
                  'journalId': journal.id,
                  'isAdmin': controller.isAdmin,
                },
              );
            },
            onReactivate: controller.isAdmin
                ? () => _handleReactivate(context, controller, journal)
                : null,
          );
        },
      );
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _handleReactivate(
    BuildContext context,
    JournalController controller,
    JournalChantier journal,
  ) {
    if (journal.isLocked) {
      controller.reactivateJournal(journal.id);
    } else {
      _confirmLock(context, controller, journal.id);
    }
  }

  void _confirmLock(
    BuildContext context,
    JournalController controller,
    String journalId,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Désactiver le journal ?'),
        content: const Text('Le journal passera en lecture seule.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              controller.reactivateJournal(journalId);
            },
            child: const Text('Désactiver'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ⏳ Loading View
// ═══════════════════════════════════════════════════════════════════════════════
class _LoadingView extends StatelessWidget {
  final String message;

  const _LoadingView({
    super.key,
    this.message = '',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primaryColor,
            strokeWidth: 2.5,
          ),
          const SizedBox(height: 16),
          Text(
            message.isNotEmpty ? message : 'chargement'.tr,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 📭 Empty View
// ═══════════════════════════════════════════════════════════════════════════════
class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onRetry;

  const _EmptyView({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text('retry'.tr),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryColor,
                side: const BorderSide(color: AppColors.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ❌ Error View
// ═══════════════════════════════════════════════════════════════════════════════
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 64, color: Colors.red[200]),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text('retry'.tr),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red[400],
                side: BorderSide(color: Colors.red[300]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
