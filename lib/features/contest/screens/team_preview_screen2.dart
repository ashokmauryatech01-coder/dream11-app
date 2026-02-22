import 'package:flutter/material.dart';
import 'package:fantasy_crick/common/widgets/beauty_dialog.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';

class TeamPreviewScreen2 extends StatelessWidget {
  const TeamPreviewScreen2({super.key});

  @override
  Widget build(BuildContext context) {
    final contests = [
      {'name': 'Mega Contest', 'prize': '₹50 Lakhs', 'entry': '₹49'},
      {'name': 'Head to Head', 'prize': '₹1,000', 'entry': '₹25'},
      {'name': 'Winner Takes All', 'prize': '₹5,000', 'entry': '₹100'},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Team Preview 2', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPreviewCard(),
          const SizedBox(height: 16),
          const Text('Join Contest', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text)),
          const SizedBox(height: 10),
          ...contests.map((contest) => _buildContestTile(context, contest)),
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MI Super Kings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text('Captain: Rohit Sharma', style: TextStyle(color: AppColors.textLight)),
          Text('Vice Captain: MS Dhoni', style: TextStyle(color: AppColors.textLight)),
        ],
      ),
    );
  }

  Widget _buildContestTile(BuildContext context, Map<String, String> contest) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contest['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Prize: ${contest['prize']}', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                Text('Entry: ${contest['entry']}', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              BeautyDialog.show(
                context,
                title: 'Joined Contest',
                message: 'You joined ${contest['name']} successfully!',
                type: BeautyDialogType.success,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Join', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
