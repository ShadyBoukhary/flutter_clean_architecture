// Customer entity for Order VPC testing

class Customer {
  final String id;
  final String name;
  final String email;
  final String? phone;

  const Customer({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
  });

  Customer copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Customer && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Customer(id: $id, name: $name, email: $email)';
}
