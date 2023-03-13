import 'package:example/src/data/repositories/data_users_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('data users repository ...', () async {
    final testDataUserRepository = DataUsersRepository();
    final testUser = await testDataUserRepository.getUser('test-uid');
    expect(testUser.name, 'John Smith');
    expect(testUser.age, 18);
  });
  test('data users repository ...', () async {
    final testDataUserRepository = DataUsersRepository();
    final testUser = await testDataUserRepository.getAllUsers();
    expect(testUser.length, 2);
    expect(testUser[0].name, 'John Smith');
    expect(testUser[0].age, 18);
    expect(testUser[1].name, 'John Doe');
    expect(testUser[1].age, 22);
  });
}
