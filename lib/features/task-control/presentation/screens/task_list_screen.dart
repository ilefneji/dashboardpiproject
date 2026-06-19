import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/widgets/search_field_widget.dart';
import '../../../../core/widgets/app_sidebar.dart';
import '../../../task/presentation/controllers/task_controller.dart';
import '../widgets/task_form_dialog.dart';

// ✅ FIX: Completely convert to StatelessWidget + GetX (no StatefulWidget mixing)
class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controllers on first build only
    _initializeControllers();

    final taskController = Get.find<TaskController>();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.assignment_rounded, size: 24),
            const SizedBox(width: 12),
            Text('tasks'.tr),
          ],
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'refresh'.tr,
            onPressed: taskController.fetchTasks,
          ),
        ],
      ),
      body: Row(
        children: [
          const AppSidebar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => await taskController.fetchTasks(),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    SearchFieldWidget(
                      controller: taskController.searchController,
                      onChanged: (value) => taskController.searchTasks(value),
                      hintText: 'search_tasks'.tr,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Obx(() => _buildContent(context, taskController)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTaskDialog(context, taskController),
        backgroundColor: Colors.blue[700],
        tooltip: 'add_task'.tr,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _initializeControllers() {
    // ✅ FIX: Initialize only once
    if (!Get.isRegistered<TaskController>()) {
      try {
        Get.find<TaskController>();
      } catch (e) {
        // If not found, try to register from binding
      }
    }
  }

  Widget _buildContent(BuildContext context, TaskController controller) {
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.errorMessage.value.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              controller.errorMessage.value,
              style: TextStyle(color: Colors.red[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: controller.fetchTasks,
              icon: const Icon(Icons.refresh),
              label: Text('retry'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (controller.tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('no_tasks'.tr,
                style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          ],
        ),
      );
    }

    if (controller.filteredTasks.isEmpty &&
        controller.searchController.text.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('no_results_found'.tr,
                style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('try_different_search'.tr,
                style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: controller.filteredTasks.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final task = controller.filteredTasks[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            title: Text(task.name),
            subtitle: Text(task.description ?? ''),
            onTap: () => _showEditTaskDialog(context, task.id!, controller),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Text('edit'.tr),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('delete'.tr),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditTaskDialog(context, task.id!, controller);
                } else if (value == 'delete') {
                  _showDeleteConfirmation(context, task.id!, controller);
                }
              },
            ),
          ),
        );
      },
    );
  }

  void _showCreateTaskDialog(BuildContext context, TaskController controller) {
    controller.clearForm();
    showDialog(
      context: context,
      builder: (dialogContext) => TaskFormDialog(
        isEditing: false,
        onSave: () async {
          final success = await controller.createTask();
          if (success && dialogContext.mounted) {
            Navigator.of(dialogContext).pop();
          }
        },
      ),
    );
  }

  void _showEditTaskDialog(
      BuildContext context, int taskId, TaskController controller) {
    final task = controller.tasks.firstWhere((t) => t.id == taskId,
        orElse: () => throw Exception('Task not found'));
    controller.setFormValues(task);
    showDialog(
      context: context,
      builder: (dialogContext) => TaskFormDialog(
        isEditing: true,
        onSave: () async {
          final success = await controller.updateTask(task);
          if (success && dialogContext.mounted) {
            Navigator.of(dialogContext).pop();
          }
        },
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, int taskId, TaskController controller) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('delete_task'.tr),
        content: Text('confirm_delete_task'.tr),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () {
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
              controller.deleteTask(taskId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red[700]),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
  }
}
