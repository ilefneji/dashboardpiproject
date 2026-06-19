// core/dashboard/controllers/app_search_controller.dart
import 'package:get/get.dart';

class AppSearchController extends GetxService {
  final query = ''.obs;
  final pageContext = ''.obs; // e.g. 'organizations', 'users', 'projects'

  /// Called by each page on init to register its context
  void setContext(String context) {
    pageContext.value = context;
    query.value = ''; // reset query on page change
  }

  void updateQuery(String value) => query.value = value;

  void clear() => query.value = '';
}
