import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
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
              'Introduction',
              'iLaba ("we" or "us" or "our") operates the iLaba mobile application (the "Service"). This page informs you of our policies regarding the collection, use, and disclosure of personal data when you use our Service and the choices you have associated with that data.',
            ),
            _buildSection(
              context,
              'Information Collection and Use',
              'We collect several different types of information for various purposes to provide and improve our Service to you.\n\nTypes of Data Collected:\n• Personal Data: While using our Service, we may ask you to provide us with certain personally identifiable information that can be used to contact or identify you ("Personal Data"). This may include:\n  - Email address\n  - First name and last name\n  - Phone number\n  - Address\n  - Date of birth\n  - Gender\n  - Cookies and usage data',
            ),
            _buildSection(
              context,
              'Use of Data',
              'iLaba uses the collected data for various purposes:\n\n• To provide and maintain our Service\n• To notify you about changes to our Service\n• To allow you to participate in interactive features of our Service when you choose to do so\n• To provide customer care and support\n• To gather analysis or valuable information so that we can improve our Service\n• To monitor the usage of our Service\n• To detect, prevent and address technical issues',
            ),
            _buildSection(
              context,
              'Security of Data',
              'The security of your data is important to us, but remember that no method of transmission over the Internet or method of electronic storage is 100% secure. While we strive to use commercially acceptable means to protect your Personal Data, we cannot guarantee its absolute security.',
            ),
            _buildSection(
              context,
              'Service Providers',
              'We may employ third party companies and individuals to facilitate our Service ("Service Providers"), to provide the Service on our behalf, to perform Service-related services or to assist us in analyzing how our Service is used.',
            ),
            _buildSection(
              context,
              'Links to Other Sites',
              'Our Service may contain links to other sites that are not operated by us. If you click on a third party link, you will be directed to that third party\'s site. We strongly advise you to review the Privacy Policy of every site you visit. We have no control over and assume no responsibility for the content, privacy policies or practices of any third party sites or services.',
            ),
            _buildSection(
              context,
              'Changes to This Privacy Policy',
              'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last updated" date at the top of this Privacy Policy. You are advised to review this Privacy Policy periodically for any changes.',
            ),
            _buildSection(
              context,
              'Contact Us',
              'If you have any questions about this Privacy Policy, please contact us:\n\nBy email: support@ilaba.com\nBy visiting this page on our website: www.ilaba.com/contact',
            ),
            _buildSection(
              context,
              'Data Retention',
              'We will retain your Personal Data only for as long as necessary for the purposes set out in this Privacy Policy. We will retain and use your Personal Data to the extent necessary to comply with our legal obligations.',
            ),
            _buildSection(
              context,
              'Your Rights',
              'Depending on your location, you may have the following rights:\n\n• Right to Access: You have the right to access the personal data we hold about you\n• Right to Correction: You have the right to request that we correct inaccurate data\n• Right to Deletion: You have the right to request erasure of your data\n• Right to Restrict Processing: You have the right to request that we restrict processing of your data',
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
