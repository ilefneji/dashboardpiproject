import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/dashboard/presentation/controllers/dashboard_navigation_controller.dart';
import '../../features/dashboard/presentation/widgets/dashboard_section_host.dart';
import '../theme/app_colors.dart';
import '../theme/theme_controller.dart';
import 'app_sidebar.dart';
import 'cached_avatar_image.dart';

class AppShell extends StatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final String _initialRoute;
  late final bool _usesSectionHost;

  @override
  void initState() {
    super.initState();
    _initialRoute = Get.currentRoute;
    final navigationController = Get.find<DashboardNavigationController>();
    _usesSectionHost = navigationController.isSectionRoute(_initialRoute);
    if (_usesSectionHost) {
      navigationController.syncFromRoute(_initialRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewportWidth = MediaQuery.of(context).size.width;
    final isDesktop = viewportWidth >= 1024;
    final isTablet = viewportWidth >= 600 && !isDesktop;
    final sidebarWidth = viewportWidth >= 1600
        ? 312.0
        : viewportWidth >= 1280
            ? 296.0
            : 280.0;
    final drawerWidth =
        isTablet ? 280.0 : (viewportWidth - 24).clamp(240.0, 272.0).toDouble();
    final colors = Theme.of(context).colorScheme;
    final content = _usesSectionHost
        ? DashboardSectionHost(
            initialRoute: _initialRoute,
            initialChild: widget.child,
          )
        : widget.child;

    return Scaffold(
      backgroundColor: colors.background,
      drawer: isDesktop
          ? null
          : Drawer(
              width: drawerWidth,
              child: AppSidebar(width: drawerWidth),
            ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        color: colors.background,
        child: Row(
          children: [
            if (isDesktop) AppSidebar(width: sidebarWidth),
            Expanded(
              child: Column(
                children: [
                  _TopBar(showMenuButton: !isDesktop),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: content,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final bool showMenuButton;

  const _TopBar({required this.showMenuButton});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(
              theme.brightness == Brightness.dark ? 0.22 : 0.045,
            ),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          if (showMenuButton) ...[
            Builder(
              builder: (context) => IconButton(
                tooltip: 'Menu',
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu_rounded),
              ),
            ),
            const SizedBox(width: 8),
          ],
          const SizedBox(width: 4),
          _UserAvatar(authController: authController),
          const SizedBox(width: 12),
          Expanded(
            child: _UserGreeting(
              authController: authController,
              colors: colors,
              textTheme: textTheme,
            ),
          ),
          const SizedBox(width: 12),
          GetBuilder<ThemeController>(
            builder: (themeController) => Tooltip(
              message:
                  themeController.isDarkMode ? 'Mode clair' : 'Mode sombre',
              child: InkWell(
                onTap: themeController.toggleTheme,
                borderRadius: BorderRadius.circular(999),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 62,
                  height: 32,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: themeController.isDarkMode
                        ? const Color(0xFF202A37)
                        : const Color(0xFFFFF3EC),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    alignment: themeController.isDarkMode
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: colors.shadow.withOpacity(0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        themeController.isDarkMode
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        color: AppColors.primaryOrange,
                        size: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Déconnexion',
            child: IconButton(
              onPressed: () => authController.logout(),
              icon: const Icon(Icons.logout_rounded),
              color: AppColors.primaryOrange,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final AuthController authController;

  const _UserAvatar({required this.authController});

  @override
  Widget build(BuildContext context) {
    final user = authController.currentUser.value;
    final imageId = user?.imageId;
    final name = [
      user?.firstname ?? '',
      user?.lastname ?? '',
    ].where((part) => part.trim().isNotEmpty).join(' ');
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.primaryOrange.withOpacity(0.14),
      child: imageId != null 
          ? CachedAvatarImage(
              imageId: imageId.toString(),
              initials: initials,
              initialsStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.primaryOrange,
                    fontWeight: FontWeight.w800,
                  ),
            )
          : Text(
              initials,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.primaryOrange,
                    fontWeight: FontWeight.w800,
                  ),
            ),
    );
  }
}

class _UserGreeting extends StatelessWidget {
  final AuthController authController;
  final ColorScheme colors;
  final TextTheme textTheme;

  const _UserGreeting({
    required this.authController,
    required this.colors,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final user = authController.currentUser.value;
    final name = [
      user?.firstname ?? '',
      user?.lastname ?? '',
    ].where((part) => part.trim().isNotEmpty).join(' ');

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PI Project Admin',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          name.isEmpty ? 'workspace'.tr : '${'welcome'.tr}, $name',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
