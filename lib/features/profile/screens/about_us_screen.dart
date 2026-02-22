import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('About Us', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildMissionSection(),
          const SizedBox(height: 20),
          _buildFeaturesSection(),
          const SizedBox(height: 20),
          _buildStatsSection(),
          const SizedBox(height: 20),
          _buildTeamSection(),
          const SizedBox(height: 20),
          _buildContactSection(),
          const SizedBox(height: 20),
          _buildSocialSection(),
          const SizedBox(height: 16),
          _buildVersionInfo(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.sports_cricket, color: AppColors.primary, size: 48),
          ),
          const SizedBox(height: 16),
          const Text('FantasyCrick', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.white)),
          const SizedBox(height: 8),
          Text("India's #1 Fantasy Cricket Platform", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.white.withOpacity(0.9))),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: AppColors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: const Text('⭐ 4.8 Rating', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [Icon(Icons.flag, color: AppColors.primary), SizedBox(width: 10), Text('Our Mission', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 12),
          const Text('To create the most fair, fun, and transparent fantasy sports platform that brings cricket fans closer to the game they love. We believe every cricket enthusiast deserves a chance to showcase their cricketing knowledge.', style: TextStyle(color: AppColors.textLight, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection() {
    final features = [
      {'icon': Icons.verified_user, 'title': '100% Safe & Secure', 'desc': 'SSL encryption & RBI approved'},
      {'icon': Icons.speed, 'title': 'Instant Withdrawals', 'desc': 'Get winnings within 24 hours'},
      {'icon': Icons.support_agent, 'title': '24/7 Support', 'desc': 'Always here to help you'},
      {'icon': Icons.emoji_events, 'title': 'Daily Contests', 'desc': 'Win big every day'},
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Why Choose Us?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(f['icon'] as IconData, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(f['desc'] as String, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
              ])),
            ]),
          )),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final stats = [
      {'value': '10M+', 'label': 'Users'},
      {'value': '500+', 'label': 'Contests Daily'},
      {'value': '₹100Cr+', 'label': 'Won'},
      {'value': '4.8', 'label': 'Rating'},
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: stats.map((s) => Column(children: [
          Text(s['value']!, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 4),
          Text(s['label']!, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
        ])).toList(),
      ),
    );
  }

  Widget _buildTeamSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Our Team', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('We are a passionate team of cricket lovers and tech enthusiasts working to revolutionize how fans engage with the sport.', style: TextStyle(color: AppColors.textLight, height: 1.5)),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _buildTeamMember('🧑‍💼', 'CEO & Founder'),
            _buildTeamMember('👨‍💻', 'Tech Team'),
            _buildTeamMember('🎨', 'Design Team'),
          ]),
        ],
      ),
    );
  }

  Widget _buildTeamMember(String emoji, String role) {
    return Column(children: [
      Container(
        width: 60, height: 60,
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(30)),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
      ),
      const SizedBox(height: 8),
      Text(role, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
    ]);
  }

  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Contact Us', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildContactRow(Icons.email, 'support@fantasycrick.com'),
          _buildContactRow(Icons.phone, '+91 1800-123-4567'),
          _buildContactRow(Icons.location_on, 'Mumbai, India'),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(color: AppColors.textLight)),
      ]),
    );
  }

  Widget _buildSocialSection() {
    final socials = [
      {'icon': '📘', 'name': 'Facebook'},
      {'icon': '🐦', 'name': 'Twitter'},
      {'icon': '📸', 'name': 'Instagram'},
      {'icon': '▶️', 'name': 'YouTube'},
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Follow Us', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: socials.map((s) => Column(children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(25)),
                child: Center(child: Text(s['icon']!, style: const TextStyle(fontSize: 24))),
              ),
              const SizedBox(height: 6),
              Text(s['name']!, style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
            ])).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Center(
      child: Column(children: [
        const Text('Version 1.0.0', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
        const SizedBox(height: 4),
        Text('Made with ❤️ in India', style: TextStyle(color: AppColors.textLight.withOpacity(0.7), fontSize: 11)),
      ]),
    );
  }
}
