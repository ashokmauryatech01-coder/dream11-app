import 'package:flutter/material.dart';
import 'package:fantasy_crick/common/widgets/beauty_dialog.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  String _selectedIssue = '';

  final List<Map<String, dynamic>> _issueTypes = [
    {'id': 'payment', 'name': 'Payment Related', 'icon': Icons.payments, 'description': 'Issues with deposits, withdrawals, transactions'},
    {'id': 'team', 'name': 'Team Issues', 'icon': Icons.people, 'description': 'Team creation, editing, captain selection'},
    {'id': 'contest', 'name': 'Contest Problems', 'icon': Icons.emoji_events, 'description': 'Contest joining, winnings, rankings'},
    {'id': 'technical', 'name': 'Technical Issues', 'icon': Icons.bug_report, 'description': 'App crashes, bugs, performance'},
    {'id': 'account', 'name': 'Account Issues', 'icon': Icons.account_circle, 'description': 'Login, profile, security concerns'},
    {'id': 'other', 'name': 'Other', 'icon': Icons.more_horiz, 'description': 'Any other issues or suggestions'},
  ];

  final List<Map<String, dynamic>> _quickActions = [
    {'id': 'faq', 'name': 'Browse FAQs', 'icon': Icons.help},
    {'id': 'chat', 'name': 'Live Chat', 'icon': Icons.chat},
    {'id': 'call', 'name': 'Call Support', 'icon': Icons.call},
    {'id': 'email', 'name': 'Email Support', 'icon': Icons.email},
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedIssue.isEmpty || _subjectController.text.isEmpty || _messageController.text.isEmpty) {
      await BeautyDialog.show(context, title: 'Incomplete', message: 'Please fill all fields before submitting.', type: BeautyDialogType.warning);
      return;
    }
    await BeautyDialog.show(context, title: 'Ticket Submitted', message: 'Your support ticket has been submitted. We will respond within 24 hours.', type: BeautyDialogType.success);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Support', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
        actions: [IconButton(icon: const Icon(Icons.history), onPressed: () {})],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildQuickActions(),
          const SizedBox(height: 20),
          _buildSectionTitle('Create Support Ticket'),
          const SizedBox(height: 12),
          _buildIssueTypeSelector(),
          const SizedBox(height: 16),
          _buildTextField('Subject', 'Brief description of your issue', _subjectController),
          _buildTextField('Message', 'Describe your issue in detail...', _messageController, maxLines: 5),
          const SizedBox(height: 16),
          _buildSubmitButton(),
          const SizedBox(height: 20),
          _buildContactInfo(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text));
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _quickActions.map((action) => _buildQuickActionItem(action)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem(Map<String, dynamic> action) {
    return GestureDetector(
      onTap: () => _handleQuickAction(action['id'] as String),
      child: Column(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(28)),
            child: Icon(action['icon'] as IconData, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(action['name'] as String, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
        ],
      ),
    );
  }

  void _handleQuickAction(String actionId) {
    switch (actionId) {
      case 'faq':
        Navigator.pop(context);
        break;
      case 'chat':
        BeautyDialog.show(context, title: 'Live Chat', message: 'Chat feature coming soon!', type: BeautyDialogType.info);
        break;
      case 'call':
        BeautyDialog.show(context, title: 'Call Support', message: 'Dial: +91-XXXXXXXXXX\nAvailable 24/7', type: BeautyDialogType.info);
        break;
      case 'email':
        BeautyDialog.show(context, title: 'Email Support', message: 'support@fantasycrick.com', type: BeautyDialogType.info);
        break;
    }
  }

  Widget _buildIssueTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Issue Type', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.text)),
        const SizedBox(height: 12),
        ..._issueTypes.map((issue) => _buildIssueTypeCard(issue)),
      ],
    );
  }

  Widget _buildIssueTypeCard(Map<String, dynamic> issue) {
    final isSelected = _selectedIssue == issue['id'];
    return GestureDetector(
      onTap: () => setState(() => _selectedIssue = issue['id'] as String),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(22)),
              child: Icon(issue['icon'] as IconData, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(issue['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(issue['description'] as String, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                ],
              ),
            ),
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: 2),
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
              child: isSelected ? const Icon(Icons.check, color: AppColors.white, size: 16) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, {int maxLines = 1}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.text)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: AppColors.textLight), border: InputBorder.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Icon(Icons.send, color: AppColors.white), SizedBox(width: 8), Text('Submit Ticket', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 16))],
        ),
      ),
    );
  }

  Widget _buildContactInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Contact Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildContactItem(Icons.email, 'Email', 'support@fantasycrick.com'),
          _buildContactItem(Icons.phone, 'Phone', '+91-XXXXXXXXXX'),
          _buildContactItem(Icons.access_time, 'Working Hours', '24/7 Support Available'),
          _buildContactItem(Icons.location_on, 'Address', 'Mumbai, Maharashtra, India'),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
