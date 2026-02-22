import 'package:flutter/material.dart';
import 'package:fantasy_crick/common/widgets/beauty_dialog.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selectedLanguage = 'english';
  bool _autoDetect = false;
  bool _translateNames = true;
  bool _commentaryLanguage = true;

  final List<Map<String, String>> _languages = [
    {'id': 'english', 'name': 'English', 'nativeName': 'English', 'flag': '🇬🇧'},
    {'id': 'hindi', 'name': 'Hindi', 'nativeName': 'हिन्दी', 'flag': '🇮🇳'},
    {'id': 'bengali', 'name': 'Bengali', 'nativeName': 'বাংলা', 'flag': '🇧🇩'},
    {'id': 'tamil', 'name': 'Tamil', 'nativeName': 'தமிழ்', 'flag': '🇱🇰'},
    {'id': 'telugu', 'name': 'Telugu', 'nativeName': 'తెలుగు', 'flag': '🇮🇳'},
    {'id': 'marathi', 'name': 'Marathi', 'nativeName': 'मराठी', 'flag': '🇮🇳'},
    {'id': 'gujarati', 'name': 'Gujarati', 'nativeName': 'ગુજરાતી', 'flag': '🇮🇳'},
    {'id': 'kannada', 'name': 'Kannada', 'nativeName': 'ಕನ್ನಡ', 'flag': '🇮🇳'},
    {'id': 'malayalam', 'name': 'Malayalam', 'nativeName': 'മലയാളം', 'flag': '🇮🇳'},
    {'id': 'punjabi', 'name': 'Punjabi', 'nativeName': 'ਪੰਜਾਬੀ', 'flag': '🇮🇳'},
  ];

  Future<void> _saveLanguage() async {
    final lang = _languages.firstWhere((l) => l['id'] == _selectedLanguage);
    await BeautyDialog.show(context, title: 'Language Changed', message: 'App language has been changed to ${lang['name']}.', type: BeautyDialogType.success);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Language', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoSection(),
          const SizedBox(height: 20),
          _buildSectionTitle('Available Languages'),
          const SizedBox(height: 12),
          ..._languages.map((lang) => _buildLanguageCard(lang)),
          const SizedBox(height: 20),
          _buildSectionTitle('Language Settings'),
          const SizedBox(height: 12),
          _buildSettingsSection(),
          const SizedBox(height: 20),
          _buildHelpSection(),
          const SizedBox(height: 16),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text));
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.translate, color: AppColors.white, size: 48),
          const SizedBox(height: 12),
          const Text('Choose Your Language', style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Select your preferred language to enjoy the app in your native language.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.white.withOpacity(0.9))),
        ],
      ),
    );
  }

  Widget _buildLanguageCard(Map<String, String> lang) {
    final isSelected = _selectedLanguage == lang['id'];
    return GestureDetector(
      onTap: () => setState(() => _selectedLanguage = lang['id']!),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Text(lang['flag']!, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lang['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(lang['nativeName']!, style: const TextStyle(color: AppColors.textLight)),
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

  Widget _buildSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildSettingToggle(Icons.auto_awesome, 'Auto-detect Language', 'Automatically detect language based on device settings', _autoDetect, (v) => setState(() => _autoDetect = v)),
          const Divider(),
          _buildSettingToggle(Icons.translate, 'Translate Player Names', 'Show player names in selected language', _translateNames, (v) => setState(() => _translateNames = v)),
          const Divider(),
          _buildSettingToggle(Icons.comment, 'Commentary Language', 'Match commentary in preferred language', _commentaryLanguage, (v) => setState(() => _commentaryLanguage = v)),
        ],
      ),
    );
  }

  Widget _buildSettingToggle(IconData icon, String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(subtitle, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeTrackColor: AppColors.primary.withValues(alpha: 0.5), thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? AppColors.primary : null)),
        ],
      ),
    );
  }

  Widget _buildHelpSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Need Help?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildHelpItem(Icons.help, 'Language not available?'),
          _buildHelpItem(Icons.feedback, 'Report translation issues'),
          _buildHelpItem(Icons.volunteer_activism, 'Help us translate'),
        ],
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w500))),
          const Icon(Icons.chevron_right, color: AppColors.textLight),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveLanguage,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Save Changes', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
