import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  final List<Map<String, dynamic>> _sections = [
    {
      'icon': Icons.info_outline,
      'title': 'Introduction',
      'content': 'Welcome to FantasyCrick. We are committed to protecting your privacy and ensuring you have a positive experience on our platform. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.',
      'expanded': true,
    },
    {
      'icon': Icons.storage,
      'title': 'Information We Collect',
      'content': 'We collect information you provide directly to us, such as:\n\n• Account Information (name, email, phone number)\n• Profile Data (avatar, preferences, game history)\n• Payment Information (processed securely via third-party processors)\n• Device Information (device type, OS, unique identifiers)\n• Usage Data (features used, time spent, interactions)',
      'expanded': false,
    },
    {
      'icon': Icons.settings,
      'title': 'How We Use Your Information',
      'content': 'We use the collected information to:\n\n• Provide and maintain our services\n• Process transactions and send related information\n• Send promotional communications (with your consent)\n• Analyze usage patterns to improve user experience\n• Detect, prevent, and address technical issues\n• Comply with legal obligations',
      'expanded': false,
    },
    {
      'icon': Icons.share,
      'title': 'Information Sharing',
      'content': 'We may share your information with:\n\n• Service providers who assist our operations\n• Business partners for joint promotions\n• Law enforcement when required by law\n• Other users (limited profile information for competitions)\n\nWe do NOT sell your personal information to third parties.',
      'expanded': false,
    },
    {
      'icon': Icons.security,
      'title': 'Data Security',
      'content': 'We implement appropriate security measures including:\n\n• SSL/TLS encryption for data transmission\n• Secure servers with access controls\n• Regular security audits and updates\n• Employee training on data protection\n\nHowever, no method of transmission over the Internet is 100% secure.',
      'expanded': false,
    },
    {
      'icon': Icons.cookie,
      'title': 'Cookies & Tracking',
      'content': 'We use cookies and similar tracking technologies to:\n\n• Remember your preferences\n• Analyze app performance\n• Personalize your experience\n• Deliver targeted advertisements\n\nYou can control cookies through your device settings.',
      'expanded': false,
    },
    {
      'icon': Icons.gavel,
      'title': 'Your Rights',
      'content': 'You have the right to:\n\n• Access your personal data\n• Correct inaccurate data\n• Delete your account and data\n• Opt-out of marketing communications\n• Export your data in a portable format\n• Lodge a complaint with data protection authorities',
      'expanded': false,
    },
    {
      'icon': Icons.child_care,
      'title': "Children's Privacy",
      'content': 'Our services are not intended for users under 18 years of age. We do not knowingly collect personal information from children. If we discover that a child under 18 has provided us with personal information, we will delete such information from our servers.',
      'expanded': false,
    },
    {
      'icon': Icons.update,
      'title': 'Policy Updates',
      'content': 'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date. You are advised to review this Privacy Policy periodically for any changes.',
      'expanded': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Privacy Policy', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
        actions: [
          IconButton(icon: const Icon(Icons.print), onPressed: () {}),
          IconButton(icon: const Icon(Icons.share), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildQuickActions(),
          const SizedBox(height: 20),
          ..._sections.asMap().entries.map((e) => _buildSection(e.key, e.value)),
          const SizedBox(height: 20),
          _buildContactSection(),
          const SizedBox(height: 16),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.privacy_tip, color: AppColors.white, size: 36),
          ),
          const SizedBox(height: 12),
          const Text('Your Privacy Matters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.white)),
          const SizedBox(height: 8),
          Text('Last updated: January 2025', style: TextStyle(color: AppColors.white.withOpacity(0.9), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(child: _buildQuickAction(Icons.download, 'Download PDF')),
        const SizedBox(width: 12),
        Expanded(child: _buildQuickAction(Icons.delete_outline, 'Delete Data')),
        const SizedBox(width: 12),
        Expanded(child: _buildQuickAction(Icons.help_outline, 'Help')),
      ],
    );
  }

  Widget _buildQuickAction(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildSection(int index, Map<String, dynamic> section) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: section['expanded'],
          onExpansionChanged: (expanded) => setState(() => section['expanded'] = expanded),
          leading: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(section['icon'], color: AppColors.primary, size: 20),
          ),
          title: Text(section['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(section['content'], style: const TextStyle(color: AppColors.textLight, height: 1.6)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Questions?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('If you have questions about this Privacy Policy, contact our Data Protection Officer:', style: TextStyle(color: AppColors.textLight)),
          const SizedBox(height: 16),
          _buildContactRow(Icons.email, 'privacy@fantasycrick.com'),
          _buildContactRow(Icons.location_on, 'Mumbai, India'),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(color: AppColors.textLight)),
      ]),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Text('By using FantasyCrick, you agree to this Privacy Policy.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textLight, fontSize: 12)),
        const SizedBox(height: 8),
        Text('© 2025 FantasyCrick. All rights reserved.', style: TextStyle(color: AppColors.textLight.withOpacity(0.7), fontSize: 11)),
      ],
    );
  }
}
