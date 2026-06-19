import '../entities/user.dart';

abstract class AuthRepository {
  Future<(User?, String?)> login(String email, String password);
  Future<(User?, String?)> googleLogin({
    required String firebaseToken,
    required String email,
    String? name,
    String? photo,
  });
  Future<(bool, String)> sendResetPasswordEmail(String email);
  Future<(bool, String)> validateResetCode(String email, String resetCode);
  Future<(bool, String)> resetPassword(
    String email,
    String resetCode,
    String newPassword,
  );
  Future<void> logout();
  Future<bool> isLoggedIn();
  Future<User?> getCurrentUser();
}
