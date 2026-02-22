import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';

class MyMatchesScreen1 extends StatelessWidget {
  const MyMatchesScreen1({super.key});

  @override
  Widget build(BuildContext context) {
    final matches = [
      {'team1': 'MI', 'team2': 'CSK', 'date': 'Today', 'time': '7:30 PM', 'venue': 'Wankhede Stadium', 'teams': 2, 'contests': 3},
      {'team1': 'RCB', 'team2': 'KKR', 'date': 'Tomorrow', 'time': '3:30 PM', 'venue': 'Chinnaswamy', 'teams': 1, 'contests': 2},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Matches 1', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: matches.length,
        itemBuilder: (context, index) {
          final match = matches[index];
          return _buildMatchCard(match);
        },
      ),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${match['team1']} vs ${match['team2']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(match['date'], style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text('${match['time']} • ${match['venue']}', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat('Teams', '${match['teams']}'),
              _buildStat('Contests', '${match['contests']}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
