import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/services/google_auth_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepository;
  final RxBool isLoading = false.obs;
  final RxBool isResetPasswordLoading = false.obs;
  final RxBool isLoggedIn = false.obs;
  final Rxn<User> currentUser = Rxn<User>();

  AuthController(this._authRepository);

  @override
  void onInit() {
    super.onInit();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    isLoggedIn.value = await _authRepository.isLoggedIn();
    if (isLoggedIn.value) {
      currentUser.value = await _authRepository.getCurrentUser();
      Get.offAllNamed('/dashboard');
    }
  }

  Future<bool> login(String email, String password) async {
    isLoading.value = true;

    try {
      final (user, token) = await _authRepository.login(email, password);

      if (user == null || token == null) {
        _showErrorSnackbar('error'.tr, 'invalid_credentials'.tr);
        return false;
      }

      if (!user.isAdmin) {
        _showErrorSnackbar(
          'error'.tr,
          "Vous n'êtes pas administrateur. Pour accéder au tableau de bord, veuillez contacter le responsable.",
        );
        return false;
      }

      // Si tout est OK
      currentUser.value = user;
      isLoggedIn.value = true;
      Get.offAllNamed('/dashboard');
      return true;
    } catch (e) {
      _showErrorSnackbar('error'.tr, e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> loginWithGoogle() async {
    isLoading.value = true;

    try {
      final googleAuth = await GoogleAuthService.signIn();
      final (user, token) = await _authRepository.googleLogin(
        firebaseToken: googleAuth.firebaseToken,
        email: googleAuth.email,
        name: googleAuth.displayName,
        photo: googleAuth.photoUrl,
      );

      if (user == null || token == null) {
        _showErrorSnackbar(
          'Erreur',
          'Erreur lors de la connexion avec Google.',
        );
        return false;
      }

      if (!user.isAdmin) {
        await GoogleAuthService.signOut();
        _showErrorSnackbar(
          'Erreur',
          "Vous n'etes pas administrateur. Pour acceder au tableau de bord, veuillez contacter le responsable.",
        );
        return false;
      }

      currentUser.value = user;
      isLoggedIn.value = true;
      Get.offAllNamed('/dashboard');
      return true;
    } catch (e) {
      _showErrorSnackbar(
        'Erreur',
        'Erreur lors de la connexion avec Google: $e',
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> sendResetPasswordEmail(String email) async {
    isResetPasswordLoading.value = true;

    try {
      final (success, message) = await _authRepository.sendResetPasswordEmail(
        email.trim(),
      );
      if (success) {
        _showSuccessSnackbar('Succès', message);
      } else {
        _showErrorSnackbar('Erreur', message);
      }
      return success;
    } catch (e) {
      _showErrorSnackbar('Erreur', e.toString());
      return false;
    } finally {
      isResetPasswordLoading.value = false;
    }
  }

  Future<bool> validateResetCode(String email, String resetCode) async {
    isResetPasswordLoading.value = true;

    try {
      final (success, message) = await _authRepository.validateResetCode(
        email.trim(),
        resetCode.trim(),
      );
      if (success) {
        _showSuccessSnackbar('Succès', message);
      } else {
        _showErrorSnackbar('Erreur', message);
      }
      return success;
    } catch (e) {
      _showErrorSnackbar('Erreur', e.toString());
      return false;
    } finally {
      isResetPasswordLoading.value = false;
    }
  }

  Future<bool> resetPassword(
    String email,
    String resetCode,
    String newPassword,
  ) async {
    isResetPasswordLoading.value = true;

    try {
      final (success, message) = await _authRepository.resetPassword(
        email.trim(),
        resetCode.trim(),
        newPassword,
      );
      if (success) {
        _showSuccessSnackbar('Succès', message);
      } else {
        _showErrorSnackbar('Erreur', message);
      }
      return success;
    } catch (e) {
      _showErrorSnackbar('Erreur', e.toString());
      return false;
    } finally {
      isResetPasswordLoading.value = false;
    }
  }

  void _showErrorSnackbar(String title, String message) {
    try {
      // Ensure we have a valid context/overlay
      if (Get.context != null && Get.context!.mounted) {
        Get.snackbar(
          title,
          message,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      // If snackbar fails, just print the error
      debugPrint('Error showing snackbar: $e');
    }
  }

  void _showSuccessSnackbar(String title, String message) {
    try {
      if (Get.context != null && Get.context!.mounted) {
        Get.snackbar(
          title,
          message,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      debugPrint('Error showing snackbar: $e');
    }
  }

  Future<void> logout() async {
    try {
      await _authRepository.logout();
    } catch (e) {
      debugPrint('Logout storage error: $e');
    }

    try {
      await GoogleAuthService.signOut();
    } catch (e) {
      debugPrint('Google sign out error: $e');
    } finally {
      currentUser.value = null;
      isLoggedIn.value = false;
      Get.offAllNamed('/login');
    }
  }

  String get userFullName => currentUser.value?.fullName ?? '';

  String get userEmail => currentUser.value?.email ?? '';

  String get userFunction => currentUser.value?.function ?? '';
}
