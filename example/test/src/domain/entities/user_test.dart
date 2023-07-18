import 'package:flutter_test/flutter_test.dart';

import 'package:example/src/domain/entities/user.dart';

void main() {
  test('Given User when instantiate into object then return User object values',
      () async {
    final user = User('1000-2000-3000', 'John', 30);
    expect(user.uid, '1000-2000-3000');
    expect(user.name, 'John');
    expect(user.age, 30);
  });
  test(
      'Given User when toString is called Then return string name and age of the user',
      () async {
    final user = User('1000-2000-3000', 'John', 30);
    final strUser = user.toString();
    expect(strUser, 'John, 30');
  });
}
