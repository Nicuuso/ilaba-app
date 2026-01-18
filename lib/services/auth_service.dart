import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ilaba/models/user.dart' as models;
import 'package:flutter/foundation.dart';

abstract class AuthService {
  Future<models.User> login(String email, String password);
  Future<models.User> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required DateTime birthdate,
    required String gender,
    String? middleName,
    String? address,
    required String password,
  });
  Future<void> logout();
  Future<models.User?> getCurrentUser();
  Future<void> resetPassword(String email);
  Future<bool> isLoggedIn();
}

class AuthServiceImpl implements AuthService {
  final SupabaseClient supabaseClient;

  AuthServiceImpl({required this.supabaseClient});

  @override
  Future<models.User> login(String email, String password) async {
    try {
      debugPrint('🔐 Login attempt: $email');

      final response = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final authUser = response.user;
      if (authUser == null) {
        debugPrint('❌ No user returned from auth');
        throw Exception('Login failed: No user returned from authentication');
      }

      debugPrint('✅ Auth successful, fetching customer profile...');

      // Fetch user profile from customers table
      final userData = await supabaseClient
          .from('customers')
          .select()
          .eq('auth_id', authUser.id)
          .single();

      debugPrint('✅ Customer profile fetched successfully');
      return models.User.fromJson(userData);
    } on AuthException catch (e) {
      // Handle Supabase-specific auth errors
      debugPrint('❌ AuthException: ${e.statusCode} - ${e.message}');

      if (e.statusCode == '400') {
        throw Exception('Invalid email or password');
      } else if (e.statusCode == '401') {
        throw Exception('Invalid email or password');
      } else if (e.statusCode == '422') {
        throw Exception('Email not confirmed. Please check your email');
      }
      throw Exception(e.message);
    } catch (e) {
      debugPrint('❌ Login error: ${e.runtimeType} - $e');

      if (e.toString().contains('no rows returned')) {
        throw Exception('User profile not found. Please contact support');
      }

      // Extract just the message part, removing "Exception: " prefix
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring(10);
      }

      // Provide helpful message for common errors
      if (errorMsg.contains('Invalid login credentials')) {
        throw Exception('Invalid email or password');
      } else if (errorMsg.contains('User not found')) {
        throw Exception('No account found with this email');
      }

      throw Exception(errorMsg);
    }
  }

  @override
  Future<models.User> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required DateTime birthdate,
    required String gender,
    String? middleName,
    String? address,
    required String password,
  }) async {
    try {
      debugPrint('📝 Signup: Creating auth for $email');

      // Create auth account
      final response = await supabaseClient.auth.signUp(
        email: email,
        password: password,
      );

      final authUser = response.user;
      if (authUser == null) {
        throw Exception('Signup failed: No user returned from authentication');
      }

      debugPrint('✅ Auth created, storing customer profile...');

      // Create user profile in customers table
      final user = models.User(
        id: authUser.id,
        authId: authUser.id,
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        birthdate: birthdate,
        gender: gender,
        emailAddress: email,
        phoneNumber: phoneNumber,
        address: address,
        loyaltyPoints: 0, // Initialize new customers with 0 loyalty points
        createdAt: DateTime.now(),
      );

      await supabaseClient.from('customers').insert(user.toJson());

      debugPrint('✅ Signup complete');
      return user;
    } on AuthException catch (e) {
      debugPrint(
        '❌ AuthException during signup: ${e.statusCode} - ${e.message}',
      );

      if (e.statusCode == '400' &&
          (e.message.contains('already registered') ||
              e.message.contains('already exists'))) {
        throw Exception(
          'Email address already registered. Please login or use a different email',
        );
      } else if (e.statusCode == '422') {
        throw Exception('Email is invalid. Please check and try again');
      }
      throw Exception(e.message);
    } catch (e) {
      debugPrint('❌ Signup error: ${e.runtimeType} - $e');

      if (e.toString().contains('duplicate')) {
        throw Exception(
          'Email address already registered. Please login or use a different email',
        );
      }

      // Extract clean error message
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring(10);
      }
      throw Exception(errorMsg);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await supabaseClient.auth.signOut();
    } catch (e) {
      throw Exception('Logout failed: ${e.toString()}');
    }
  }

  @override
  Future<models.User?> getCurrentUser() async {
    try {
      final authUser = supabaseClient.auth.currentUser;
      if (authUser == null) {
        return null;
      }

      final userData = await supabaseClient
          .from('customers')
          .select()
          .eq('auth_id', authUser.id)
          .single();

      return models.User.fromJson(userData);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      debugPrint('🔑 Password reset request for: $email');
      await supabaseClient.auth.resetPasswordForEmail(email);
      debugPrint('✅ Password reset email sent');
    } on AuthException catch (e) {
      debugPrint(
        '❌ AuthException during reset: ${e.statusCode} - ${e.message}',
      );

      if (e.statusCode == '422' || e.statusCode == '400') {
        throw Exception('No account found with this email address');
      }
      throw Exception(e.message);
    } catch (e) {
      debugPrint('❌ Password reset error: ${e.runtimeType} - $e');

      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring(10);
      }
      throw Exception(errorMsg);
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    return supabaseClient.auth.currentUser != null;
  }
}
