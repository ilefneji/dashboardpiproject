import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../controllers/user_controller.dart';

class UserDetailPage extends StatefulWidget {
  const UserDetailPage({super.key});

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  final UserController controller = Get.find<UserController>();
  late int userId;

  @override
  void initState() {
    super.initState();
    userId = int.parse(Get.parameters['id'] ?? '0');
    // Utilisation de addPostFrameCallback pour s'assurer que la mise à jour de l'état
    // se produit après la construction du widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (userId > 0) {
        controller.getUserById(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('user_details'.tr),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.selectedUser.value == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  'user_not_found'.tr,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        final user = controller.selectedUser.value!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error message display
              if (controller.errorMessage.value.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red.shade100,
                  width: double.infinity,
                  child: Text(
                    controller.errorMessage.value,
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ),

              // User profile header
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: user.isActive!
                          ? Colors.blue.shade100
                          : Colors.grey.shade300,
                      child: Text(
                        "${user.firstname?.substring(0, 1) ?? ''}${user.lastname?.substring(0, 1) ?? ''}",
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: user.isActive!
                              ? Colors.blue.shade800
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "${user.firstname} ${user.lastname}",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (user.function != null && user.function!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          user.function!,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blue.shade700,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: user.isActive!
                            ? Colors.green.shade100
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 3,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        user.isActive! ? 'active'.tr : 'inactive'.tr,
                        style: TextStyle(
                          color: user.isActive!
                              ? Colors.green.shade800
                              : Colors.grey.shade800,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // User details section
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'user_details'.tr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildDetailItem(Icons.email, 'email'.tr, user.email!),
                    if (user.phone != null)
                      _buildDetailItem(
                          Icons.phone, 'phone'.tr, user.phone.toString()),
                    if (user.organization != null)
                      _buildDetailItem(Icons.business, 'organization'.tr,
                          user.organization!.name ?? 'N/A'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Additional information section
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'additional_info'.tr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            Icons.confirmation_number,
                            'Nombre des projets :',
                            user.projectCount.toString(),
                            Colors.blue.shade50,
                            Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoCard(
                            Icons.business,
                            'Nombre des Evenements :',
                            user.eventCount.toString(),
                            Colors.amber.shade50,
                            Colors.amber.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: user.isActive! ? Icons.person_off : Icons.person,
                    label: user.isActive! ? 'deactivate'.tr : 'activate'.tr,
                    color: user.isActive! ? Colors.orange : Colors.green,
                    onPressed: () =>
                        _handleStatusChange(user.id!, user.isActive!),
                  ),
                  _buildActionButton(
                    icon: Icons.delete,
                    label: 'delete'.tr,
                    color: Colors.red,
                    onPressed: () => _confirmDelete(user.id!),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value,
      Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: iconColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: controller.isProcessing.value ? null : onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Future<void> _handleStatusChange(int id, bool isCurrentlyActive) async {
    if (isCurrentlyActive) {
      final result = await controller.deactivateUser(id);
      if (result) {
        Get.snackbar(
          'success'.tr,
          'user_deactivated'.tr,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
      }
    } else {
      final result = await controller.activateUser(id);
      if (result) {
        Get.snackbar(
          'success'.tr,
          'user_activated'.tr,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
      }
    }
  }

  void _confirmDelete(int id) {
    Get.dialog(
      AlertDialog(
        title: Text('confirm_delete'.tr),
        content: Text('delete_user_confirmation'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              final result = await controller.deleteUser(id);
              if (result) {
                Get.snackbar(
                  'success'.tr,
                  'user_deleted'.tr,
                  backgroundColor: AppColors.success,
                  colorText: Colors.white,
                );
                Get.back(); // Return to users list
              }
            },
            child: Text('delete'.tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
