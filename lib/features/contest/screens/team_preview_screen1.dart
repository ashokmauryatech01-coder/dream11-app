import 'package:flutter/material.dart';
import 'package:fantasy_crick/common/widgets/beauty_dialog.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';

class TeamPreviewScreen1 extends StatelessWidget {
  const TeamPreviewScreen1({super.key});

  @override
  Widget build(BuildContext context) {
    final players = [
      'Rohit Sharma',
      'Virat Kohli',
      'MS Dhoni',
      'Jasprit Bumrah',
      'Hardik Pandya',
      'Ravindra Jadeja',
      'KL Rahul',
      'David Warner',
      'Shubman Gill',
      'Rashid Khan',
      'Mohammed Shami',
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Team Preview 1', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildHeader(),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: players.length,
              itemBuilder: (context, index) {
                return _buildPlayerTile(players[index], index == 0, index == 1);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  BeautyDialog.show(
                    context,
                    title: 'Team Saved',
                    message: 'Your team has been saved successfully!',
                    type: BeautyDialogType.success,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Save Team', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Team Name', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('MI Super Kings', style: TextStyle(color: AppColors.textLight)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Credits', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
              Text('99.5', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerTile(String name, bool isCaptain, bool isVice) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(name.substring(0, 1), style: const TextStyle(color: AppColors.primary)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold))),
          if (isCaptain)
            _buildBadge('C')
          else if (isVice)
            _buildBadge('VC'),
        ],
      ),
    );
  }

  Widget _buildBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: const TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
