import '../../domain/entities/user.dart';
import '../../domain/repositories/users_repository.dart';

class DataUsersRepository extends UsersRepository {
  List<User> users;
  // sigleton
  static final DataUsersRepository _instance = DataUsersRepository._internal();
  DataUsersRepository._internal() : users = <User>[] {
    users.addAll([
      User('test-uid', 'John Smith', 18),
      User('test-uid2', 'John Doe', 22)
    ]);
  }
  factory DataUsersRepository() => _instance;

  @override
  Future<List<User>> getAllUsers() async {
    // Here, do some heavy work lke http requests, async tasks, etc to get data
    return users;
  }

  @override
  Future<User> getUser(String uid) async {
    // Here, do some heavy work lke http requests, async tasks, etc to get data

    return users.firstWhere((user) => user.uid == uid);
  }
}
