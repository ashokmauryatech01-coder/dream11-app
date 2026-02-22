import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';

class PlayerPerformanceScreen extends StatelessWidget {
  const PlayerPerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = [
      {'label': 'Runs', 'value': '345'},
      {'label': 'Wickets', 'value': '12'},
      {'label': 'Fantasy Pts', 'value': '512'},
      {'label': 'Avg Pts', 'value': '64'},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Player Performance', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.person, color: AppColors.white),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hardik Pandya', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('All Rounder', style: TextStyle(color: AppColors.textLight)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: stats.map((stat) {
                return SizedBox(
                  width: 150,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stat['value']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
                      Text(stat['label']!, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Performance Notes', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('• Consistent scorer in last 5 matches'),
                Text('• High strike rate in powerplay'),
                Text('• Bowling economy improved this season'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
