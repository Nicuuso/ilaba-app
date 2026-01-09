import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:ilaba/providers/auth_provider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _middleNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  DateTime? _selectedBirthdate;
  String? _selectedGender;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _middleNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _phoneNumberController = TextEditingController();
    _emailController = TextEditingController();
    _addressController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthdate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthdate ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)),
    );
    if (picked != null) {
      setState(() {
        _selectedBirthdate = picked;
      });
    }
  }

  Future<void> _handleSignup() async {
    // Validation
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _phoneNumberController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _selectedBirthdate == null ||
        _selectedGender == null ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showErrorSnackbar('Please fill in all required fields');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorSnackbar('Passwords do not match');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showErrorSnackbar('Password must be at least 6 characters');
      return;
    }

    debugPrint('📝 Attempting signup for: ${_emailController.text.trim()}');
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signup(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      middleName: _middleNameController.text.trim().isEmpty
          ? null
          : _middleNameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneNumberController.text.trim(),
      birthdate: _selectedBirthdate!,
      gender: _selectedGender!,
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      debugPrint('✅ Signup successful');
      Navigator.of(context).pushReplacementNamed('/home');
    } else if (mounted) {
      final errorMsg =
          authProvider.errorMessage ?? 'Signup failed. Please try again.';
      debugPrint('❌ Signup failed: $errorMsg');
      _showErrorSnackbar(errorMsg);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'Create Account',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Join iLaba for easy laundry booking',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // First Name
              TextField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: 'First Name *',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Middle Name
              TextField(
                controller: _middleNameController,
                decoration: InputDecoration(
                  labelText: 'Middle Name (Optional)',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Last Name
              TextField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: 'Last Name *',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Birthdate
              GestureDetector(
                onTap: () => _selectBirthdate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Birthdate *',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _selectedBirthdate == null
                        ? 'Select your birthdate'
                        : '${_selectedBirthdate!.year}-${_selectedBirthdate!.month.toString().padLeft(2, '0')}-${_selectedBirthdate!.day.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: _selectedBirthdate == null
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Gender
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Gender *',
                  prefixIcon: const Icon(Icons.wc),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: DropdownButton<String>(
                  value: _selectedGender,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  hint: const Text('Select gender'),
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('Male')),
                    DropdownMenuItem(value: 'female', child: Text('Female')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Phone Number
              TextField(
                controller: _phoneNumberController,
                decoration: InputDecoration(
                  labelText: 'Phone Number *',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Email Address
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address *',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Address
              TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address (Optional)',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
                keyboardType: TextInputType.streetAddress,
              ),
              const SizedBox(height: 16),

              // Password
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password *',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _passwordVisible = !_passwordVisible;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                obscureText: !_passwordVisible,
              ),
              const SizedBox(height: 16),

              // Confirm Password
              TextField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm Password *',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _confirmPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _confirmPasswordVisible = !_confirmPasswordVisible;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                obscureText: !_confirmPasswordVisible,
              ),
              const SizedBox(height: 8),
              Text(
                'Must be at least 6 characters',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              // Sign Up Button
              Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  return ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _handleSignup,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: authProvider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign Up'),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Back to Login Button
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Return to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
