import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';

import '../controllers/lot_controller.dart';

class AffectTasksDialog extends StatefulWidget {
  final int lotId;
  final String lotName;
  final List<int> currentTaskIds;

  const AffectTasksDialog({
    super.key,
    required this.lotId,
    required this.lotName,
    required this.currentTaskIds,
  });

  @override
  State<AffectTasksDialog> createState() => _AffectTasksDialogState();
}

class _AffectTasksDialogState extends State<AffectTasksDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _selectAll = false;
  late final LotController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<LotController>();

    // Initialize selected tasks with current task IDs only once
    controller.selectedTaskIds.assignAll(widget.currentTaskIds);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.maxFinite,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assignment, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Affecter des tâches au lot ${widget.lotName}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'close'.tr,
                ),
              ],
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Rechercher des Activités",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (controller.tasks.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.assignment_outlined,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          "Pas d'activités disponibles",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Filter tasks based on search query
              final filteredTasks = controller.tasks.where((task) {
                if (_searchQuery.isEmpty) return true;
                return task.name
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()) ||
                    (task.description ?? '')
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase());
              }).toList();

              if (filteredTasks.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'no_search_results'.tr,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Select all checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _selectAll,
                        onChanged: (value) {
                          setState(() {
                            _selectAll = value ?? false;
                          });

                          if (_selectAll) {
                            // Add all filtered task IDs
                            for (final task in filteredTasks) {
                              if (task.id != null &&
                                  !controller.selectedTaskIds
                                      .contains(task.id)) {
                                controller.selectedTaskIds.add(task.id!);
                              }
                            }
                          } else {
                            // Remove all filtered task IDs
                            for (final task in filteredTasks) {
                              if (task.id != null) {
                                controller.selectedTaskIds.remove(task.id!);
                              }
                            }
                          }
                        },
                      ),
                      Text(
                        _selectAll
                            ? 'Désélectionner tout'
                            : 'Sélectionner tout',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Obx(() => Text(
                            '${controller.selectedTaskIds.length} Selectionné(s)',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.bold,
                            ),
                          )),
                    ],
                  ),
                  const Divider(),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.5,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredTasks.length,
                      itemBuilder: (context, index) {
                        final task = filteredTasks[index];
                        return Obx(() => CheckboxListTile(
                              title: Text(
                                task.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.description ?? '-',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              value:
                                  controller.selectedTaskIds.contains(task.id),
                              onChanged: (bool? value) {
                                if (value == true) {
                                  controller.selectedTaskIds.add(task.id!);
                                } else {
                                  controller.selectedTaskIds.remove(task.id!);
                                }

                                // Update select all state
                                setState(() {
                                  _selectAll = filteredTasks.every(
                                    (t) =>
                                        t.id != null &&
                                        controller.selectedTaskIds
                                            .contains(t.id),
                                  );
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ));
                      },
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  child: Text('cancel'.tr),
                ),
                const SizedBox(width: 8),
                Obx(() => ElevatedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : () async {
                              // Use syncTasks to handle both adding and removing tasks
                              final success = await controller.syncTasks(
                                widget.lotId,
                                controller.selectedTaskIds,
                                widget.currentTaskIds,
                              );
                              if (success) {
                                // Show success message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Row(
                                      children: [
                                        Icon(Icons.check_circle,
                                            color: Colors.white),
                                        SizedBox(width: 8),
                                        Text("Activités affectées avec succès"),
                                      ],
                                    ),
                                    backgroundColor: AppColors.success,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                                Navigator.of(context).pop();
                              } else {
                                // Show error message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.error_outline,
                                            color: Colors.white),
                                        const SizedBox(width: 8),
                                        Text(controller
                                                .errorMessage.value.isEmpty
                                            ? 'operation_failed'.tr
                                            : controller.errorMessage.value),
                                      ],
                                    ),
                                    backgroundColor: AppColors.error,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: controller.isLoading.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'save'.tr,
                              style: const TextStyle(fontSize: 16),
                            ),
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
