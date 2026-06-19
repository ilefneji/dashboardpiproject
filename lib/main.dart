import 'package:constructiondashboard/core/navigation/auth_middleware.dart';
import 'package:constructiondashboard/features/journal/presentation/binding/journal_binding.dart';
import 'package:constructiondashboard/features/project/data/repositories/project_repository_impl.dart';
import 'package:constructiondashboard/features/project/domain/repositories/project_repository.dart';
import 'package:constructiondashboard/features/task-control/presentation/bindings/task_control_binding.dart';
import 'package:constructiondashboard/features/task-control/presentation/screens/task_control_list_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:constructiondashboard/features/project/presentation/widgets/project_form_dialog.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/create_password_screen.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/dashboard/presentation/bindings/dashboard_binding.dart';
import 'features/dashboard/presentation/controllers/app_search_controller.dart';
import 'features/dashboard/presentation/controllers/dashboard_navigation_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/translations/app_translations.dart';
import 'features/organization/presentation/pages/organization_list_page.dart';
import 'features/organization/presentation/pages/add_organization_page.dart';
import 'features/organization/presentation/pages/edit_organization_page.dart';
import 'features/organization/presentation/binding/organization_bindinig.dart';
import 'features/organization/domain/entities/organization.dart';
import 'features/config/presentation/pages/config_page.dart';
import 'features/config/presentation/pages/subscription_list_page.dart';
import 'features/config/presentation/binding/config_binding.dart';
import 'features/config/data/repositories/config_repository_impl.dart';
import 'features/config/domain/repositories/config_repository.dart';
import 'features/config/presentation/controllers/subscription_controller.dart';
import 'features/task/presentation/screens/task_list_screen.dart';
import 'features/task/presentation/bindings/task_binding.dart';
import 'features/users/presentation/binding/user_binding.dart';
import 'features/users/presentation/pages/user_list_page.dart';
import 'features/users/presentation/pages/user_detail_page.dart';
import 'features/project/presentation/binding/project_binding.dart';
import 'features/project/presentation/screens/project_admin_detail_screen.dart';
import 'features/project/presentation/screens/project_list_screen.dart';
import 'features/lot/presentation/screens/lot_list_screen.dart';
import 'features/lot/presentation/bindings/lot_binding.dart';
import 'features/document/presentation/bindings/document_binding.dart';
import 'features/document/presentation/pages/document_list_page.dart';
import 'features/journal/presentation/pages/journal_list_page.dart';
import 'features/journal/presentation/widgets/journal_detail_page.dart';
import 'features/search/presentation/binding/search_binding.dart';
import 'features/search/presentation/pages/search_results_page.dart';
import 'features/search/presentation/controllers/search_controller.dart';
import 'core/network/api_client.dart';
import 'core/navigation/app_route_observer.dart';
import 'core/services/stripe_payment_service.dart';
import 'firebase_options.dart';

// ✅ ÉTAPE 1 — main() est async pour permettre await Stripe
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final themeController = Get.put(ThemeController(), permanent: true);
  await themeController.loadTheme();

  if (!kIsWeb) {
    // ✅ ÉTAPE 2 — Clé PUBLISHABLE (pk_test_...) jamais la secret key !
    Stripe.publishableKey =
        'pk_test_51TNfI0K6pPTHGbrz3xuQI4QaaCt9dZsl8ry5u2jx7g2MJCeO1iaNeYYzQlVToPLGzziP0gNhIG2lgulxnLb0cKYM00DycFsszg';

    // ✅ ÉTAPE 3 — Appliquer les paramètres Stripe
    await Stripe.instance.applySettings();
  }

  runApp(const MyApp());
}

// ══════════════════════════════════════════════════════════════
// 📱 MyApp
// ══════════════════════════════════════════════════════════════
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  String _getInitialRoute() {
    final path = Uri.base.path;
    if (path.isEmpty || path == '/') {
      return '/login';
    }
    return path;
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return GetMaterialApp(
      title: 'Construction Dashboard',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeController.themeMode.value,
      translations: AppTranslations(),
      locale: const Locale('fr', 'FR'),
      fallbackLocale: const Locale('fr', 'FR'),
      debugShowCheckedModeBanner: false,
      initialBinding: AppBinding(),
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('fr', 'FR'),
        Locale('ar', 'AR'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: _getInitialRoute(),
      getPages: [
        GetPage(name: '/login', page: () => const LoginPage()),
        GetPage(
          name: '/create-password',
          page: () => const CreatePasswordScreen(),
        ),
        GetPage(
          name: '/dashboard',
          page: () => const DashboardPage(),
          binding: DashboardBinding(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: '/organizations',
          page: () => const OrganizationListPage(),
          binding: OrganizationBinding(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: '/organizations/add',
          page: () => const AddOrganizationPage(),
          binding: OrganizationBinding(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: '/organizations/edit',
          page: () {
            final org = Get.arguments as Organization;
            return EditOrganizationPage(organization: org);
          },
          binding: OrganizationBinding(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: '/config',
          page: () => const ConfigPage(),
          binding: ConfigBinding(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: '/config/subscriptions',
          page: () => const SubscriptionListPage(),
          binding: ConfigBinding(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: '/tasks',
          page: () => const TaskListScreen(),
          binding: TaskBinding(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: '/task-controls',
          page: () => const TaskControlListScreen(),
          binding: TaskControlBinding(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: '/users',
          page: () => const UserListPage(),
          binding: UserBinding(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: '/users/:id',
          page: () => const UserDetailPage(),
          binding: UserBinding(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: '/projects',
          page: () => const ProjectListScreen(),
          binding: ProjectBinding(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: '/projects/archive',
          page: () => const ProjectListScreen(showArchived: true),
          binding: ProjectBinding(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: '/projects/:id',
          page: () => const ProjectAdminDetailScreen(),
          binding: ProjectBinding(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: '/journal-detail',
          page: () => const JournalDetailPage(),
          binding: JournalBinding(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: '/project-form',
          page: () => const ProjectFormDialog(),
          binding: ProjectBinding(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: '/lots',
          page: () => const LotListScreen(),
          binding: LotBinding(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: '/journal',
          page: () => const JournalListPage(),
          binding: JournalBinding(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: '/documents',
          page: () => const DocumentListPage(),
          binding: DocumentBinding(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: '/search',
          page: () => SearchResultsPage(
            searchController: Get.find<GlobalSearchController>(),
          ),
          binding: SearchBinding(),
          middlewares: [AuthMiddleware()],
        ),
      ],
      unknownRoute: GetPage(name: '/login', page: () => const LoginPage()),
      navigatorObservers: [appRouteObserver],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 🔌 AppBinding
// ══════════════════════════════════════════════════════════════
// ══════════════════════════════════════════════════════════════
// 🔌 AppBinding
// ══════════════════════════════════════════════════════════════
class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ApiClient(), permanent: true);

    final authRepository = AuthRepositoryImpl(
      storage: const FlutterSecureStorage(),
    );

    Get.put<AuthRepository>(authRepository, permanent: true);
    Get.put(AuthController(authRepository), permanent: true);
    Get.put(AppSearchController(), permanent: true);
    Get.put(GlobalSearchController(), permanent: true);
    Get.put(DashboardNavigationController(), permanent: true);

    // ✅ Stripe Payment Service
    Get.put(StripePaymentService(), permanent: true);

    Get.lazyPut<ConfigRepository>(
      () => ConfigRepositoryImpl(Get.find<ApiClient>()),
      fenix: true,
    );
    Get.put<SubscriptionController>(
      SubscriptionController(Get.find<ConfigRepository>()),
      permanent: true,
    );

    Get.lazyPut<ProjectRepository>(
      () => ProjectRepositoryImpl(apiClient: Get.find<ApiClient>()),
      fenix: true,
    );
  }
}
