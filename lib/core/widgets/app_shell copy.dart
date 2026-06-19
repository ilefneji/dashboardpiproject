import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/dashboard/presentation/controllers/app_search_controller.dart';
import '../theme/app_colors.dart';
import 'app_sidebar.dart';

class AppShell extends StatefulWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final TextEditingController _textCtrl;
  late final AppSearchController _search;

  // route → hint label
  static const Map<String, String> _hints = {
    '/organizations': 'Rechercher...',
    '/task-controls': 'Rechercher...',
  };

  // only show search on these routes
  static const Set<String> _searchableRoutes = {
    '/organizations',
    '/task-controls', // ✅ ADD THIS
  };

  @override
  void initState() {
    super.initState();
    _search = Get.find<AppSearchController>();
    _textCtrl = TextEditingController();

    // if another part of the app clears the query, clear the field too
    ever(_search.query, (String q) {
      if (q.isEmpty && _textCtrl.text.isNotEmpty) _textCtrl.clear();
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Row(
        children: [
          /// ── Sidebar ─────────────────────────────────────────
          const AppSidebar(),

          const SizedBox(width: 2),

          /// ── Right side ──────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                /// ── Top Header ────────────────────────────────
                Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      /// Welcome message
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'welcome'.tr,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Obx(
                            () => Text(
                              '${authController.currentUser.value?.firstname ?? ''} '
                              '${authController.currentUser.value?.lastname ?? ''}',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      /// ── Context-aware search bar ────────────
                      Tooltip(
                        message: 'Déconnexion',
                        child: IconButton(
                          onPressed: () => authController.logout(),
                          icon: const Icon(Icons.logout_rounded),
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),

                /// ── Page Content ──────────────────────────────
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
