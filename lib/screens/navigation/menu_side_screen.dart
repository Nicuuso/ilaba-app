import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ilaba/providers/auth_provider.dart';
import 'package:ilaba/screens/settings/settings_screen.dart';
import 'package:ilaba/screens/account/account_center_screen.dart';
import 'package:ilaba/constants/ilaba_colors.dart';

class MenuSideScreen extends StatelessWidget {
  const MenuSideScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Perform logout
      await authProvider.logout();

      // Navigate to login screen and remove all previous routes
      if (context.mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header - Updated to use burgundy color
          DrawerHeader(
            decoration: const BoxDecoration(
              color: ILabaColors.burgundy,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: ILabaColors.white,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: ILabaColors.burgundy,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  "Welcome, User!",
                  style: TextStyle(
                    color: ILabaColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Navigation items
          ListTile(
            leading: const Icon(Icons.account_circle, color: ILabaColors.burgundy),
            title: const Text("Account Center"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AccountCenterScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: ILabaColors.burgundy),
            title: const Text("Settings"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Log out"),
            textColor: Colors.red,
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }
}
