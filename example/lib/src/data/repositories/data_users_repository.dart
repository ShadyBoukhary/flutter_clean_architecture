
import 'package:example/src/domain/entities/user.dart';
import 'package:example/src/domain/repositories/users_repository.dart';

class DataUsersRepository extends UsersRepository {
  @override
  Future<List<User>> getAllUsers() async {
    return [User('test-uid', 'John Smith', 18), User('test-uid2', 'John Doe', 22)];
  }

  @override
  Future<User> getUser(String uid) async {
    return User('test-uid', 'John Smith', 18);
  }
  
}