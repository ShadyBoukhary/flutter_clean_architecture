// Customer repository interface for Order VPC

import '../entities/customer/customer.dart';

abstract class CustomerRepository {
  Future<Customer> get(String id);
  Future<List<Customer>> getAll();
}
