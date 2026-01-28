import 'package:flutter/material.dart';
import 'package:ilaba/models/user.dart' as user_model;
import 'package:ilaba/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService authService;

  user_model.User? _currentUser;
  bool _isLoading = true; // Start as true for initial load
  String? _errorMessage;
  bool _initializationComplete = false;

  AuthProvider({required this.authService}) {
    _initializeAuth();
  }

  // Getters
  user_model.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;
  bool get initializationComplete => _initializationComplete;

  // Initialize auth on app start
  Future<void> _initializeAuth() async {
    try {
      _isLoading = true;
      final user = await authService.getCurrentUser();
      _currentUser = user;
      _isLoading = false;
      _initializationComplete = true;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      _initializationComplete = true;
      notifyListeners();
    }
  }

  // Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await authService.login(email, password);
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // Extract clean error message, removing Exception: prefix
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring(10);
      }
      _errorMessage = errorMsg;
      // Set loading to false BEFORE notifying so UI removes loading immediately
      _isLoading = false;
      // Add a small delay to ensure the loading state is fully removed before showing snackbar
      await Future.delayed(const Duration(milliseconds: 50));
      notifyListeners();
      return false;
    }
  }

  // Signup
  Future<bool> signup({
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await authService.signup(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phoneNumber: phoneNumber,
        birthdate: birthdate,
        gender: gender,
        middleName: middleName,
        address: address,
        password: password,
      );
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring(10);
      }
      _errorMessage = errorMsg;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await authService.logout();
      _currentUser = null;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring(10);
      }
      _errorMessage = errorMsg;
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring(10);
      }
      _errorMessage = errorMsg;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Refresh user data (including loyalty points after order creation)
  Future<void> refreshUser() async {
    try {
      debugPrint('🔄 AuthProvider: Refreshing user data...');
      final user = await authService.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        debugPrint(
          '✅ AuthProvider: User data refreshed - Loyalty points: ${user.loyaltyPoints}',
        );
        notifyListeners();
      } else {
        debugPrint('⚠️ AuthProvider: Could not refresh user - returned null');
      }
    } catch (e) {
      debugPrint('❌ AuthProvider: Error refreshing user: $e');
      _errorMessage = e.toString();
    }
  }
}
