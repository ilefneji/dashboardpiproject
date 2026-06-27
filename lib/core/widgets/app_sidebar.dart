import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/config/presentation/controllers/subscription_controller.dart';
import '../../features/dashboard/presentation/bindings/dashboard_section_bindings.dart';
import '../../features/dashboard/presentation/controllers/dashboard_navigation_controller.dart';
import '../theme/app_colors.dart';
import 'cached_avatar_image.dart';

class AppSidebar extends StatelessWidget {
  final double width;

  const AppSidebar({super.key, this.width = 280});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final subscriptionController = Get.find<SubscriptionController>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(right: BorderSide(color: colors.outlineVariant)),
      ),
      child: Column(
        children: [
          _BrandHeader(colors: colors, textTheme: theme.textTheme),
          Expanded(
            child: _SidebarNavigation(
              authController: authController,
              subscriptionController: subscriptionController,
            ),
          ),
          Divider(height: 1, color: colors.outlineVariant),
          _UserProfile(
            name:
                '${authController.currentUser.value?.firstname ?? ''} ${authController.currentUser.value?.lastname ?? ''}'
                    .trim(),
            email: authController.currentUser.value?.email ?? '',
            imageId: authController.currentUser.value?.imageId,
            onLogout: authController.logout,
          ),
        ],
      ),
    );
  }
}

class _SidebarNavigation extends StatelessWidget {
  final AuthController authController;
  final SubscriptionController subscriptionController;

  const _SidebarNavigation({
    required this.authController,
    required this.subscriptionController,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = authController.currentUser.value;
    final currentSub = subscriptionController.findCurrentSubscriptionForUser(
      currentUser?.id,
    );
    final endDate =
        currentSub?.currentPeriodEnd ?? currentSub?.project?.endDate;
    final daysLeft = endDate?.difference(DateTime.now()).inDays;
    final isExpiring = daysLeft != null && daysLeft <= 7 && daysLeft >= 0;
    final isExpired = daysLeft != null && daysLeft < 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel(label: 'Navigation'),
          _SidebarItem(
            icon: Icons.dashboard_outlined,
            label: 'dashboard'.tr,
            route: '/dashboard',
          ),
          _SidebarItem(
            icon: Icons.business_outlined,
            label: 'Mon organisme'.tr,
            route: '/organizations',
          ),
          _SidebarItem(
            icon: Icons.folder_outlined,
            label: 'projects'.tr,
            route: '/projects',
          ),
          const _SidebarItem(
            icon: Icons.inventory_2_outlined,
            label: 'Archives',
            route: '/projects/archive',
          ),
          const SizedBox(height: 18),
          const _SectionLabel(label: 'Chantier'),
          _SidebarItem(
            icon: Icons.category_outlined,
            label: 'lots'.tr,
            route: '/lots',
          ),
          _SidebarItem(
            icon: Icons.assignment_outlined,
            label: 'tasks'.tr,
            route: '/tasks',
          ),
          _SidebarItem(
            icon: Icons.check_circle_outline,
            label: 'task_controls'.tr,
            route: '/task-controls',
          ),
          _SidebarItem(
            icon: Icons.history_outlined,
            label: 'journal'.tr,
            route: '/journal',
          ),
          const SizedBox(height: 18),
          const _SectionLabel(label: 'Administration'),
          _SidebarItem(
            icon: Icons.people_outline,
            label: 'users'.tr,
            route: '/users',
          ),
          _SidebarItem(
            icon: Icons.list_alt_outlined,
            label: 'subscriptions'.tr,
            route: '/config/subscriptions',
            alert: isExpiring || isExpired,
          ),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  final ColorScheme colors;
  final TextTheme textTheme;

  const _BrandHeader({required this.colors, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: [
          Image.asset('assets/images/logo.png', width: 40, height: 40),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  'PI Project',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                Text(
                  'Construction Suite',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
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

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 8, 9),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.55,
                ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Divider(color: colors.outlineVariant.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }
}

class _UserProfile extends StatelessWidget {
  final String name;
  final String email;
  final int? imageId;
  final VoidCallback onLogout;

  const _UserProfile({
    required this.name,
    required this.email,
    this.imageId,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

    Widget avatarWidget() {
      if (imageId != null ) {
        return CachedAvatarImage(
          imageId: imageId!.toString()  ,
          initials: initials,
          initialsStyle: theme.textTheme.titleSmall?.copyWith(
            color: AppColors.primaryOrange,
            fontWeight: FontWeight.w800,
          ),
        );
      }
      return Text(
        initials,
        style: theme.textTheme.titleSmall?.copyWith(
          color: AppColors.primaryOrange,
          fontWeight: FontWeight.w800,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: InkWell(
        onTap: onLogout,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
          decoration: BoxDecoration(
            color: colors.surfaceVariant.withOpacity(
              theme.brightness == Brightness.dark ? 0.55 : 0.7,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryOrange.withOpacity(0.14),
                child: avatarWidget(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Admin' : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: 'Déconnexion',
                child: IconButton(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout_rounded, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String route;
  final bool alert;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.route,
    this.alert = false,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final navigationController = Get.find<DashboardNavigationController>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    const alertColor = Color(0xFFDC2626);
    final accent = widget.alert ? alertColor : AppColors.primaryOrange;
    final activeBg = accent.withOpacity(
      theme.brightness == Brightness.dark ? 0.18 : 0.10,
    );
    final hoverBg = colors.surfaceVariant.withOpacity(
      theme.brightness == Brightness.dark ? 0.45 : 0.65,
    );

    return Obx(() {
      final activeRoute = navigationController.activeSidebarRoute(
        Get.currentRoute,
      );
      final selected = activeRoute == widget.route;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: InkWell(
            onTap: () {
              if (selected) return;

              final currentRoute = Get.currentRoute;
              final isInsideDashboardSection =
                  navigationController.isSectionRoute(currentRoute);

              if (widget.route == '/dashboard' &&
                  currentRoute != '/dashboard') {
                Get.offNamed(widget.route);
                return;
              }

              if (!isInsideDashboardSection) {
                Get.offNamed(widget.route);
                return;
              }

              DashboardSectionBindings.ensure(widget.route);
              navigationController.select(widget.route);

              final scaffold = Scaffold.maybeOf(context);
              if (scaffold?.isDrawerOpen ?? false) {
                Navigator.of(context).pop();
              }
            },
            borderRadius: BorderRadius.circular(13),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                color: selected
                    ? activeBg
                    : (_hovered ? hoverBg : Colors.transparent),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color:
                      selected ? accent.withOpacity(0.30) : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: selected
                          ? accent
                          : accent.withOpacity(
                              theme.brightness == Brightness.dark ? 0.15 : 0.08,
                            ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 18,
                      color: selected ? Colors.white : accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: selected
                            ? accent
                            : (widget.alert ? alertColor : colors.onSurface),
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                        height: 1.15,
                      ),
                    ),
                  ),
                  if (selected)
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
