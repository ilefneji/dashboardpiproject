import 'package:get/get.dart';

class DashboardNavigationController extends GetxController {
  static const Set<String> sectionRoutes = {
    '/dashboard',
    '/organizations',
    '/projects',
    '/projects/archive',
    '/lots',
    '/tasks',
    '/task-controls',
    '/journal',
    '/users',
    '/config/subscriptions',
  };

  final RxString currentRoute = '/dashboard'.obs;

  bool isSectionRoute(String route) => sectionRoutes.contains(route);

  String sidebarRouteFor(String route) {
    if (route.startsWith('/projects/') && route != '/projects/archive') {
      return '/projects';
    }
    return route;
  }

  String activeSidebarRoute(String currentGetRoute) {
    final selectedSectionRoute = currentRoute.value;

    if (isSectionRoute(currentGetRoute)) {
      return selectedSectionRoute;
    }
    return sidebarRouteFor(currentGetRoute);
  }

  void syncFromRoute(String route) {
    if (isSectionRoute(route)) {
      currentRoute.value = route;
    }
  }

  void select(String route) {
    if (!isSectionRoute(route)) return;
    currentRoute.value = route;
  }
}
