import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';

class PlayerHistoryScreen extends StatelessWidget {
  const PlayerHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = [
      {'match': 'MI vs CSK', 'runs': 74, 'wickets': 0, 'points': 98},
      {'match': 'RCB vs KKR', 'runs': 55, 'wickets': 1, 'points': 84},
      {'match': 'RR vs RCB', 'runs': 102, 'wickets': 0, 'points': 132},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Player History', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: history.length,
        itemBuilder: (context, index) {
          final item = history[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['match'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('Runs: ${item['runs']} • Wickets: ${item['wickets']}', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                  ],
                ),
                Text('${item['points']} pts', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
          );
        },
      ),
    );
  }
}
