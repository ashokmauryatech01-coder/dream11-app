import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/features/contest/screens/create_new_team_screen.dart';
import 'package:fantasy_crick/features/contest/screens/team_preview_screen1.dart';

class MyTeamScreen extends StatefulWidget {
  const MyTeamScreen({super.key});

  @override
  State<MyTeamScreen> createState() => _MyTeamScreenState();
}

class _MyTeamScreenState extends State<MyTeamScreen> {
  String _selectedTab = 'all';

  final List<Map<String, dynamic>> _teams = [
    {
      'name': 'MI Super Kings',
      'match': 'MI vs CSK',
      'players': 11,
      'captain': 'Rohit Sharma',
      'viceCaptain': 'MS Dhoni',
      'credits': 100,
      'created': '2 hours ago',
      'contests': 3,
    },
    {
      'name': 'RCB Warriors',
      'match': 'RCB vs KKR',
      'players': 11,
      'captain': 'Virat Kohli',
      'viceCaptain': 'AB de Villiers',
      'credits': 99.5,
      'created': '1 day ago',
      'contests': 2,
    },
    {
      'name': 'DC Champions',
      'match': 'DC vs SRH',
      'players': 11,
      'captain': 'Rishabh Pant',
      'viceCaptain': 'David Warner',
      'credits': 98,
      'created': '2 days ago',
      'contests': 5,
    },
  ];

  final List<Map<String, String>> _tabs = const [
    {'id': 'all', 'name': 'All Teams'},
    {'id': 'cricket', 'name': 'Cricket'},
    {'id': 'football', 'name': 'Football'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Teams', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateNewTeamScreen()));
            },
            icon: const Icon(Icons.add, color: AppColors.primary),
            label: const Text('Create', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabs(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _teams.length,
              itemBuilder: (context, index) {
                final team = _teams[index];
                return _buildTeamCard(team);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _tabs.map((tab) {
            final bool selected = _selectedTab == tab['id'];
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = tab['id']!),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tab['name']!,
                    style: TextStyle(
                      color: selected ? AppColors.white : AppColors.textLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTeamCard(Map<String, dynamic> team) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(team['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(team['match'], style: const TextStyle(color: AppColors.textLight)),
                ],
              ),
              const Icon(Icons.more_vert, color: AppColors.textLight),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildInfoChip(Icons.people, '${team['players']} Players')),
              const SizedBox(width: 8),
              Expanded(child: _buildInfoChip(Icons.stars, '${team['captain']} (C)', iconColor: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildInfoChip(Icons.star, '${team['viceCaptain']} (VC)')),
              const SizedBox(width: 8),
              Expanded(child: _buildInfoChip(Icons.account_balance_wallet, '${team['credits']} Credits', iconColor: AppColors.success)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(team['created'], style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                  Text('${team['contests']} Contests', style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TeamPreviewScreen1()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Preview', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, {Color iconColor = AppColors.textLight}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.text))),
        ],
      ),
    );
  }
}
