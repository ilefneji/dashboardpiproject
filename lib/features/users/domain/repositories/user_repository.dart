import '../entities/user.dart';

abstract class UserRepository {
  Future<List<UserModel>> getUsers();
  Future<UserModel?> getUserById(int id);
  Future<UserModel?> createUser(UserModel user);
  Future<bool> updateUser(UserModel user);
  Future<bool> deleteUser(int id);
  Future<bool> activateUser(int id);
  Future<bool> deactivateUser(int id);
  Future<bool> makeAdmin(int id);
  Future<bool> inviteCompanyUser(String email, int inviterId, {int? organizationId});
  Future<bool> demoteAdmin(int id);
}
