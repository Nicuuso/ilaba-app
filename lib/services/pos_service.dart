import 'package:ilaba/models/pos_types.dart';

/// Extended POS-specific service methods
abstract class POSService {
  /// Products
  Future<List<Product>> getProducts();

  /// Services (wash, dry, etc.)
  Future<List<LaundryService>> getServices();

  /// Customer search
  Future<List<Customer>> searchCustomers(String query);

  /// Save a complete order
  Future<String> saveOrder(Map<String, dynamic> orderData);

  /// Create new customer
  Future<Customer> createCustomer(Customer customer);

  /// Update customer
  Future<void> updateCustomer(Customer customer);
}

class POSServiceImpl implements POSService {
  // TODO: Implement with actual API calls to Supabase
  // This service handles all POS-related operations

  @override
  Future<List<Product>> getProducts() async {
    throw UnimplementedError('getProducts() not implemented');
  }

  @override
  Future<List<LaundryService>> getServices() async {
    throw UnimplementedError('getServices() not implemented');
  }

  @override
  Future<List<Customer>> searchCustomers(String query) async {
    throw UnimplementedError('searchCustomers() not implemented');
  }

  @override
  Future<String> saveOrder(Map<String, dynamic> orderData) async {
    throw UnimplementedError('saveOrder() not implemented');
  }

  @override
  Future<Customer> createCustomer(Customer customer) async {
    throw UnimplementedError('createCustomer() not implemented');
  }

  @override
  Future<void> updateCustomer(Customer customer) async {
    throw UnimplementedError('updateCustomer() not implemented');
  }
}
