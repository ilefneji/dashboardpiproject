// ─────────────────────────────────────────────
// presentation/controllers/subscription_controller.dart
// ─────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/repositories/config_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class SubscriptionController extends GetxController {
  final ConfigRepository _configRepository;

  SubscriptionController(this._configRepository);

  // ── Observables ────────────────────────────
  final RxList<SubscriptionModel> subscriptions = <SubscriptionModel>[].obs;
  final RxList<SubscriptionModel> subscriptionHistory =
      <SubscriptionModel>[].obs;
  final RxList<SubscriptionModel> companySubscriptions =
      <SubscriptionModel>[].obs;
  final RxList<SubscriptionModel> userSubscriptions = <SubscriptionModel>[].obs;
  final Rx<SubscriptionModel?> selectedSubscription = Rx<SubscriptionModel?>(
    null,
  );

  // ── Loading states (granular) ──────────────
  final RxBool isLoading = false.obs;
  final RxBool isCreating = false.obs;
  final RxBool isUpdating = false.obs;
  final RxBool isDeleting = false.obs;
  final RxBool isCancelling = false.obs;
  final RxBool isDownloading = false.obs;

  // ── Error ──────────────────────────────────
  final RxString errorMessage = ''.obs;
  Worker? _authWorker;

  // ════════════════════════════════════════════
  // 🚀 Lifecycle
  // ════════════════════════════════════════════

  @override
  void onInit() {
    super.onInit();

    final authController = Get.find<AuthController>();

    final userId = authController.currentUser.value?.id;
    if (userId != null) {
      fetchSubscriptionsByUser(userId);
    }

    _authWorker = ever(authController.currentUser, (user) {
      final id = user?.id;

      if (id == null) {
        userSubscriptions.clear();
        selectedSubscription.value = null;
        return;
      }

      fetchSubscriptionsByUser(id);
    });
  }

  @override
  void onClose() {
    _authWorker?.dispose();
    super.onClose();
  }
  // ════════════════════════════════════════════
  // 📥 READ
  // ════════════════════════════════════════════

  Future<void> fetchSubscriptions() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      print('[SubscriptionController] fetchSubscriptions() called');
      final result = await _configRepository.getSubscriptions();
      subscriptions.assignAll(result);
      print('[SubscriptionController] ✅ Loaded ${result.length} subscriptions');
    } catch (e) {
      errorMessage.value = 'Failed to load subscriptions: $e';
      print('[SubscriptionController] ❌ fetchSubscriptions: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchSubscription(int id) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final result = await _configRepository.getSubscription(id);
      selectedSubscription.value = result;
    } catch (e) {
      errorMessage.value = 'Failed to load subscription: $e';
      print('[SubscriptionController] ❌ fetchSubscription($id): $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchSubscriptionHistory() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final result = await _configRepository.getSubscriptionHistory();
      subscriptionHistory.value = result;
    } catch (e) {
      errorMessage.value = 'Failed to load history: $e';
      print('[SubscriptionController] ❌ fetchSubscriptionHistory: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchSubscriptionsByCompany(int companyId) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final result = await _configRepository.getSubscriptionsByCompany(
        companyId,
      );
      companySubscriptions.value = result;
    } catch (e) {
      errorMessage.value = 'Failed to load company subscriptions: $e';
      print(
        '[SubscriptionController] ❌ fetchSubscriptionsByCompany($companyId): $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchSubscriptionsByUser(int userId) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      print(
        '[SubscriptionController] fetchSubscriptionsByUser($userId) called',
      );
      final result = await _configRepository.getSubscriptionsByUser(userId);
      userSubscriptions.assignAll(result);
      print(
        '[SubscriptionController] ✅ Loaded ${result.length} user subscriptions',
      );
    } catch (e) {
      errorMessage.value = 'Failed to load user subscriptions: $e';
      print('[SubscriptionController] ❌ fetchSubscriptionsByUser($userId): $e');
    } finally {
      isLoading.value = false;
    }
  }

  SubscriptionModel? findCurrentSubscriptionForUser(int? userId) {
    if (userId == null) return null;

    final now = DateTime.now();
    final matches = userSubscriptions.where((sub) {
      final belongsToUser =
          sub.userIds.contains(userId) ||
          sub.subscriptionUsers.any((su) => su.userId == userId) ||
          (sub.project?.userProjects.any((up) => up.userId == userId) ??
              false) ||
          (sub.company?.userCompanies.any((uc) => uc.userId == userId) ??
              false) ||
          (sub.project?.company?.userCompanies.any(
                (uc) => uc.userId == userId,
              ) ??
              false);

      return belongsToUser;
    }).toList();

    if (matches.isEmpty) return null;

    int score(SubscriptionModel s) {
      int value = 0;

      final paymentStatus = (s.paymentStatus ?? '').toLowerCase();
      final status = (s.status ?? '').toLowerCase();
      final endDate = s.currentPeriodEnd ?? s.project?.endDate;
      final currentPlan =
          s.plan?.trim().toLowerCase() ??
          s.company?.plan?.trim().toLowerCase() ??
          s.project?.company?.plan?.trim().toLowerCase() ??
          'free';

      if (paymentStatus == 'paid') value += 100;
      if (status == 'active') value += 60;
      if (status == 'trialing') value += 40;
      if (endDate != null && endDate.isAfter(now)) value += 20;
      if (currentPlan == 'pro') value += 10;

      return value;
    }

    matches.sort((a, b) {
      final scoreCompare = score(b).compareTo(score(a));
      if (scoreCompare != 0) return scoreCompare;

      final aEnd = a.currentPeriodEnd ?? a.project?.endDate;
      final bEnd = b.currentPeriodEnd ?? b.project?.endDate;

      if (aEnd == null && bEnd == null) return 0;
      if (aEnd == null) return 1;
      if (bEnd == null) return -1;

      return bEnd.compareTo(aEnd);
    });

    return matches.first;
  }
  // ════════════════════════════════════════════
  // ✏️ WRITE
  // ════════════════════════════════════════════

  Future<SubscriptionModel?> createSubscription(
    Map<String, dynamic> data,
  ) async {
    isCreating.value = true;
    errorMessage.value = '';
    try {
      final result = await _configRepository.createSubscription(data);
      if (result != null) {
        subscriptions.add(result);
        _showSuccess('Abonnement créé avec succès');
      }
      return result;
    } catch (e) {
      errorMessage.value = 'Failed to create subscription: $e';
      _showError('Échec de la création de l\'abonnement');
      print('[SubscriptionController] ❌ createSubscription: $e');
      return null;
    } finally {
      isCreating.value = false;
    }
  }

  Future<String?> createRenewalCheckoutUrl({int? subscriptionId}) async {
    isUpdating.value = true;
    errorMessage.value = '';

    try {
      final authController = Get.find<AuthController>();
      final userId = authController.currentUser.value?.id;

      SubscriptionModel? currentSub = selectedSubscription.value;

      currentSub ??= findCurrentSubscriptionForUser(userId);

      if (currentSub == null && userSubscriptions.isNotEmpty) {
        currentSub = userSubscriptions.first;
      }

      final id = subscriptionId ?? currentSub?.id;

      if (id == null) {
        errorMessage.value = 'Aucun abonnement trouvé.';
        return null;
      }

      return await _configRepository.createRenewalCheckoutSession(
        subscriptionId: id,
      );
    } catch (e) {
      errorMessage.value = 'Erreur paiement: $e';
      return null;
    } finally {
      isUpdating.value = false;
    }
  }

  Future<SubscriptionModel?> updateSubscription(
    int id,
    Map<String, dynamic> data,
  ) async {
    isUpdating.value = true;
    errorMessage.value = '';
    try {
      final result = await _configRepository.updateSubscription(id, data);
      if (result != null) {
        // Replace in list
        final idx = subscriptions.indexWhere((s) => s.id == id);
        if (idx != -1) subscriptions[idx] = result;

        // Update selected if it's the same
        if (selectedSubscription.value?.id == id) {
          selectedSubscription.value = result;
        }
        _showSuccess('Abonnement mis à jour');
      }
      return result;
    } catch (e) {
      errorMessage.value = 'Failed to update subscription: $e';
      _showError('Échec de la mise à jour');
      print('[SubscriptionController] ❌ updateSubscription($id): $e');
      return null;
    } finally {
      isUpdating.value = false;
    }
  }

  Future<bool> deleteSubscription(int id) async {
    isDeleting.value = true;
    errorMessage.value = '';
    try {
      final success = await _configRepository.deleteSubscription(id);
      if (success) {
        subscriptions.removeWhere((s) => s.id == id);
        if (selectedSubscription.value?.id == id) {
          selectedSubscription.value = null;
        }
        _showSuccess('Abonnement supprimé');
      }
      return success;
    } catch (e) {
      errorMessage.value = 'Failed to delete subscription: $e';
      _showError('Échec de la suppression');
      print('[SubscriptionController] ❌ deleteSubscription($id): $e');
      return false;
    } finally {
      isDeleting.value = false;
    }
  }

  Future<bool> cancelSubscription(int id) async {
    isCancelling.value = true;
    errorMessage.value = '';
    try {
      final success = await _configRepository.cancelSubscription(id);
      if (success) {
        // Refresh to get updated cancelAtPeriodEnd flag
        await fetchSubscription(id);
        _showSuccess('Abonnement annulé en fin de période');
      }
      return success;
    } catch (e) {
      errorMessage.value = 'Failed to cancel subscription: $e';
      _showError('Échec de l\'annulation');
      print('[SubscriptionController] ❌ cancelSubscription($id): $e');
      return false;
    } finally {
      isCancelling.value = false;
    }
  }

  // ════════════════════════════════════════════
  // 🧾 Invoice
  // ════════════════════════════════════════════

  Future<void> downloadInvoice(int id) async {
    isDownloading.value = true;
    errorMessage.value = '';

    try {
      _showLoadingDialog();

      final pdfData = await _configRepository.downloadInvoice(id);
      _closeDialog();

      if (pdfData == null) {
        _showError('Facture non disponible');
        return;
      }

      // ── Build filename ─────────────────────
      final sub = await _configRepository.getSubscription(id);
      final fileName = _buildInvoiceFileName(sub);

      if (kIsWeb) {
        // TODO: implement web download via dart:html
        _showWarning('Téléchargement PDF non disponible sur web');
        return;
      }

      // ── Mobile: save & open ────────────────
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/$fileName.pdf';
      final file = File(filePath);
      await file.writeAsBytes(pdfData);

      final uri = Uri.file(filePath);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        _showSuccess('Facture téléchargée avec succès');
      } else {
        _showError('Impossible d\'ouvrir la facture');
      }
    } catch (e) {
      _closeDialog();
      errorMessage.value = 'Failed to download invoice: $e';
      _showError('Échec du téléchargement de la facture');
      print('[SubscriptionController] ❌ downloadInvoice($id): $e');
    } finally {
      isDownloading.value = false;
    }
  }

  // ════════════════════════════════════════════
  // 🔧 Computed helpers
  // ════════════════════════════════════════════

  /// Returns subscriptions expiring within [withinDays] days
  List<SubscriptionModel> get expiringSubscriptions {
    final now = DateTime.now();
    return subscriptions.where((s) {
      final end = s.currentPeriodEnd ?? s.project?.endDate;
      if (end == null) return false;
      final diff = end.difference(now).inDays;
      return diff >= 0 && diff <= 7;
    }).toList();
  }

  /// Returns subscriptions that are already expired
  List<SubscriptionModel> get expiredSubscriptions {
    final now = DateTime.now();
    return subscriptions.where((s) {
      final end = s.currentPeriodEnd ?? s.project?.endDate;
      if (end == null) return false;
      return end.isBefore(now);
    }).toList();
  }

  /// Returns active subscriptions only
  List<SubscriptionModel> get activeSubscriptions {
    return subscriptions
        .where((s) => s.status?.toLowerCase() == 'active')
        .toList();
  }

  /// Days remaining for a given subscription (-1 if no end date)
  int daysRemaining(SubscriptionModel sub) {
    final end = sub.currentPeriodEnd ?? sub.project?.endDate;
    if (end == null) return -1;
    return end.difference(DateTime.now()).inDays;
  }

  // ════════════════════════════════════════════
  // 🔒 Private helpers
  // ════════════════════════════════════════════

  String _buildInvoiceFileName(SubscriptionModel? sub) {
    if (sub == null) return 'facture';
    final project = sub.project?.name?.replaceAll(' ', '_') ?? 'projet';
    final month = sub.month != null
        ? DateFormat(
            'MMMM',
            'fr_FR',
          ).format(DateTime(DateTime.now().year, sub.month!))
        : 'mois';
    final year = sub.year ?? DateTime.now().year;
    return 'facture_${project}_${month}_$year';
  }

  void _showLoadingDialog() {
    Get.dialog(
      const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 14),
                Text('Téléchargement de la facture...'),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _closeDialog() {
    if (Get.isDialogOpen ?? false) Get.back();
  }

  void _showSuccess(String message) => Get.snackbar(
    'Succès',
    message,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: AppColors.success,
    colorText: Colors.white,
    duration: const Duration(seconds: 3),
    icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
  );

  void _showError(String message) => Get.snackbar(
    'Erreur',
    message,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: AppColors.error,
    colorText: Colors.white,
    duration: const Duration(seconds: 3),
    icon: const Icon(Icons.error_rounded, color: Colors.white),
  );

  void _showWarning(String message) => Get.snackbar(
    'Info',
    message,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: AppColors.warning,
    colorText: Colors.white,
    duration: const Duration(seconds: 3),
    icon: const Icon(Icons.warning_rounded, color: Colors.white),
  );

  bool isCurrentUserBlocked() {
    final authController = Get.find<AuthController>();
    final userId = authController.currentUser.value?.id;

    final currentSub = findCurrentSubscriptionForUser(userId);

    final endDate =
        currentSub?.currentPeriodEnd ?? currentSub?.project?.endDate;

    if (endDate == null) {
      return false; // no end date = not blocked
    }

    return endDate.isBefore(DateTime.now());
  }
}
