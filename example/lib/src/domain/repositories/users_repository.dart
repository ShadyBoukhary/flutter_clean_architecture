import '../entities/user.dart';

abstract class UsersRepository {
  Future<User> getUser(String uid);
  Future<List<User>> getAllUsers();
}