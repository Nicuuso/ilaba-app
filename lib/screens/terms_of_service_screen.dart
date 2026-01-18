import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms of Service',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: January 18, 2026',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '1. Acceptance of Terms',
              'By accessing and using the iLaba mobile application ("Service"), you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.',
            ),
            _buildSection(
              context,
              '2. Use License',
              'Permission is granted to temporarily download one copy of the materials (information or software) on iLaba\'s Service for personal, non-commercial transitory viewing only. This is the grant of a license, not a transfer of title, and under this license you may not:\n\n• Modify or copy the materials\n• Use the materials for any commercial purpose or for any public display\n• Attempt to decompile or reverse engineer any software contained on the Service\n• Remove any copyright or other proprietary notations from the materials\n• Transfer the materials to another person or "mirror" the materials on any other server',
            ),
            _buildSection(
              context,
              '3. Disclaimer',
              'The materials on iLaba\'s Service are provided on an \'as is\' basis. iLaba makes no warranties, expressed or implied, and hereby disclaims and negates all other warranties including, without limitation, implied warranties or conditions of merchantability, fitness for a particular purpose, or non-infringement of intellectual property or other violation of rights.',
            ),
            _buildSection(
              context,
              '4. Limitations',
              'In no event shall iLaba or its suppliers be liable for any damages (including, without limitation, damages for loss of data or profit, or due to business interruption) arising out of the use or inability to use the materials on iLaba\'s Service, even if iLaba or an authorized representative has been notified orally or in writing of the possibility of such damage.',
            ),
            _buildSection(
              context,
              '5. Accuracy of Materials',
              'The materials appearing on iLaba\'s Service could include technical, typographical, or photographic errors. iLaba does not warrant that any of the materials on its Service are accurate, complete, or current. iLaba may make changes to the materials contained on its Service at any time without notice.',
            ),
            _buildSection(
              context,
              '6. Links',
              'iLaba has not reviewed all of the sites linked to its Service and is not responsible for the contents of any such linked site. The inclusion of any link does not imply endorsement by iLaba of the site. Use of any such linked website is at the user\'s own risk.',
            ),
            _buildSection(
              context,
              '7. Modifications',
              'iLaba may revise these terms of service for its Service at any time without notice. By using this Service, you are agreeing to be bound by the then current version of these terms of service.',
            ),
            _buildSection(
              context,
              '8. Governing Law',
              'These terms and conditions are governed by and construed in accordance with the laws of the jurisdiction where iLaba operates, and you irrevocably submit to the exclusive jurisdiction of the courts in that location.',
            ),
            _buildSection(
              context,
              '9. Contact Information',
              'If you have any questions about these Terms of Service, please contact us at support@ilaba.com.',
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
