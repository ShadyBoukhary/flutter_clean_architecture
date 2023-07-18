import 'package:example/src/domain/usecases/get_user_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:example/src/domain/repositories/users_repository.dart';
import 'package:example/src/domain/entities/user.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

void main() {
  test(
      'Given getUserUseCase when Parameters user UUID does exist return successfull',
      () async {
    GetUserUseCase getUserUseCase;
    _Observer observer;
    getUserUseCase = GetUserUseCase(MockGetUser());
    observer = _Observer();
    getUserUseCase.execute(observer, GetUserUseCaseParams('1000-2000-5600'));
    while (!observer.status['progress']!.contains('done')) {
      await Future.delayed(const Duration(seconds: 1));
    }
    expect(observer.status['result'], 'success');
  });
  test(
      'Given getUserUseCase when getUser and user UUID does exist return the namd and the age',
      () async {
    GetUserUseCase getUserUseCase;
    getUserUseCase = GetUserUseCase(MockGetUser());
    final testUser =
        await getUserUseCase.usersRepository.getUser('1000-2000-5600');
    expect(testUser.name, 'John');
    expect(testUser.age, 30);
  });
  test(
      'Given getUserUseCase when Parameters user UUID does not exist return failed',
      () async {
    GetUserUseCase getUserUseCase;
    _Observer observer;
    getUserUseCase = GetUserUseCase(MockGetUser());
    observer = _Observer();
    getUserUseCase.execute(observer, GetUserUseCaseParams('22222'));
    while (!observer.status['progress']!.contains('done')) {
      await Future.delayed(const Duration(seconds: 1));
    }
    expect(observer.status['result'], 'failed');
  });
}

class _Observer implements Observer<GetUserUseCaseResponse> {
  final status = {'progress': 'starting', 'result': ''};
  @override
  void onNext(response) {
    expect(GetUserUseCaseResponse, response.runtimeType);
    status['progress'] = 'done';
    status['result'] = 'success';
  }

  @override
  void onComplete() {}

  @override
  void onError(e) {
    status['progress'] = 'done';
    status['result'] = 'failed';
  }
}

class MockGetUser extends Mock implements UsersRepository {
  List<User> users = [];

  MockGetUser() {
    users.add(User('1000-2000-5600', 'John', 30));
    users.add(User('1000-3000-2900', 'Juan', 42));
    users.add(User('1000-5000-3100', 'Maria', 12));
  }

  @override
  Future<User> getUser(String uid) async {
    User? testGetUser;
    for (var user in users) {
      if (user.uid == uid) {
        testGetUser = user;
      }
    }
    if (testGetUser != null) {
      return testGetUser;
    } else {
      throw Exception('User not found');
    }
  }
}
