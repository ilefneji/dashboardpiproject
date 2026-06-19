import 'dart:math' as math;

import 'package:constructiondashboard/core/navigation/app_route_observer.dart';
import 'package:constructiondashboard/core/theme/app_colors.dart';
import 'package:constructiondashboard/core/widgets/app_shell.dart';
import 'package:constructiondashboard/features/auth/presentation/controllers/auth_controller.dart';
import 'package:constructiondashboard/features/config/presentation/controllers/subscription_controller.dart';
import 'package:constructiondashboard/features/lot/domain/entities/lot.dart';
import 'package:constructiondashboard/features/lot/presentation/controllers/lot_controller.dart';
import 'package:constructiondashboard/features/project/data/models/project_model.dart';
import 'package:constructiondashboard/features/project/presentation/controllers/project_controller.dart';
import 'package:constructiondashboard/features/users/domain/entities/user.dart';
import 'package:constructiondashboard/features/users/presentation/controllers/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/dashboard_controller.dart';
import '../widgets/dashboard_fl_charts.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with RouteAware {
  late final DashboardController _dashboardController;
  late final ProjectController _projectController;
  late final UserController _userController;
  late final LotController _lotController;
  late final AuthController _authController;
  late final SubscriptionController _subscriptionController;

  Worker? _currentUserWorker;
  Worker? _userSubscriptionsWorker;
  bool _isSubscriptionExpired = false;
  int _selectedMonth = 0;
  int _selectedProjectId = 0;
  String _selectedStatus = 'Tous';

  static const List<String> _months = [
    'Tous les mois',
    'Janvier',
    'Fevrier',
    'Mars',
    'Avril',
    'Mai',
    'Juin',
    'Juillet',
    'Aout',
    'Septembre',
    'Octobre',
    'Novembre',
    'Decembre',
  ];

  static const List<String> _statusFilters = ['Tous', 'Actifs', 'Archives'];

  @override
  void initState() {
    super.initState();
    _dashboardController = Get.find<DashboardController>();
    _projectController = Get.find<ProjectController>();
    _userController = Get.find<UserController>();
    _lotController = Get.find<LotController>();
    _authController = Get.find<AuthController>();
    _subscriptionController = Get.find<SubscriptionController>();
    _refreshSubscriptionState(notify: false);
    _currentUserWorker = ever(
      _authController.currentUser,
      (_) => _refreshSubscriptionState(),
    );
    _userSubscriptionsWorker = ever(
      _subscriptionController.userSubscriptions,
      (_) => _refreshSubscriptionState(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    _currentUserWorker?.dispose();
    _userSubscriptionsWorker?.dispose();
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  void _refreshSubscriptionState({bool notify = true}) {
    final currentUser = _authController.currentUser.value;
    final currentSub = _subscriptionController.findCurrentSubscriptionForUser(
      currentUser?.id,
    );
    final endDate =
        currentSub?.currentPeriodEnd ?? currentSub?.project?.endDate;
    final daysLeft = endDate?.difference(DateTime.now()).inDays;
    final isExpired = daysLeft != null && daysLeft < 0;

    if (_isSubscriptionExpired == isExpired) return;
    _isSubscriptionExpired = isExpired;
    if (notify && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isSubscriptionExpired) ...[
              const _SubscriptionExpiredBanner(),
              const SizedBox(height: 14),
            ],
            _Header(
              projectController: _projectController,
              selectedMonth: _selectedMonth,
              selectedProjectId: _selectedProjectId,
              selectedStatus: _selectedStatus,
              months: _months,
              statusFilters: _statusFilters,
              onMonthChanged: (value) {
                setState(() => _selectedMonth = value ?? 0);
              },
              onProjectChanged: (value) {
                setState(() => _selectedProjectId = value ?? 0);
              },
              onStatusChanged: (value) {
                setState(() => _selectedStatus = value ?? 'Tous');
              },
            ),
            const SizedBox(height: 14),
            _KpiGrid(
              projectController: _projectController,
              userController: _userController,
            ),
            const SizedBox(height: 14),
            _ChartsGrid(
              projectController: _projectController,
              lotController: _lotController,
              dashboardController: _dashboardController,
              selectedMonth: _selectedMonth,
              selectedProjectId: _selectedProjectId,
              selectedStatus: _selectedStatus,
            ),
            const SizedBox(height: 14),
            _ActivityAndAlerts(
              projectController: _projectController,
              userController: _userController,
              lotController: _lotController,
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.projectController,
    required this.selectedMonth,
    required this.selectedProjectId,
    required this.selectedStatus,
    required this.months,
    required this.statusFilters,
    required this.onMonthChanged,
    required this.onProjectChanged,
    required this.onStatusChanged,
  });

  final ProjectController projectController;
  final int selectedMonth;
  final int selectedProjectId;
  final String selectedStatus;
  final List<String> months;
  final List<String> statusFilters;
  final ValueChanged<int?> onMonthChanged;
  final ValueChanged<int?> onProjectChanged;
  final ValueChanged<String?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 1120;
          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tableau de bord admin',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pilotage projets, lots, activites et alertes chantier.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );

          final filters = Obx(() {
            final selectedYear = projectController.selectedYear.value;
            final years = projectController.availableYears.toList();
            final projects = projectController.projects.toList();
            final filterItems = [
              _FilterPill<int>(
                icon: Icons.calendar_month_rounded,
                value: selectedYear,
                minWidth: 142,
                maxWidth: 150,
                items: [
                  const DropdownMenuItem(
                    value: 0,
                    child: Text('Toutes annees'),
                  ),
                  ...years.map(
                    (year) => DropdownMenuItem(
                      value: year,
                      child: Text(year.toString()),
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  if (value == 0) {
                    projectController.clearYearFilter();
                  } else {
                    projectController.filterByYear(value);
                  }
                },
              ),
              _FilterPill<int>(
                icon: Icons.date_range_rounded,
                value: selectedMonth,
                minWidth: 148,
                maxWidth: 158,
                items: List.generate(
                  months.length,
                  (index) => DropdownMenuItem(
                    value: index,
                    child: Text(months[index]),
                  ),
                ),
                onChanged: onMonthChanged,
              ),
              _FilterPill<int>(
                icon: Icons.apartment_rounded,
                value: selectedProjectId,
                minWidth: 188,
                maxWidth: 210,
                items: [
                  const DropdownMenuItem(value: 0, child: Text('Tous projets')),
                  ...projects.map(
                    (project) => DropdownMenuItem(
                      value: project.id,
                      child: Text(project.name),
                    ),
                  ),
                ],
                onChanged: onProjectChanged,
              ),
              _FilterPill<String>(
                icon: Icons.tune_rounded,
                value: selectedStatus,
                minWidth: 126,
                maxWidth: 138,
                items: statusFilters
                    .map(
                      (status) =>
                          DropdownMenuItem(value: status, child: Text(status)),
                    )
                    .toList(),
                onChanged: onStatusChanged,
              ),
            ];

            if (desktop) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < filterItems.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    filterItems[i],
                  ],
                ],
              );
            }

            return Wrap(spacing: 8, runSpacing: 8, children: filterItems);
          });

          if (desktop) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 4, child: title),
                const SizedBox(width: 16),
                Flexible(
                  flex: 7,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: filters,
                  ),
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 12), filters],
          );
        },
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({
    required this.projectController,
    required this.userController,
  });

  final ProjectController projectController;
  final UserController userController;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final dashboardController = Get.find<DashboardController>();

      final projects = projectController.projects;
      final users = userController.users;
      final reserves = dashboardController.reserves;

      final projectsCount = projects.length;
      final archivedCount = projects.where((p) => p.isActive == false).length;
      final usersCount = users.length;
      final reservesCount = reserves.length;

      final cards = [
        _KpiData(
          'Projets',
          projectsCount,
          Icons.folder_copy_rounded,
          const Color(0xFFFF8C00),
          'Total projets',
        ),
        _KpiData(
          'Archives',
          archivedCount,
          Icons.inventory_2_rounded,
          const Color(0xFF64748B),
          'Projets archives',
        ),
        _KpiData(
          'Utilisateurs',
          usersCount,
          Icons.groups_rounded,
          const Color(0xFF2563EB),
          'Comptes disponibles',
        ),
        _KpiData(
          'Reserves',
          reservesCount,
          Icons.fact_check_rounded,
          const Color(0xFFDC2626),
          'Total reserves',
        ),
      ];

      return LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth >= 1024
              ? 4
              : constraints.maxWidth >= 600
                  ? 2
                  : 1;

          return GridView.builder(
            itemCount: cards.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              mainAxisExtent: 84,
            ),
            itemBuilder: (context, index) => _KpiCard(data: cards[index]),
          );
        },
      );
    });
  }
}

class _ChartsGrid extends StatelessWidget {
  const _ChartsGrid({
    required this.projectController,
    required this.lotController,
    required this.dashboardController,
    required this.selectedMonth,
    required this.selectedProjectId,
    required this.selectedStatus,
  });

  final ProjectController projectController;
  final LotController lotController;
  final DashboardController dashboardController;
  final int selectedMonth;
  final int selectedProjectId;
  final String selectedStatus;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedYear = projectController.selectedYear.value;

      final projects = _filteredProjects(
        projectController.projects.toList(),
        selectedYear,
        selectedMonth,
        selectedProjectId,
        selectedStatus,
      );

      final visibleProjectIds = projects.map((p) => p.id).toSet();

      final tasks = lotController.tasks.toList();

      final monthly = _monthlyProjectData(projects);
      final monthlyRecords = monthly
          .map((m) => (label: m.label, active: m.active, archived: m.archived))
          .toList();

      final lotData = projects
          .take(8)
          .map(
            (project) => _ChartValue(
              project.name,
              (project.lots.isNotEmpty
                      ? project.lots.length
                      : project.lotIds.length)
                  .toDouble(),
            ),
          )
          .toList();

      final sortedByBudget = [...projects]
        ..sort((a, b) => b.budget.compareTo(a.budget));

      final top5Budget = sortedByBudget
          .take(5)
          .map((p) => (name: p.name, budget: p.budget.toDouble()))
          .toList();

      final assignedTasks = tasks.where((task) => task.lotId != null).length;
      final unassignedTasks = math.max(tasks.length - assignedTasks, 0);

      final taskStatusData = {
        'Affectees': assignedTasks,
        'Non affectees': unassignedTasks,
        'Terminees': 0,
        'En retard': 0,
      };

      final reserveData = <String, int>{};

      for (final reserve in dashboardController.reserves) {
        final projectId = reserve.filePlan?.id;

        // If your ReserveModel has projectId later, replace this condition.
        // For now we count all loaded reserves because controller fetched them by projects.
        final priority = (reserve.priority ?? '').trim();
        final key = priority.isEmpty ? 'Non definie' : priority;

        reserveData[key] = (reserveData[key] ?? 0) + 1;
      }

      const journalLabels = [
        'Jan',
        'Fev',
        'Mar',
        'Avr',
        'Mai',
        'Juin',
        'Juil',
        'Aou',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      final journalData = List.generate(
        12,
        (i) => (label: journalLabels[i], count: 0),
      );

      for (final journal in dashboardController.journals) {
        if (!visibleProjectIds.contains(journal.projectId)) continue;

        final index = journal.mois - 1;
        if (index < 0 || index >= 12) continue;

        final old = journalData[index];
        journalData[index] = (label: old.label, count: old.count + 1);
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final twoColumns = constraints.maxWidth >= 900;
          final cardWidth = twoColumns
              ? (constraints.maxWidth - 14) / 2
              : constraints.maxWidth;

          final cards = <Widget>[
            SizedBox(
              width: cardWidth,
              child: _ChartCard(
                title: 'Projets actifs / archives par mois',
                icon: Icons.stacked_bar_chart_rounded,
                height: 260,
                child: ProjectStatusBarChart(data: monthlyRecords),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _ChartCard(
                title: 'Repartition des reserves par priorite',
                icon: Icons.pie_chart_outline_rounded,
                height: 260,
                child: ReservePriorityPieChart(data: reserveData),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _ChartCard(
                title: 'Activites par statut',
                icon: Icons.horizontal_split_rounded,
                height: 260,
                child: TaskStatusHorizontalChart(data: taskStatusData),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _ChartCard(
                title: 'Journaux de chantier par mois',
                icon: Icons.show_chart_rounded,
                height: 260,
                child: JournalMonthlyLineChart(data: journalData),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _ChartCard(
                title: 'Budget par projet (Top 5)',
                icon: Icons.account_balance_wallet_rounded,
                height: 260,
                child: TopBudgetBarChart(data: top5Budget),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _ChartCard(
                title: 'Repartition des lots par projet',
                icon: Icons.account_tree_rounded,
                height: 260,
                child: _DonutBreakdownChart(
                  values: lotData,
                  valueSuffix: ' lots',
                ),
              ),
            ),
          ];

          return Wrap(spacing: 12, runSpacing: 12, children: cards);
        },
      );
    });
  }
}

class _ActivityAndAlerts extends StatelessWidget {
  const _ActivityAndAlerts({
    required this.projectController,
    required this.userController,
    required this.lotController,
  });

  final ProjectController projectController;
  final UserController userController;
  final LotController lotController;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final projects = projectController.projects.toList();
      final users = userController.users.toList();
      final latestProject = _latestById(projects);
      final latestUser = _latestById(users);
      final projectsWithoutLots = projects
          .where((project) => project.lotIds.isEmpty && project.lots.isEmpty)
          .length;
      final alerts = [
        const _AlertData(
          'Reserves non traitees',
          0,
          Icons.report_problem_rounded,
          'Aucune donnee globale disponible',
        ),
        const _AlertData(
          'Journaux manquants',
          0,
          Icons.event_busy_rounded,
          'Verification globale non exposee',
        ),
        const _AlertData(
          'Documents manquants',
          0,
          Icons.folder_off_rounded,
          'Aucune donnee globale disponible',
        ),
        _AlertData(
          'Projets sans lots',
          projectsWithoutLots,
          Icons.account_tree_outlined,
          'Controle de structuration chantier',
        ),
      ];

      return LayoutBuilder(
        builder: (context, constraints) {
          final twoColumns = constraints.maxWidth >= 900;
          final width = twoColumns
              ? (constraints.maxWidth - 14) / 2
              : constraints.maxWidth;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: width,
                child: _Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionHeader(
                        icon: Icons.history_rounded,
                        title: 'Dernieres activites',
                      ),
                      const SizedBox(height: 12),
                      _ActivityRow(
                        icon: Icons.apartment_rounded,
                        label: 'Dernier projet ajoute',
                        value: latestProject?.name ?? 'Aucun projet',
                      ),
                      _ActivityRow(
                        icon: Icons.person_add_alt_1_rounded,
                        label: 'Dernier utilisateur ajoute',
                        value: _userName(latestUser),
                      ),
                      const _ActivityRow(
                        icon: Icons.description_rounded,
                        label: 'Dernier document ajoute',
                        value: 'Aucune donnee globale',
                      ),
                      const _ActivityRow(
                        icon: Icons.warning_amber_rounded,
                        label: 'Derniere reserve',
                        value: 'Aucune donnee globale',
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: width,
                child: _Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionHeader(
                        icon: Icons.notifications_active_rounded,
                        title: 'Alertes chantier',
                      ),
                      const SizedBox(height: 12),
                      ...alerts.map((alert) => _AlertRow(data: alert)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      );
    });
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.data});

  final _KpiData data;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: data.color.withOpacity(Get.isDarkMode ? 0.18 : 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: data.color, size: 19),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.value.toString(),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  data.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
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

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.icon,
    required this.child,
    this.height = 260,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(icon: icon, title: title),
            const SizedBox(height: 16),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _MonthlyProjectsChart extends StatelessWidget {
  const _MonthlyProjectsChart({required this.data});

  final List<_MonthlyValue> data;

  @override
  Widget build(BuildContext context) {
    final maxValue = data.fold<int>(
      0,
      (max, item) => math.max(max, math.max(item.active, item.archived)),
    );
    if (maxValue == 0) {
      return const _EmptyState(
        icon: Icons.bar_chart_rounded,
        title: 'Aucune donnee disponible',
        message: 'Les projets apparaitront ici apres chargement.',
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map((item) {
        final activeHeight = 160 * (item.active / maxValue);
        final archivedHeight = 160 * (item.archived / maxValue);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _VerticalBar(
                          height: activeHeight,
                          color: AppColors.primaryOrange,
                        ),
                        const SizedBox(width: 3),
                        _VerticalBar(
                          height: archivedHeight,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.label,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _BudgetByProjectChart extends StatelessWidget {
  const _BudgetByProjectChart({required this.data});

  final List<_ChartValue> data;

  static const _colors = [
    AppColors.primaryOrange,
    Color(0xFF2563EB),
    Color(0xFF10B981),
    Color(0xFF8B5CF6),
  ];

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const _EmptyState(
        icon: Icons.account_balance_wallet_rounded,
        title: 'Aucun projet disponible',
        message: 'Le budget par projet apparaitra apres creation de projets.',
      );
    }

    final maxValue = data.fold<double>(
      0,
      (max, item) => math.max(max, item.value),
    );
    final chartMax = math.max(maxValue, 1.0);
    final totalBudget = data.fold<double>(0, (sum, item) => sum + item.value);

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final color = _colors[index % _colors.length];
              final hasBudget = item.value > 0;
              final heightRatio = math.min(
                math.max(item.value / chartMax, hasBudget ? 0.08 : 0.02),
                1.0,
              );

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: heightRatio,
                            widthFactor: 0.52,
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              decoration: BoxDecoration(
                                color: hasBudget
                                    ? color
                                    : AppColors.textSecondary.withValues(
                                        alpha: 0.22,
                                      ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  if (hasBudget)
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.18),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${_formatCompactValue(item.value)} TND',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _softSurface(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderColor(context)),
          ),
          child: Text(
            'Total budget: ${_formatCompactValue(totalBudget)} TND',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _HorizontalBars extends StatelessWidget {
  const _HorizontalBars({
    required this.data,
    required this.emptyText,
    this.valueSuffix = '',
  });

  final List<_ChartValue> data;
  final String emptyText;
  final String valueSuffix;

  @override
  Widget build(BuildContext context) {
    final visibleData = data.where((item) => item.value > 0).toList();
    final maxValue = visibleData.fold<double>(
      0,
      (max, item) => math.max(max, item.value),
    );
    if (visibleData.isEmpty || maxValue == 0) {
      return const _EmptyState(
        icon: Icons.insights_rounded,
        title: 'Aucune donnee disponible',
        message: 'Les valeurs seront affichees des que disponibles.',
      );
    }

    const barColors = [
      AppColors.primaryOrange,
      Color(0xFF2563EB),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFF8B5CF6),
      Color(0xFFEF4444),
    ];

    return Column(
      children: visibleData.take(6).toList().asMap().entries.map((entry) {
        final item = entry.value;
        final color = barColors[entry.key % barColors.length];
        final percent = item.value / maxValue;
        return Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Row(
            children: [
              SizedBox(
                width: 116,
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: percent.clamp(0.0, 1.0),
                    minHeight: 11,
                    backgroundColor: color.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 72,
                child: Text(
                  '${_formatCompactValue(item.value)}$valueSuffix',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SegmentList extends StatelessWidget {
  const _SegmentList({required this.values, required this.emptyText});

  final List<_ChartValue> values;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final total = values.fold<double>(0, (sum, item) => sum + item.value);
    if (total <= 0) {
      return const _EmptyState(
        icon: Icons.check_circle_outline_rounded,
        title: 'Aucune donnee disponible',
        message: 'Les activites chargees seront classees automatiquement.',
      );
    }

    return Column(
      children: values.map((item) {
        final ratio = item.value / total;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    item.value.toStringAsFixed(0),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: ratio.clamp(0.0, 1.0),
                  minHeight: 12,
                  backgroundColor: _borderColor(context).withOpacity(0.55),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    item.label == 'Affectees'
                        ? AppColors.primaryOrange
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _DonutBreakdownChart extends StatelessWidget {
  const _DonutBreakdownChart({required this.values, this.valueSuffix = ''});

  final List<_ChartValue> values;
  final String valueSuffix;

  static const List<Color> _colors = [
    AppColors.primaryOrange,
    Color(0xFF2563EB),
    Color(0xFF059669),
    Color(0xFF7C3AED),
    Color(0xFFDC2626),
    Color(0xFF0891B2),
    Color(0xFF64748B),
    Color(0xFFF59E0B),
  ];

  @override
  Widget build(BuildContext context) {
    final visible = values.where((item) => item.value > 0).take(8).toList();
    final total = visible.fold<double>(0, (sum, item) => sum + item.value);

    if (total <= 0) {
      return const _EmptyState(
        icon: Icons.pie_chart_rounded,
        title: 'Statistiques en attente',
        message:
            'Les statistiques seront disponibles apres creation de donnees.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;
        final chart = SizedBox(
          width: compact ? 140 : 160,
          height: compact ? 140 : 160,
          child: CustomPaint(
            painter: _DonutChartPainter(
              values: visible,
              colors: _colors,
              backgroundColor: _borderColor(context),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    total.toStringAsFixed(0),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'lots',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        final legend = Column(
          children: visible.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final ratio = item.value / total;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _colors[index % _colors.length],
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${item.value.toStringAsFixed(0)}$valueSuffix',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(ratio * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: AppColors.primaryOrange,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );

        if (compact) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [chart, const SizedBox(height: 18), legend],
          );
        }

        return Row(
          children: [
            chart,
            const SizedBox(width: 18),
            Expanded(child: legend),
          ],
        );
      },
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  const _DonutChartPainter({
    required this.values,
    required this.colors,
    required this.backgroundColor,
  });

  final List<_ChartValue> values;
  final List<Color> colors;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (sum, item) => sum + item.value);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius - 8);
    final strokeWidth = math.max(18.0, radius * 0.22);

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..color = backgroundColor;

    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, basePaint);

    if (total <= 0) return;

    var startAngle = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = (values[i].value / total) * math.pi * 2;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth
        ..color = colors[i % colors.length];

      canvas.drawArc(rect, startAngle, sweep - 0.035, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.colors != colors ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

class _CompactEmptyPanel extends StatelessWidget {
  const _CompactEmptyPanel({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withOpacity(
                Get.isDarkMode ? 0.18 : 0.1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryOrange, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _softSurface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor(context)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryOrange, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
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

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.data});

  final _AlertData data;

  @override
  Widget build(BuildContext context) {
    final active = data.count > 0;
    final color = active ? const Color(0xFFDC2626) : const Color(0xFF059669);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(Get.isDarkMode ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          Icon(data.icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            data.count.toString(),
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding = const EdgeInsets.all(14)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: padding,
      decoration: BoxDecoration(
        color: _panelColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(Get.isDarkMode ? 0.18 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(Get.isDarkMode ? 0.10 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.primaryOrange.withOpacity(
              Get.isDarkMode ? 0.18 : 0.1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryOrange, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterPill<T> extends StatelessWidget {
  const _FilterPill({
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
    this.minWidth = 150,
    this.maxWidth = 240,
  });

  final IconData icon;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final double minWidth;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minWidth, maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: _softSurface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primaryOrange, size: 16),
            const SizedBox(width: 7),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<T>(
                  value: value,
                  isDense: true,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(14),
                  dropdownColor: _panelColor(context),
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  items: items,
                  onChanged: onChanged,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: Get.isDarkMode
                  ? const Color(0xFF1F2937)
                  : const Color(0xFFFFF3E8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primaryOrange, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Get.isDarkMode
                  ? const Color(0xFFF9FAFB)
                  : const Color(0xFF111827),
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Get.isDarkMode
                  ? const Color(0xFF9CA3AF)
                  : const Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalBar extends StatelessWidget {
  const _VerticalBar({required this.height, required this.color});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 9,
      height: height.clamp(4, 160),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _SubscriptionExpiredBanner extends StatelessWidget {
  const _SubscriptionExpiredBanner();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFDC2626),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Votre abonnement est termine. Veuillez regler votre situation financiere.',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiData {
  const _KpiData(this.title, this.value, this.icon, this.color, this.subtitle);

  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final String subtitle;
}

class _ChartValue {
  const _ChartValue(this.label, this.value);

  final String label;
  final double value;
}

class _MonthlyValue {
  const _MonthlyValue(this.label, this.active, this.archived);

  final String label;
  final int active;
  final int archived;
}

class _AlertData {
  const _AlertData(this.title, this.count, this.icon, this.subtitle);

  final String title;
  final int count;
  final IconData icon;
  final String subtitle;
}

List<ProjectModel> _filteredProjects(
  List<ProjectModel> projects,
  int selectedYear,
  int selectedMonth,
  int selectedProjectId,
  String selectedStatus,
) {
  return projects.where((project) {
    if (selectedProjectId != 0 && project.id != selectedProjectId) return false;
    if (selectedStatus == 'Actifs' && project.isActive == false) return false;
    if (selectedStatus == 'Archives' && project.isActive != false) return false;
    final start = _parseDate(project.startDate);
    final end = _parseDate(project.endDate);
    if (selectedYear != 0) {
      final matchesYear = (start != null && start.year <= selectedYear) &&
          (end != null ? end.year >= selectedYear : true);
      if (!matchesYear) return false;
    }
    if (selectedMonth != 0 && start != null && start.month != selectedMonth) {
      return false;
    }
    return true;
  }).toList();
}

List<_MonthlyValue> _monthlyProjectData(List<ProjectModel> projects) {
  const labels = [
    'Jan',
    'Fev',
    'Mar',
    'Avr',
    'Mai',
    'Juin',
    'Juil',
    'Aou',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final active = List<int>.filled(12, 0);
  final archived = List<int>.filled(12, 0);
  for (final project in projects) {
    final start = _parseDate(project.startDate);
    if (start == null) continue;
    final index = start.month - 1;
    if (project.isActive == false) {
      archived[index]++;
    } else {
      active[index]++;
    }
  }
  return List.generate(
    12,
    (index) => _MonthlyValue(labels[index], active[index], archived[index]),
  );
}

DateTime? _parseDate(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return DateTime.tryParse(value);
}

T? _latestById<T>(List<T> items) {
  if (items.isEmpty) return null;
  final copy = [...items];
  copy.sort((a, b) {
    final aId = a is ProjectModel
        ? a.id
        : a is UserModel
            ? (a.id ?? 0)
            : a is Lot
                ? (a.id ?? 0)
                : 0;
    final bId = b is ProjectModel
        ? b.id
        : b is UserModel
            ? (b.id ?? 0)
            : b is Lot
                ? (b.id ?? 0)
                : 0;
    return bId.compareTo(aId);
  });
  return copy.first;
}

String _userName(UserModel? user) {
  if (user == null) return 'Aucun utilisateur';
  final fullName = '${user.firstname ?? ''} ${user.lastname ?? ''}'.trim();
  if (fullName.isNotEmpty) return fullName;
  return user.email ?? 'Utilisateur';
}

String _formatCompactValue(double value) {
  if (value >= 1000000000) return '${(value / 1000000000).toStringAsFixed(1)}B';
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
  return value.toStringAsFixed(0);
}


Color _panelColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? AppColors.darkSurface : Colors.white;
}

Color _softSurface(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF8FAFC);
}

Color _borderColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB);
}
