// Example Category entity for testing fca CLI multi-repo feature

class Category {
  final String id;
  final String name;
  final String? parentId;

  const Category({
    required this.id,
    required this.name,
    this.parentId,
  });

  Category copyWith({
    String? id,
    String? name,
    String? parentId,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Category(id: $id, name: $name)';
}
