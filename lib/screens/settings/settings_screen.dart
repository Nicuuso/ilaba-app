import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ilaba/providers/settings_provider.dart';
import 'package:ilaba/constants/ilaba_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Accessibility Settings',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: ILabaColors.darkText,
          ),
        ),
        backgroundColor: ILabaColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: ILabaColors.burgundy),
        centerTitle: false,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Header
                Text(
                  'Accessibility',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: ILabaColors.darkText,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Customize your experience with accessibility features',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ILabaColors.lightText,
                      ),
                ),
                const SizedBox(height: 24),

                // Text Size Setting
                _buildSettingCard(
                  context: context,
                  icon: Icons.text_fields,
                  title: 'Text Size',
                  subtitle: 'Adjust text size globally',
                  child: _buildTextSizeSelector(context, settingsProvider),
                ),
                const SizedBox(height: 16),

                // High Contrast Text Toggle
                _buildSettingCard(
                  context: context,
                  icon: Icons.contrast,
                  title: 'High Contrast Text',
                  subtitle: 'Increases text visibility',
                  child: _buildHighContrastToggle(context, settingsProvider),
                ),
                const SizedBox(height: 32),

                // Preview Section
                _buildPreviewSection(context, settingsProvider),
                const SizedBox(height: 32),

                // Reset Button
                _buildResetButton(context, settingsProvider),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: ILabaColors.darkText.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ILabaColors.lightText,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildTextSizeSelector(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<TextSizeMode>(
        value: settingsProvider.textSizeMode,
        onChanged: (TextSizeMode? newSize) {
          if (newSize != null) {
            settingsProvider.setTextSize(newSize);
          }
        },
        isExpanded: true,
        underline: const SizedBox(),
        items: [
          DropdownMenuItem(
            value: TextSizeMode.small,
            child: Text(
              'Small (85%)',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          DropdownMenuItem(
            value: TextSizeMode.default_,
            child: Text(
              'Default (100%)',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          DropdownMenuItem(
            value: TextSizeMode.large,
            child: Text(
              'Large (120%)',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighContrastToggle(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                settingsProvider.highContrastText ? 'Enabled' : 'Disabled',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: settingsProvider.highContrastText
                      ? Colors.green.shade600
                      : ILabaColors.lightText,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (settingsProvider.highContrastText)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Bold text with higher contrast',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.green.shade600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Switch.adaptive(
          value: settingsProvider.highContrastText,
          onChanged: (value) {
            settingsProvider.toggleHighContrastText(value);
          },
          activeColor: Colors.green,
        ),
      ],
    );
  }

  Widget _buildPreviewSection(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.preview,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Live Preview',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Main heading text appearance',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'This is body text - shows your current settings applied',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Small subtitle or caption text',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Reset Settings'),
              content: const Text(
                'Are you sure you want to reset all accessibility settings to default?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    settingsProvider.resetToDefaults();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Settings reset to default'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Text(
                    'Reset',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade200,
          foregroundColor: ILabaColors.darkText,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        icon: const Icon(Icons.refresh),
        label: const Text(
          'Reset to Default',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
