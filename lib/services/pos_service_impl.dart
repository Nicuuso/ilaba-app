import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:ilaba/models/pos_types.dart';
import 'package:ilaba/services/pos_service.dart';

/// Supabase implementation of POSService
class SupabasePOSService implements POSService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch all products from the products table
  /// Maps database columns: id, item_name, unit, unit_price
  @override
  Future<List<Product>> getProducts() async {
    try {
      final response = await _supabase
          .from('products')
          .select('id, item_name, unit, unit_price')
          .order('item_name');

      final products = (response as List)
          .map((product) => Product.fromJson(product))
          .toList();

      return products;
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  /// Fetch all laundry services (wash, dry, iron, etc.)
  @override
  Future<List<LaundryService>> getServices() async {
    try {
      final response = await _supabase
          .from('services')
          .select(
            'id, service_type, name, description, base_duration_minutes, rate_per_kg, is_active',
          )
          .eq('is_active', true)
          .order('service_type');

      final services = (response as List)
          .map((service) => LaundryService.fromJson(service))
          .toList();

      return services;
    } catch (e) {
      throw Exception('Failed to fetch services: $e');
    }
  }

  /// Search customers by name or phone
  @override
  Future<List<Customer>> searchCustomers(String query) async {
    try {
      final response = await _supabase
          .from('customers')
          .select()
          .or(
            'first_name.ilike.%$query%,last_name.ilike.%$query%,phone_number.eq.$query',
          );

      final customers = (response as List)
          .map((customer) => Customer.fromJson(customer))
          .toList();

      return customers;
    } catch (e) {
      throw Exception('Failed to search customers: $e');
    }
  }

  /// Save a complete order using the unified web API
  /// This matches the format expected by /api/pos/newOrder endpoint
  @override
  Future<String> saveOrder(Map<String, dynamic> orderData) async {
    try {
      debugPrint('=== Order Save Started ===');
      debugPrint('Order Data Keys: ${orderData.keys.toList()}');
      debugPrint('Has breakdown: ${orderData.containsKey('breakdown')}');
      debugPrint('Has handling: ${orderData.containsKey('handling')}');
      debugPrint('Full order data: $orderData');

      // DIRECT SUPABASE SAVE (bypass web API)
      // Insert directly into orders table with proper JSONB columns
      final response = await Supabase.instance.client.from('orders').insert([
        orderData,
      ]).select();

      debugPrint('Supabase Response: $response');

      if (response.isEmpty) {
        throw Exception('No response from Supabase');
      }

      final orderId = response[0]['id'] as String;
      debugPrint('✅ Order created successfully in Supabase! ID: $orderId');
      return orderId;
    } catch (e, stackTrace) {
      debugPrint('❌ Order Save Error: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Create a new customer
  @override
  Future<Customer> createCustomer(Customer customer) async {
    try {
      final response = await _supabase
          .from('customers')
          .insert({
            'first_name': customer.firstName,
            'last_name': customer.lastName,
            'phone_number': customer.phoneNumber,
            'email_address': customer.emailAddress,
            'address': customer.address,
          })
          .select()
          .single();

      return Customer.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create customer: $e');
    }
  }

  /// Update customer information
  @override
  Future<void> updateCustomer(Customer customer) async {
    try {
      await _supabase
          .from('customers')
          .update({
            'first_name': customer.firstName,
            'last_name': customer.lastName,
            'phone_number': customer.phoneNumber,
            'email_address': customer.emailAddress,
            'address': customer.address,
          })
          .eq('id', customer.id ?? '');
    } catch (e) {
      throw Exception('Failed to update customer: $e');
    }
  }
}
