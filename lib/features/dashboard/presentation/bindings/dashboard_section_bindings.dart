import 'package:get/get.dart';

import '../../../config/presentation/binding/config_binding.dart';
import '../../../journal/presentation/binding/journal_binding.dart';
import '../../../lot/presentation/bindings/lot_binding.dart';
import '../../../organization/presentation/binding/organization_bindinig.dart';
import '../../../project/presentation/binding/project_binding.dart';
import '../../../task-control/presentation/bindings/task_control_binding.dart';
import '../../../task/presentation/bindings/task_binding.dart';
import '../../../users/presentation/binding/user_binding.dart';
import 'dashboard_binding.dart';

class DashboardSectionBindings {
  const DashboardSectionBindings._();

  static void ensure(String route) {
    switch (route) {
      case '/dashboard':
        DashboardBinding().dependencies();
        break;
      case '/organizations':
        OrganizationBinding().dependencies();
        break;
      case '/projects':
      case '/projects/archive':
        ProjectBinding().dependencies();
        break;
      case '/lots':
        LotBinding().dependencies();
        break;
      case '/tasks':
        TaskBinding().dependencies();
        break;
      case '/task-controls':
        TaskControlBinding().dependencies();
        break;
      case '/journal':
        JournalBinding().dependencies();
        break;
      case '/users':
        UserBinding().dependencies();
        break;
      case '/config/subscriptions':
        ConfigBinding().dependencies();
        break;
    }
  }
}
