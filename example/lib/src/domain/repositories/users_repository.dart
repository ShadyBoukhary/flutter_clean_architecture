import 'package:example/src/domain/entities/user.dart';

abstract class UsersRepository {
  Future<User> getUser(String uid);
  Future<List<User>> getAllUsers();
}