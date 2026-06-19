// lib/features/journal/presentation/controllers/journal_controller.dart

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import 'package:constructiondashboard/features/auth/presentation/controllers/auth_controller.dart';
import 'package:constructiondashboard/features/journal/data/journal_repository.dart';
import 'package:constructiondashboard/features/project/data/models/project_model.dart';
import 'package:constructiondashboard/features/project/domain/repositories/project_repository.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../dashboard/presentation/controllers/app_search_controller.dart';
import '../../domain/entities/journal_chantier.dart';

class JournalController extends GetxController {
  final JournalRepository _repository;

  JournalController(this._repository);

  final RxBool isLoading = false.obs;
  final RxBool isLoadingProjects = false.obs;
  final RxString errorMessage = ''.obs;

  final RxList<ProjectModel> allProjects = <ProjectModel>[].obs;
  final Rx<ProjectModel?> selectedProject = Rx<ProjectModel?>(null);
  final Rx<JournalChantier?> selectedJournal = Rx<JournalChantier?>(null);

  final TextEditingController searchController = TextEditingController();
  final Rx<DateTime?> selectedDateFilter = Rx<DateTime?>(null);

  final RxList<JournalChantier?> weekJournals =
      List<JournalChantier?>.filled(7, null).obs;

  final List<JournalChantier> _allJournals = [];
  final RxSet<String> _reactivatingIds = <String>{}.obs;

  String _searchQuery = '';
  bool _isDisposed = false;

  bool get isAdmin =>
      Get.find<AuthController>().currentUser.value?.isAdmin ?? false;

  bool isJournalReactivating(String? id) {
    return id != null && _reactivatingIds.contains(id);
  }

  DateTime get _weekStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - (now.weekday - 1));
  }

  List<DateTime> get currentWeekDays {
    return List.generate(7, (i) => _weekStart.add(Duration(days: i)));
  }

  static const List<String> _dayLabels = [
    'Lun',
    'Mar',
    'Mer',
    'Jeu',
    'Ven',
    'Sam',
    'Dim',
  ];

  String dayLabel(int index) => _dayLabels[index];

  bool isToday(int index) {
    final day = currentWeekDays[index];
    final today = DateTime.now();

    return day.day == today.day &&
        day.month == today.month &&
        day.year == today.year;
  }

  @override
  void onInit() {
    super.onInit();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed) return;
      _initAfterFrame();
    });
  }

  void _initAfterFrame() {
    final search = Get.find<AppSearchController>();
    search.setContext('journal');
    ever(search.query, (String q) => _onSearchQueryChanged(q));
    _loadProjects();
  }

  @override
  void onClose() {
    _isDisposed = true;
    searchController.dispose();
    super.onClose();
  }

  Future<void> _loadProjects() async {
    if (_isDisposed) return;

    isLoadingProjects.value = true;
    errorMessage.value = '';

    try {
      final projectRepo = Get.find<ProjectRepository>();
      final projects = await projectRepo.getAllProjects();

      if (_isDisposed) return;

      allProjects.assignAll(projects);

      if (projects.length == 1) {
        selectProject(projects.first);
      }
    } catch (e) {
      if (_isDisposed) return;

      errorMessage.value = 'Impossible de charger les projets: $e';
      debugPrint('_loadProjects ERROR: $e');
    } finally {
      if (!_isDisposed) {
        isLoadingProjects.value = false;
      }
    }
  }

  void selectProject(ProjectModel project) {
    if (_isDisposed) return;

    selectedProject.value = project;
    selectedJournal.value = null;
    errorMessage.value = '';

    loadWeekJournals();
  }

  void clearSelectedProject() {
    if (_isDisposed) return;

    selectedProject.value = null;
    selectedJournal.value = null;
    weekJournals.assignAll(List<JournalChantier?>.filled(7, null));
    _allJournals.clear();
  }

  Future<void> loadWeekJournals() async {
    if (_isDisposed) return;

    final project = selectedProject.value;
    if (project == null) return;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final journals = await _repository.fetchByProject(project.id.toString());

      if (_isDisposed) return;

      _allJournals
        ..clear()
        ..addAll(journals);

      if (selectedJournal.value != null) {
        selectedJournal.value = getJournalById(selectedJournal.value!.id);
      }

      _mapToWeek();
    } catch (e) {
      if (_isDisposed) return;

      errorMessage.value = 'Impossible de charger les journaux: $e';
      debugPrint('loadWeekJournals ERROR: $e');

      Get.snackbar(
        'error'.tr,
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } finally {
      if (!_isDisposed) {
        isLoading.value = false;
      }
    }
  }

  void selectJournalById(String id) {
    selectedJournal.value = getJournalById(id);
  }

  JournalChantier? getJournalById(String id) {
    return _allJournals.firstWhereOrNull((j) => j.id == id);
  }

  Future<JournalChantier?> getOrCreateTodayForSelectedProject() async {
    final project = selectedProject.value;
    if (project == null) return null;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final journal = await _repository.getOrCreateToday(project.id.toString());

      if (_isDisposed) return null;

      _upsertJournal(journal);
      selectedJournal.value = journal;
      _mapToWeek();

      return journal;
    } catch (e) {
      if (_isDisposed) return null;

      errorMessage.value = 'Impossible de récupérer le journal du jour: $e';
      debugPrint('getOrCreateTodayForSelectedProject ERROR: $e');

      Get.snackbar(
        'error'.tr,
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );

      return null;
    } finally {
      if (!_isDisposed) {
        isLoading.value = false;
      }
    }
  }

  void _mapToWeek() {
    final days = currentWeekDays;
    final slots = List<JournalChantier?>.filled(7, null);
    final source = _activeJournals;

    for (int i = 0; i < days.length; i++) {
      final d = days[i];

      final matches = source
          .where(
            (j) => j.jour == d.day && j.mois == d.month && j.annee == d.year,
          )
          .toList();

      if (matches.isEmpty) {
        slots[i] = null;
        continue;
      }

      matches.sort((a, b) => _journalScore(b).compareTo(_journalScore(a)));
      slots[i] = matches.first;
    }

    weekJournals.assignAll(slots);
  }

  int _journalScore(JournalChantier j) {
    int score = j.status == 'SUBMITTED'
        ? 10
        : j.status == 'LOCKED'
            ? 8
            : 0;

    if (j.meteo != null && j.meteo!.trim().isNotEmpty && j.meteo != 'N/A') {
      score++;
    }

    if (j.accidents != null && j.accidents!.trim().isNotEmpty) score++;
    if (j.materiaux != null && j.materiaux!.trim().isNotEmpty) score++;
    if (j.essaisControle != null && j.essaisControle!.trim().isNotEmpty) {
      score++;
    }
    if (j.experience != null && j.experience!.trim().isNotEmpty) score++;
    if (j.observations != null && j.observations!.trim().isNotEmpty) score++;
    if (j.approvisionnement != null && j.approvisionnement!.trim().isNotEmpty) {
      score++;
    }
    if (j.ressources != null && j.ressources!.trim().isNotEmpty) score++;
    if (j.travaux != null && j.travaux!.trim().isNotEmpty) score++;

    return score;
  }

  Future<void> reactivateJournal(String journalId) async {
    if (_isDisposed || !isAdmin || _reactivatingIds.contains(journalId)) {
      return;
    }

    final current = getJournalById(journalId) ??
        weekJournals.firstWhereOrNull((j) => j?.id == journalId);

    final isCurrentlyLocked = current?.isLocked ?? false;

    _reactivatingIds.add(journalId);

    try {
      final JournalChantier updated = isCurrentlyLocked
          ? await _repository.unlockJournal(journalId)
          : await _repository.lockJournal(journalId);

      if (_isDisposed) return;

      _upsertJournal(updated);
      _replaceInWeek(updated);

      await loadWeekJournals();

      Get.snackbar(
        updated.isLocked ? 'Journal désactivé' : 'Journal activé',
        updated.isLocked
            ? 'Le journal est maintenant désactivé et ne peut plus être modifié.'
            : 'Le journal est maintenant activé et peut être modifié.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: updated.isLocked ? AppColors.error : AppColors.success,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      if (_isDisposed) return;

      debugPrint('reactivateJournal ERROR: $e');

      Get.snackbar(
        'Erreur',
        isCurrentlyLocked
            ? 'Impossible de réactiver ce journal.'
            : 'Impossible de désactiver ce journal.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } finally {
      _reactivatingIds.remove(journalId);
    }
  }

  Future<void> updateJournal(
    String journalId,
    Map<String, dynamic> data,
  ) async {
    if (_isDisposed) return;

    isLoading.value = true;

    try {
      final updated = await _repository.update(journalId, data);

      if (_isDisposed) return;

      _upsertJournal(updated);
      _replaceInWeek(updated);

      Get.snackbar(
        'success'.tr,
        'journal_updated'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
    } catch (e) {
      if (_isDisposed) return;

      debugPrint('updateJournal ERROR: $e');

      Get.snackbar(
        'error'.tr,
        'error_updating_journal'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } finally {
      if (!_isDisposed) {
        isLoading.value = false;
      }
    }
  }

  void _upsertJournal(JournalChantier journal) {
    final index = _allJournals.indexWhere((j) => j.id == journal.id);

    if (index == -1) {
      _allJournals.add(journal);
    } else {
      _allJournals[index] = journal;
    }

    if (selectedJournal.value?.id == journal.id) {
      selectedJournal.value = journal;
    }
  }

  void _replaceInWeek(JournalChantier updated) {
    final weekIdx = weekJournals.indexWhere((j) => j?.id == updated.id);

    if (weekIdx != -1) {
      weekJournals[weekIdx] = updated;
      weekJournals.refresh();
    }

    if (selectedJournal.value?.id == updated.id) {
      selectedJournal.value = updated;
    }
  }

  JournalChantier? get todayJournal {
    final today = DateTime.now();

    final matches = _allJournals
        .where(
          (j) =>
              j.jour == today.day &&
              j.mois == today.month &&
              j.annee == today.year,
        )
        .toList();

    if (matches.isEmpty) return null;
    if (matches.length == 1) return matches.first;

    matches.sort((a, b) => _journalScore(b).compareTo(_journalScore(a)));
    return matches.first;
  }

  void _onSearchQueryChanged(String query) {
    if (_isDisposed) return;
    searchJournals(query);
  }

  void searchJournals(String query) {
    if (_isDisposed) return;

    _searchQuery = query.trim().toLowerCase();
    _mapToWeek();
  }

  List<JournalChantier> get _activeJournals {
    final date = selectedDateFilter.value;

    return _allJournals.where((journal) {
      final isInCurrentWeek = _isInCurrentWeek(journal);
      final matchesSearch = _searchQuery.isEmpty || _matchesQuery(journal);

      final matchesDate = date == null ||
          (journal.jour == date.day &&
              journal.mois == date.month &&
              journal.annee == date.year);

      return isInCurrentWeek && matchesSearch && matchesDate;
    }).toList();
  }

  bool _isInCurrentWeek(JournalChantier journal) {
    return true;
  }

  bool _matchesQuery(JournalChantier j) {
    final q = _searchQuery;
    if (q.isEmpty) return true;

    return (j.meteo?.toLowerCase().contains(q) ?? false) ||
        (j.accidents?.toLowerCase().contains(q) ?? false) ||
        (j.materiaux?.toLowerCase().contains(q) ?? false) ||
        (j.essaisControle?.toLowerCase().contains(q) ?? false) ||
        (j.experience?.toLowerCase().contains(q) ?? false) ||
        (j.observations?.toLowerCase().contains(q) ?? false) ||
        (j.approvisionnement?.toLowerCase().contains(q) ?? false) ||
        (j.organismeType?.toLowerCase().contains(q) ?? false) ||
        (j.ressources?.toLowerCase().contains(q) ?? false) ||
        (j.travaux?.toLowerCase().contains(q) ?? false) ||
        j.status.toLowerCase().contains(q);
  }

  void filterByDate(DateTime date) {
    selectedDateFilter.value = date;
    searchJournals(searchController.text);
  }

  void clearDateFilter() {
    selectedDateFilter.value = null;
    searchJournals(searchController.text);
  }

  List<JournalChantier> get visibleJournals {
    final date = selectedDateFilter.value;

    final filtered = _allJournals.where((j) {
      final matchesSearch = _searchQuery.isEmpty || _matchesQuery(j);

      final matchesDate = date == null ||
          (j.jour == date.day && j.mois == date.month && j.annee == date.year);

      return matchesSearch && matchesDate;
    }).toList();

    filtered.sort((a, b) {
      final dateA = DateTime(a.annee, a.mois, a.jour);
      final dateB = DateTime(b.annee, b.mois, b.jour);

      return dateB.compareTo(dateA); // newest first
    });

    return filtered;
  }

  bool get isDateFilterActive => selectedDateFilter.value != null;
}
