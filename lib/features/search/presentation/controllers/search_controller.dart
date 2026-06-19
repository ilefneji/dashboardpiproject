import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../organization/presentation/controllers/organization_controller.dart';
import '../../../project/presentation/controllers/project_controller.dart';
import '../../../task/presentation/controllers/task_controller.dart';
import '../../../users/presentation/controllers/user_controller.dart';
import '../../../lot/presentation/controllers/lot_controller.dart';
import '../../domain/entities/search_result.dart';

class GlobalSearchController extends GetxController {
  final searchQuery = ''.obs;
  final isSearching = false.obs;
  final searchResults = <SearchResult>[].obs;
  final TextEditingController textController = TextEditingController();
  
  // Debounce to avoid excessive API calls
  final _debounce = Debouncer(milliseconds: 500);

  void onSearchQueryChanged(String query) {
    searchQuery.value = query;
    if (query.isEmpty) {
      searchResults.clear();
      isSearching.value = false;
      return;
    }
    
    isSearching.value = true;
    _debounce.run(() {
      _performSearch(query);
    });
  }

  void clearSearch() {
    textController.clear();
    searchQuery.value = '';
    searchResults.clear();
    isSearching.value = false;
  }

  void _performSearch(String query) {
    // Clear previous results
    searchResults.clear();
    
    // Get controllers
    try {
      final organizationController = Get.find<OrganizationController>();
      _searchOrganizations(query, organizationController);
    } catch (e) {
      // Controller not found, skip searching organizations
    }
    
    try {
      final projectController = Get.find<ProjectController>();
      _searchProjects(query, projectController);
    } catch (e) {
      // Controller not found, skip searching projects
    }
    
    try {
      final taskController = Get.find<TaskController>();
      _searchTasks(query, taskController);
    } catch (e) {
      // Controller not found, skip searching tasks
    }
    
    try {
      final userController = Get.find<UserController>();
      _searchUsers(query, userController);
    } catch (e) {
      // Controller not found, skip searching users
    }
    
    try {
      final lotController = Get.find<LotController>();
      _searchLots(query, lotController);
    } catch (e) {
      // Controller not found, skip searching lots
    }
    
    isSearching.value = false;
  }

  void _searchOrganizations(String query, OrganizationController controller) {
    final organizations = controller.organizations;
    final results = organizations.where((org) => 
      org.name.toLowerCase().contains(query.toLowerCase())
    ).map((org) => SearchResult(
      id: org.id.toString(),
      title: org.name,
      description:  '',
      type: 'organization',
      route: '/organizations/${org.id}',
    )).toList();
    
    searchResults.addAll(results);
  }

  void _searchProjects(String query, ProjectController controller) {
    final projects = controller.projects;
    final results = projects.where((project) => 
      project.name.toLowerCase().contains(query.toLowerCase()) ||
      project.description.toLowerCase().contains(query.toLowerCase())
    ).map((project) => SearchResult(
      id: project.id.toString(),
      title: project.name,
      description: project.description,
      type: 'project',
      route: '/projects/${project.id}',
    )).toList();
    
    searchResults.addAll(results);
  }

void _searchTasks(String query, TaskController controller) {
  final tasks = controller.tasks;
  final results = tasks.where((task) =>
    task.name.toLowerCase().contains(query.toLowerCase()) ||
    (task.description?.toLowerCase().contains(query.toLowerCase()) ?? false)
  ).map((task) => SearchResult(
    id: task.id.toString(),
    title: task.name,
    description: task.description ?? '',
    type: 'task',
    route: '/tasks/${task.id}',
  )).toList();

  searchResults.addAll(results);
}


  void _searchUsers(String query, UserController controller) {
    final users = controller.users;
    final results = users.where((user) => 
     ( user.firstname?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
     ( user.lastname?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
      (user.email?.toLowerCase().contains(query.toLowerCase()) ?? false)
    ).map((user) => SearchResult(
      id: user.id.toString(),
      title: '${user.firstname} ${user.lastname}',
      description: user.email ?? '',
      type: 'user',
      route: '/users/${user.id}',
    )).toList();
    
    searchResults.addAll(results);
  }

  void _searchLots(String query, LotController controller) {
    final lots = controller.lots;
    final results = lots.where((lot) => 
      lot.name.toLowerCase().contains(query.toLowerCase()) ||
      lot.description.toLowerCase().contains(query.toLowerCase())
    ).map((lot) => SearchResult(
      id: lot.id.toString(),
      title: lot.name,
      description: lot.description,
      type: 'lot',
      route: '/lots/${lot.id}',
    )).toList();
    
    searchResults.addAll(results);
  }

  @override
  void onClose() {
    textController.dispose();
    super.onClose();
  }
}

// Debouncer class to prevent excessive API calls
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}
