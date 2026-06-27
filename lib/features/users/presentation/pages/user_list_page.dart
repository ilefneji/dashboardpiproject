import 'package:constructiondashboard/core/widgets/app_shell.dart';
import 'package:constructiondashboard/features/auth/presentation/controllers/auth_controller.dart';
import 'package:constructiondashboard/features/config/domain/entities/subscription.dart';
import 'package:constructiondashboard/features/config/presentation/controllers/subscription_controller.dart';
import 'package:constructiondashboard/features/users/domain/entities/user.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../controllers/user_controller.dart';

class UserListPage extends StatefulWidget {
  final bool embedded;

  const UserListPage({super.key, this.embedded = false});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage>
    with WidgetsBindingObserver {
  late final UserController controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = Get.find<UserController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.users.isEmpty && !controller.isLoading.value) {
        controller.fetchUsers();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      controller.fetchUsers(silent: controller.users.isNotEmpty);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      child: Column(
        children: [
          _PageHeader(controller: controller),
          Expanded(
            child: Obx(
              () => AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildBody(controller),
              ),
            ),
          ),
        ],
      ),
    );

    return widget.embedded ? content : AppShell(child: content);
  }

  Widget _buildBody(UserController controller) {
    if (controller.isLoading.value) {
      return const _LoadingView(key: ValueKey('loading'));
    }

    if (controller.errorMessage.value.isNotEmpty &&
        controller.filteredUsers.isEmpty) {
      return _ErrorView(
        key: const ValueKey('error'),
        message: controller.errorMessage.value,
        onRetry: () async => controller.fetchUsers(),
      );
    }

    if (controller.filteredUsers.isEmpty) {
      return _EmptyView(
        key: const ValueKey('empty'),
        controller: controller,
      );
    }

    return _UserList(
      key: const ValueKey('list'),
      controller: controller,
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 🔝 Page Header — StatefulWidget owns the TextEditingController
// ═══════════════════════════════════════════════════════════
class _PageHeader extends StatefulWidget {
  final UserController controller;

  const _PageHeader({required this.controller});

  @override
  State<_PageHeader> createState() => _PageHeaderState();
}

class _PageHeaderState extends State<_PageHeader> {
  // ✅ Owned here — Flutter manages its full lifecycle safely
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    // ✅ Disposed with the widget — never touched by GetX
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF94A3B8).withOpacity(0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF94A3B8).withOpacity(0.12),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title Row ──────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor.withOpacity(0.28),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.group_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                // ── Title + Count ──────────────────────────
                Expanded(
                  child: Obx(
                    () => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'users'.tr,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          // ✅ widget.controller — accessed via widget reference
                          '${widget.controller.filteredUsers.length} ${'users'.tr}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Search Field ────────────────────────────────
            TextField(
              // ✅ Local controller — safe from GetX disposal
              controller: _searchController,
              onChanged: widget.controller.searchUsers,
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFFCBD5E1),
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: Color(0xFF94A3B8),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primaryColor,
                    width: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ── Invite Button ───────────────────────────────
            Align(
              alignment: Alignment.centerRight,
              child: Obx(
                () => ElevatedButton.icon(
                  onPressed: widget.controller.isInviting.value
                      ? null
                      : () {
                          showDialog(
                            context: context,
                            builder: (_) => _InviteMemberDialog(
                              // ✅ widget.controller
                              controller: widget.controller,
                            ),
                          );
                        },
                  icon: widget.controller.isInviting.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: Text(
                    'inviter un utilisateur'.tr,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserList extends StatefulWidget {
  final UserController controller;

  const _UserList({super.key, required this.controller});

  @override
  State<_UserList> createState() => _UserListState();
}

class _UserListState extends State<_UserList> {
  static const int _pageSize = 6;
  int _currentPage = 0;
  Worker? _filteredUsersWorker;

  @override
  void initState() {
    super.initState();

    _filteredUsersWorker = ever(
      widget.controller.filteredUsers,
      (_) {
        if (mounted) {
          setState(() {
            _currentPage = 0;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _filteredUsersWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = widget.controller.filteredUsers;

      if (items.isEmpty) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.55,
              child: _EmptyView(controller: widget.controller),
            ),
          ],
        );
      }

      final totalPages = (items.length / _pageSize).ceil().clamp(1, 9999);
      final safePage = _currentPage.clamp(0, totalPages - 1);
      final start = safePage * _pageSize;
      final end = (start + _pageSize).clamp(0, items.length);
      final pageItems = items.sublist(start, end);

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: pageItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final user = pageItems[index];
                  return _UserCard(
                    user: user,
                    controller: widget.controller,
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            _PaginationBar(
              currentPage: safePage,
              totalPages: totalPages,
              onPrevious:
                  safePage > 0 ? () => setState(() => _currentPage--) : null,
              onNext: safePage < totalPages - 1
                  ? () => setState(() => _currentPage++)
                  : null,
              onPageSelected: (page) => setState(() => _currentPage = page),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    });
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final UserController controller;

  const _UserCard({required this.user, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isActive = user.isActive ?? false;
    final isAdmin = user.isAdmin ?? false;
    final isCompact = MediaQuery.of(context).size.width < 720;
    final fullName = '${user.firstname ?? ''} ${user.lastname ?? ''}'.trim();
    final displayName = isAdmin
        ? (user.email ?? 'N/A')
        : (fullName.isNotEmpty ? fullName : (user.email ?? 'N/A'));
    final roleLabel = isAdmin ? 'Administrateur' : 'Utilisateur';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8EBF2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _UserIconBadge(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _UserContentBlock(
                            displayName: displayName,
                            email: user.email ?? 'N/A',
                            roleLabel: roleLabel,
                            organismeType: user.organization?.organismeType,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Spacer(),
                        _UserActionsMenu(
                          isActive: isActive,
                          isAdmin: isAdmin,
                          onToggleStatus: () =>
                              _showStatusConfirmation(context, isActive),
                          onPromoteToAdmin: () =>
                              _confirmMakeAdmin(context, user.id!),
                          onDemoteAdmin: () =>
                              _confirmDemoteAdmin(context, user.id!),
                          onDelete: () => _confirmDelete(context, user.id!),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _UserIconBadge(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _UserContentBlock(
                        displayName: displayName,
                        email: user.email ?? 'N/A',
                        roleLabel: roleLabel,
                        organismeType: user.organization?.organismeType,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _UserActionsMenu(
                      isActive: isActive,
                      isAdmin: isAdmin,
                      onToggleStatus: () =>
                          _showStatusConfirmation(context, isActive),
                      onPromoteToAdmin: () =>
                          _confirmMakeAdmin(context, user.id!),
                      onDemoteAdmin: () =>
                          _confirmDemoteAdmin(context, user.id!),
                      onDelete: () => _confirmDelete(context, user.id!),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _showStatusConfirmation(BuildContext context, bool currentStatus) {
    final newStatus = !currentStatus;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(newStatus ? 'activate_user'.tr : 'deactivate_user'.tr),
        content: Text(
          newStatus ? 'confirm_activate_user'.tr : 'confirm_deactivate_user'.tr,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();

              final success = newStatus
                  ? await controller.activateUser(user.id!)
                  : await controller.deactivateUser(user.id!);

              if (success) {
                Get.snackbar(
                  'success'.tr,
                  newStatus ? 'user_activated'.tr : 'user_deactivated'.tr,
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.success,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 2),
                );
              } else {
                Get.snackbar(
                  'error'.tr,
                  controller.errorMessage.value.isNotEmpty
                      ? controller.errorMessage.value
                      : 'Failed to update user status',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.error,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 3),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  newStatus ? const Color(0xFF059669) : const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: Text(newStatus ? 'activate'.tr : 'deactivate'.tr),
          ),
        ],
      ),
    );
  }

  void _confirmMakeAdmin(BuildContext context, int id) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Theme.of(Get.context!).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Accorder l\'accès administrateur'.tr),
        content: const Text(
          'Cet utilisateur pourra accéder au tableau de bord en tant qu\'administrateur.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final result = await controller.makeAdmin(id);
              if (result) {
                Get.snackbar(
                  'success'.tr,
                  'Utilisateur promu administrateur',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.success,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 2),
                );
              } else {
                Get.snackbar(
                  'error'.tr,
                  controller.errorMessage.value.isNotEmpty
                      ? controller.errorMessage.value
                      : 'Échec de la promotion de l\'utilisateur administrateur',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.error,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 3),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text('Accorder accès'.tr),
          ),
        ],
      ),
    );
  }

  void _confirmDemoteAdmin(BuildContext context, int id) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Theme.of(Get.context!).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Retirer l\'accès administrateur'.tr),
        content: const Text(
          'Cet utilisateur ne pourra plus accéder au tableau de bord en tant qu\'administrateur.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final result = await controller.demoteAdmin(id);
              if (result) {
                Get.snackbar(
                  'success'.tr,
                  'Accès administrateur retiré avec succès',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.success,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 2),
                );
              } else {
                Get.snackbar(
                  'error'.tr,
                  controller.errorMessage.value.isNotEmpty
                      ? controller.errorMessage.value
                      : 'Échec du retrait de l\'accès administrateur',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.error,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 3),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Retirer accès'.tr),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Theme.of(Get.context!).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              }
            },
            child: Text('delete'.tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _UserContentBlock extends StatelessWidget {
  final String displayName;
  final String email;
  final String roleLabel;
  final String? organismeType;

  const _UserContentBlock({
    required this.displayName,
    required this.email,
    required this.roleLabel,
    this.organismeType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          displayName,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: -0.25,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        if (organismeType != null && organismeType!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _InfoChip(
              icon: Icons.business_outlined,
              label: organismeType!.toUpperCase(),
              color: const Color(0xFF3B82F6),
            ),
          ),
        _InfoChip(
          icon: Icons.badge_outlined,
          label: roleLabel.toUpperCase(),
          color: AppColors.primaryColor,
        ),
      ],
    );
  }
}

class _UserIconBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.groups_rounded,
        size: 22,
        color: Colors.white,
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color.withOpacity(0.9)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.95),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserActionsMenu extends StatelessWidget {
  final bool isActive;
  final bool isAdmin;
  final VoidCallback onToggleStatus;
  final VoidCallback onPromoteToAdmin;
  final VoidCallback onDemoteAdmin;
  final VoidCallback onDelete;

  const _UserActionsMenu({
    required this.isActive,
    required this.isAdmin,
    required this.onToggleStatus,
    required this.onPromoteToAdmin,
    required this.onDemoteAdmin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'toggle_status') {
          onToggleStatus();
        } else if (value == 'toggle_admin') {
          if (isAdmin) {
            onDemoteAdmin();
          } else {
            onPromoteToAdmin();
          }
        } else if (value == 'delete') {
          onDelete();
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'toggle_status',
          child: Row(
            children: [
              Icon(
                isActive
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 16,
                color: isActive
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF059669),
              ),
              const SizedBox(width: 10),
              Text(
                isActive ? 'Désactiver' : 'Activer',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isActive
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF059669),
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'toggle_admin',
          child: Row(
            children: [
              Icon(
                isAdmin
                    ? Icons.remove_moderator_outlined
                    : Icons.admin_panel_settings_rounded,
                size: 16,
                color:
                    isAdmin ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
              ),
              const SizedBox(width: 10),
              Text(
                isAdmin ? 'Rétrograder admin' : 'Augmenter accès',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isAdmin
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF2563EB),
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(
                Icons.delete_outline_rounded,
                size: 16,
                color: Color(0xFFEF4444),
              ),
              const SizedBox(width: 10),
              Text(
                'Supprimer',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ),
      ],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      color: Theme.of(context).colorScheme.surface,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.more_vert_rounded,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final ValueChanged<int> onPageSelected;

  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PaginationButton(
            icon: Icons.chevron_left_rounded,
            enabled: onPrevious != null,
            onTap: onPrevious,
          ),
          const SizedBox(width: 8),
          ...List.generate(totalPages, (index) {
            final active = index == currentPage;
            return GestureDetector(
              onTap: () => onPageSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color:
                      active ? AppColors.primaryColor : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            );
          }),
          const SizedBox(width: 8),
          _PaginationButton(
            icon: Icons.chevron_right_rounded,
            enabled: onNext != null,
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}

class _PaginationButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  const _PaginationButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled
              ? Theme.of(context).colorScheme.surface
              : Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 54, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text('retry'.tr),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final UserController controller;

  const _EmptyView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final hasQuery = controller.searchController.text.trim().isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.group_off_rounded,
                size: 56, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              'Aucun utilisateur trouvé',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasQuery
                  ? 'Aucun résultat pour cette recherche.'
                  : 'Ajoutez un utilisateur ou envoyez une invitation.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteMemberDialog extends StatefulWidget {
  final UserController controller;

  const _InviteMemberDialog({required this.controller});

  @override
  State<_InviteMemberDialog> createState() => _InviteMemberDialogState();
}

class _InviteMemberDialogState extends State<_InviteMemberDialog> {
  final TextEditingController _emailController = TextEditingController();

  SubscriptionModel? _findSubscriptionForOrg(
    List<SubscriptionModel> subscriptions,
    int orgId,
  ) {
    for (final sub in subscriptions) {
      if (sub.organizationId == orgId ||
          sub.companyId == orgId ||
          sub.company?.id == orgId ||
          sub.project?.company?.id == orgId) {
        return sub;
      }
    }
    return null;
  }

  String _resolvePlan(SubscriptionModel? subscription) {
    final directPlan = subscription?.plan?.trim().toLowerCase();
    if (directPlan != null && directPlan.isNotEmpty) return directPlan;

    final companyPlan = subscription?.company?.plan?.trim().toLowerCase();
    if (companyPlan != null && companyPlan.isNotEmpty) return companyPlan;

    final projectPlan =
        subscription?.project?.company?.plan?.trim().toLowerCase();
    if (projectPlan != null && projectPlan.isNotEmpty) return projectPlan;

    return 'free';
  }

  bool _isProPlan(SubscriptionModel? subscription) {
    final plan = _resolvePlan(subscription);
    if (plan == 'pro' ||
        plan == 'enterprise' ||
        plan == 'entreprise' ||
        plan == '30' ||
        plan == '30tnd' ||
        plan == '30 tnd' ||
        plan == '30_tnd') {
      return true;
    }

    final price = subscription?.price ?? subscription?.priceTotal;
    if (price == 30) return true;
    if (price != null && price > 0 && price < 5000) return true;

    final amountPaid = subscription?.amountPaid;
    if (amountPaid != null && amountPaid.round() == 30) return true;
    if (amountPaid != null && amountPaid > 0 && amountPaid < 5000) return true;

    return false;
  }

  bool _isOnPremisePlan(SubscriptionModel? subscription) {
    final plan = _resolvePlan(subscription);
    if (plan == 'onpremise' || plan == 'on_premise' || plan == '5000') {
      return true;
    }

    final price = subscription?.price ?? subscription?.priceTotal;
    if (price != null && price >= 5000) return true;

    final amountPaid = subscription?.amountPaid;
    if (amountPaid != null && amountPaid >= 5000) return true;

    return false;
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final subscriptionController = Get.find<SubscriptionController>();

    return AlertDialog(
      title: Text('inviter un utilisateur'.tr),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'utilisateur@example.com',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('cancel'.tr),
        ),
        Obx(
          () => ElevatedButton(
            onPressed: widget.controller.isInviting.value
                ? null
                : () async {
                    final email = _emailController.text.trim();
                    final currentUser = authController.currentUser.value;
                    final inviterId = currentUser?.id;
                    final orgId = currentUser?.organizationId;

                    if (inviterId == null) {
                      Get.snackbar(
                        'error'.tr,
                        'No authenticated user found',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppColors.error,
                        colorText: Colors.white,
                      );
                      return;
                    }

                    if (subscriptionController.userSubscriptions.isEmpty) {
                      await subscriptionController
                          .fetchSubscriptionsByUser(inviterId);
                    }
                    if (subscriptionController.subscriptions.isEmpty) {
                      await subscriptionController.fetchSubscriptions();
                    }
                    if (orgId != null &&
                        subscriptionController.companySubscriptions.isEmpty) {
                      await subscriptionController.fetchSubscriptionsByCompany(
                        orgId,
                      );
                    }

                    final currentSubscription = subscriptionController
                        .findCurrentSubscriptionForUser(inviterId);
                    final orgSubscription = orgId == null
                        ? null
                        : _findSubscriptionForOrg(
                            [
                              ...subscriptionController.userSubscriptions,
                              ...subscriptionController.companySubscriptions,
                              ...subscriptionController.subscriptions,
                            ],
                            orgId,
                          );
                    final effectiveSubscription =
                        currentSubscription ?? orgSubscription;
                    final plan = _resolvePlan(effectiveSubscription);
                    if (plan == 'free') {
                      Navigator.of(context).pop(); // close invite dialog
                      _showFreePlanDialog();
                      return;
                    }
                    final isOnPremise = _isOnPremisePlan(effectiveSubscription);
                    final isPro = _isProPlan(effectiveSubscription) ||
                        subscriptionController.subscriptions.any(_isProPlan) ||
                        subscriptionController.userSubscriptions
                            .any(_isProPlan) ||
                        subscriptionController.companySubscriptions
                            .any(_isProPlan);
                    final isOnPremiseAny = isOnPremise ||
                        subscriptionController.subscriptions
                            .any(_isOnPremisePlan) ||
                        subscriptionController.userSubscriptions
                            .any(_isOnPremisePlan) ||
                        subscriptionController.companySubscriptions
                            .any(_isOnPremisePlan);

                    int? maxUsers;
                    if (isPro && !isOnPremiseAny) {
                      maxUsers = 5;
                    }

                    if (maxUsers != null) {
                      final currentCount = orgId == null
                          ? widget.controller.users.length
                          : widget.controller.users
                              .where((user) => user.organizationId == orgId)
                              .length;
                      if (currentCount >= maxUsers) {
                        Get.snackbar(
                          'error'.tr,
                          'Limite atteinte: $maxUsers utilisateurs maximum pour cet abonnement.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppColors.error,
                          colorText: Colors.white,
                        );
                        return;
                      }
                    }

                    final success = await widget.controller.inviteCompanyUser(
                      email,
                      inviterId,
                      organizationId:
                          authController.currentUser.value?.organizationId,
                    );

                    if (!mounted) return;

                    Navigator.of(context).pop();

                    if (success) {
                      Get.snackbar(
                        'success'.tr,
                        'Invitation sent',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppColors.success,
                        colorText: Colors.white,
                      );
                    } else {
                      Get.snackbar(
                        'error'.tr,
                        widget.controller.errorMessage.value,
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppColors.error,
                        colorText: Colors.white,
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text('inviter'.tr),
          ),
        ),
      ],
    );
  }

  void _showFreePlanDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Row(
          children: [
            Icon(Icons.lock_outline_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text('Plan gratuit'),
          ],
        ),
        content: const Text(
          'Vous utilisez actuellement le plan gratuit.\n\n'
          'Ce plan ne permet pas d’inviter d’autres utilisateurs. '
          'Pour ajouter des membres à votre équipe, veuillez passer au plan Pro.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.toNamed('/subscription'); // change route if needed
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Passer Pro'),
          ),
        ],
      ),
    );
  }
}
