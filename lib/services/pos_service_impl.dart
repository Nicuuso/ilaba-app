import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'dart:io';
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
      // Get API base URL from environment
      String? apiBaseUrl = dotenv.env['API_BASE_URL'];

      // Validate API URL is configured
      if (apiBaseUrl == null || apiBaseUrl.isEmpty) {
        debugPrint('❌ API_BASE_URL not configured in .env file');
        throw Exception(
          'API configuration error: API_BASE_URL is not set in .env file.\n\n'
          'Please add to your .env file:\n'
          'API_BASE_URL=http://localhost:3000\n'
          '(or your actual web app URL)',
        );
      }

      final apiUrl = '$apiBaseUrl/api/pos/newOrder';
      debugPrint('=== Order Save Started ===');
      debugPrint('API URL: $apiUrl');
      debugPrint('Order Data: ${orderData.toString()}');

      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization':
                  'Bearer ${Supabase.instance.client.auth.currentSession?.accessToken ?? ''}',
            },
            body: jsonEncode(orderData),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timeout - API took too long to respond');
            },
          );

      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final orderId = result['orderId'] ?? result['id'] ?? '';
        if (orderId.isEmpty) {
          throw Exception('No order ID returned from API');
        }
        debugPrint('✅ Order created successfully! ID: $orderId');
        return orderId;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        throw Exception('Bad Request: ${error['error'] ?? response.body}');
      } else if (response.statusCode == 500) {
        final error = jsonDecode(response.body);
        throw Exception('Server Error: ${error['error'] ?? response.body}');
      } else {
        throw Exception(
          'Failed to save order (${response.statusCode}): ${response.body}',
        );
      }
    } on SocketException catch (e) {
      debugPrint('❌ Network Error: $e');
      throw Exception('Network error - Check your internet connection: $e');
    } catch (e) {
      debugPrint('❌ Order Save Error: $e');
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
