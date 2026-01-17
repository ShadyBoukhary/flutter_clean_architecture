// Category repository interface for testing fca CLI multi-repo feature

import '../entities/category/category.dart';

abstract class CategoryRepository {
  Future<Category> get(String id);
  Future<List<Category>> getAll();
  Future<List<Category>> getByParent(String? parentId);
}
