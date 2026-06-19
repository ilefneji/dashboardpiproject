import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../config/presentation/pages/subscription_list_page.dart';
import '../../../journal/presentation/pages/journal_list_page.dart';
import '../../../lot/presentation/screens/lot_list_screen.dart';
import '../../../organization/presentation/pages/organization_list_page.dart';
import '../../../project/presentation/screens/project_list_screen.dart';
import '../../../task-control/presentation/screens/task_control_list_screen.dart';
import '../../../task/presentation/screens/task_list_screen.dart';
import '../../../users/presentation/pages/user_list_page.dart';
import '../bindings/dashboard_section_bindings.dart';
import '../controllers/dashboard_navigation_controller.dart';

class DashboardSectionHost extends StatefulWidget {
  final String initialRoute;
  final Widget initialChild;

  const DashboardSectionHost({
    super.key,
    required this.initialRoute,
    required this.initialChild,
  });

  @override
  State<DashboardSectionHost> createState() => _DashboardSectionHostState();
}

class _DashboardSectionHostState extends State<DashboardSectionHost> {
  late final DashboardNavigationController _navigationController;
  final List<String> _visitedRoutes = [];

  @override
  void initState() {
    super.initState();
    _navigationController = Get.find<DashboardNavigationController>();
    _navigationController.syncFromRoute(widget.initialRoute);
    _ensureRoute(widget.initialRoute);
  }

  void _ensureRoute(String route) {
    if (!_navigationController.isSectionRoute(route)) return;
    if (_visitedRoutes.contains(route)) return;

    DashboardSectionBindings.ensure(route);
    _visitedRoutes.add(route);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final route = _navigationController.currentRoute.value;
      _ensureRoute(route);

      final index = _visitedRoutes.indexOf(route);
      if (index == -1) {
        return widget.initialChild;
      }

      return IndexedStack(
        index: index,
        children: [
          for (final visitedRoute in _visitedRoutes)
            KeyedSubtree(
              key: ValueKey('dashboard-section-$visitedRoute'),
              child: _buildSection(visitedRoute),
            ),
        ],
      );
    });
  }

  Widget _buildSection(String route) {
    if (route == widget.initialRoute) {
      return widget.initialChild;
    }

    switch (route) {
      case '/organizations':
        return const OrganizationListPage(embedded: true);
      case '/projects':
        return const ProjectListScreen(embedded: true);
      case '/projects/archive':
        return const ProjectListScreen(showArchived: true, embedded: true);
      case '/lots':
        return const LotListScreen(embedded: true);
      case '/tasks':
        return const TaskListScreen(embedded: true);
      case '/task-controls':
        return const TaskControlListScreen(embedded: true);
      case '/journal':
        return const JournalListPage(embedded: true);
      case '/users':
        return const UserListPage(embedded: true);
      case '/config/subscriptions':
        return const SubscriptionListPage(embedded: true);
      default:
        return widget.initialChild;
    }
  }
}
