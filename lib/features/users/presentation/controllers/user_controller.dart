import 'dart:async';

import 'package:constructiondashboard/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
//lib/features/users/presentation/controllers/user_controller.dart
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '/features/config/presentation/controllers/subscription_controller.dart';

class UserController extends GetxController {
  static const Duration _dashboardLoadTimeout = Duration(seconds: 12);

  final UserRepository _userRepository;

  UserController(this._userRepository);

  final RxList<UserModel> users = <UserModel>[].obs;
  final RxList<UserModel> filteredUsers = <UserModel>[].obs;
  final Rx<UserModel?> selectedUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isProcessing = false.obs;
  final RxBool isInviting = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isCreatingUser = false.obs;
  final RxBool isEditingUser = false.obs;
  final TextEditingController searchController = TextEditingController();
  late final AuthController authController;
  late final SubscriptionController subscriptionController;

  @override
  void onInit() {
    super.onInit();
    authController = Get.find<AuthController>();
    subscriptionController = Get.find<SubscriptionController>();
  }

  Future<void> fetchUsers({bool silent = false}) async {
    if (isLoading.value) {
      debugPrint('[Dashboard][Users] load skipped: already running');
      return;
    }

    final shouldShowLoading = !silent || users.isEmpty;

    if (shouldShowLoading) {
      isLoading.value = true;
    }

    errorMessage.value = '';
    debugPrint('[Dashboard][Users] load started');

    try {
      final currentUserId = authController.currentUser.value?.id;

      if (currentUserId != null) {
        try {
          await subscriptionController
              .fetchSubscriptionsByUser(currentUserId)
              .timeout(_dashboardLoadTimeout);
        } on TimeoutException {
          debugPrint(
            '[Dashboard][Users] subscription context timeout; continuing',
          );
        }
      }

      final result = await _userRepository.getUsers().timeout(
        _dashboardLoadTimeout,
      );

      users.assignAll(result);

      _applySearchFilter();
      debugPrint('[Dashboard][Users] loaded ${users.length} item(s)');
    } on TimeoutException {
      errorMessage.value = 'User loading timeout';
      debugPrint('[Dashboard][Users] timeout after 12s');
    } catch (e) {
      errorMessage.value = 'Failed to load users: $e';
      debugPrint('[Dashboard][Users] error: $e');
    } finally {
      if (shouldShowLoading) {
        isLoading.value = false;
      }
      debugPrint('[Dashboard][Users] loading=${isLoading.value}');
    }
  }

  Future<void> getUserById(int id) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final result = await _userRepository.getUserById(id);
      if (result != null) {
        selectedUser.value = result;
      } else {
        errorMessage.value = 'User not found';
      }
    } catch (e) {
      errorMessage.value = 'Failed to load user: $e';
      debugPrint('Error fetching user: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteUser(int id) async {
    isProcessing.value = true;
    errorMessage.value = '';

    try {
      final result = await _userRepository.deleteUser(id);

      if (result) {
        users.removeWhere((user) => user.id == id);
        _applySearchFilter();

        if (selectedUser.value?.id == id) {
          selectedUser.value = null;
        }

        return true;
      } else {
        errorMessage.value = 'Failed to delete user';
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error deleting user: $e';
      debugPrint('Error deleting user: $e');
      return false;
    } finally {
      isProcessing.value = false;
    }
  }

  Future<bool> activateUser(int id) async {
    isProcessing.value = true;
    errorMessage.value = '';

    try {
      final result = await _userRepository.activateUser(id);

      if (result) {
        final index = users.indexWhere((user) => user.id == id);
        if (index != -1) {
          users[index] = users[index].copyWith(isActive: true);
          users.refresh();
          _applySearchFilter();
        }

        if (selectedUser.value?.id == id) {
          selectedUser.value = selectedUser.value!.copyWith(isActive: true);
        }

        return true;
      } else {
        errorMessage.value = 'Failed to activate user';
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error activating user: $e';
      debugPrint('Error activating user: $e');
      return false;
    } finally {
      isProcessing.value = false;
    }
  }

  Future<bool> deactivateUser(int id) async {
    isProcessing.value = true;
    errorMessage.value = '';

    try {
      final result = await _userRepository.deactivateUser(id);

      if (result) {
        final index = users.indexWhere((user) => user.id == id);
        if (index != -1) {
          users[index] = users[index].copyWith(isActive: false);
          users.refresh();
          _applySearchFilter();
        }

        if (selectedUser.value?.id == id) {
          selectedUser.value = selectedUser.value!.copyWith(isActive: false);
        }

        return true;
      } else {
        errorMessage.value = 'Failed to deactivate user';
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error deactivating user: $e';
      debugPrint('Error deactivating user: $e');
      return false;
    } finally {
      isProcessing.value = false;
    }
  }

  Future<bool> makeAdmin(int id) async {
    isProcessing.value = true;
    errorMessage.value = '';

    try {
      final result = await _userRepository.makeAdmin(id);

      if (result) {
        await fetchUsers();

        if (selectedUser.value?.id == id) {
          selectedUser.value = selectedUser.value!.copyWith(isAdmin: true);
        }

        return true;
      } else {
        errorMessage.value = 'Failed to promote user to admin';
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error promoting user to admin: $e';
      debugPrint('Error promoting user to admin: $e');
      return false;
    } finally {
      isProcessing.value = false;
    }
  }

  Future<bool> demoteAdmin(int id) async {
    isProcessing.value = true;
    errorMessage.value = '';

    try {
      final result = await _userRepository.demoteAdmin(id);

      if (result) {
        await fetchUsers();

        if (selectedUser.value?.id == id) {
          selectedUser.value = selectedUser.value!.copyWith(isAdmin: false);
        }

        return true;
      } else {
        errorMessage.value = 'Failed to demote admin';
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error demoting admin: $e';
      debugPrint('Error demoting admin: $e');
      return false;
    } finally {
      isProcessing.value = false;
    }
  }

  Future<bool> inviteCompanyUser(
    String email,
    int inviterId, {
    int? organizationId,
  }) async {
    errorMessage.value = '';

    final currentUserId = authController.currentUser.value?.id;

    final currentSubscription = subscriptionController
        .findCurrentSubscriptionForUser(currentUserId);

    final currentPlan =
        currentSubscription?.plan?.trim().toLowerCase() ??
        currentSubscription?.company?.plan?.trim().toLowerCase() ??
        currentSubscription?.project?.company?.plan?.trim().toLowerCase() ??
        'free';

    if (currentPlan == 'free') {
      errorMessage.value =
          'Le plan gratuit ne permet pas d’inviter d’autres utilisateurs.';
      Get.snackbar(
        'Plan gratuit',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (email.isEmpty) {
      errorMessage.value = 'Please enter an email address';
      return false;
    }

    if (!GetUtils.isEmail(email)) {
      errorMessage.value = 'Please enter a valid email address';
      return false;
    }

    isInviting.value = true;

    try {
      final result = await _userRepository.inviteCompanyUser(
        email,
        inviterId,
        organizationId: organizationId,
      );

      if (result) {
        await fetchUsers();
        return true;
      } else {
        errorMessage.value = 'Failed to send invitation';
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error sending invitation: $e';
      debugPrint('Error sending invitation: $e');
      return false;
    } finally {
      isInviting.value = false;
    }
  }

  void setCreatingUser(bool value) {
    isCreatingUser.value = value;
  }

  void setEditingUser(bool value, [UserModel? user]) {
    isEditingUser.value = value;
    if (user != null) {
      selectedUser.value = user;
    }
  }

  void clearSelectedUser() {
    selectedUser.value = null;
  }

  void searchUsers(String query) {
    _applySearchFilter(query);
  }

  void _applySearchFilter([String? query]) {
    final effectiveQuery = (query ?? searchController.text)
        .trim()
        .toLowerCase();

    if (effectiveQuery.isEmpty) {
      filteredUsers.assignAll(users);
      return;
    }

    filteredUsers.assignAll(
      users.where((user) {
        return (user.firstname?.toLowerCase().contains(effectiveQuery) ??
                false) ||
            (user.lastname?.toLowerCase().contains(effectiveQuery) ?? false) ||
            (user.email?.toLowerCase().contains(effectiveQuery) ?? false) ||
            (user.function?.toLowerCase().contains(effectiveQuery) ?? false);
      }).toList(),
    );
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
