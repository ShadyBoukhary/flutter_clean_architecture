class User {
  final String uid;
  final String name;
  final int age;
  User(this.uid, this.name, this.age);

  @override
  String toString() => '$name, $age';
}
