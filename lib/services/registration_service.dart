import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

abstract class RegistrationService {
  Future<Map<String, dynamic>> registerCustomer({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String birthdate,
    required String gender,
    String? middleName,
    String? address,
  });
}

class RegistrationServiceImpl implements RegistrationService {
  static const String baseUrl = 'https://katflix-ilaba.vercel.app';
  static const String endpoint = '/api/customer/saveCustomer';

  @override
  Future<Map<String, dynamic>> registerCustomer({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String birthdate,
    required String gender,
    String? middleName,
    String? address,
  }) async {
    try {
      debugPrint('📝 Registering customer: $email');

      final payload = {
        'first_name': firstName,
        'last_name': lastName,
        'email_address': email,
        'phone_number': phoneNumber,
        'birthdate': birthdate,
        'gender': gender,
        if (middleName != null && middleName.isNotEmpty)
          'middle_name': middleName,
        if (address != null && address.isNotEmpty) 'address': address,
      };

      debugPrint('📤 Payload: ${jsonEncode(payload)}');

      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Registration request timed out'),
          );

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;

        if (jsonResponse['success'] == true) {
          debugPrint('✅ Registration successful');
          return jsonResponse;
        } else {
          final errorMsg = jsonResponse['error'] ?? 'Registration failed';
          debugPrint('❌ Registration error: $errorMsg');
          throw Exception(errorMsg);
        }
      } else {
        final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMsg =
            errorBody['error'] ??
            'Registration failed with status ${response.statusCode}';
        debugPrint('❌ HTTP error: $errorMsg');
        throw Exception(errorMsg);
      }
    } on http.ClientException catch (e) {
      debugPrint('❌ HTTP Client error: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      debugPrint('❌ Registration error: ${e.runtimeType} - $e');
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring(10);
      }
      throw Exception(errorMsg);
    }
  }
}
