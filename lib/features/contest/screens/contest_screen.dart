import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/features/contest/screens/create_new_team_screen.dart';
import 'package:fantasy_crick/common/widgets/beauty_dialog.dart';

class ContestScreen extends StatefulWidget {
  final String? contestId;

  const ContestScreen({super.key, this.contestId});

  @override
  State<ContestScreen> createState() => _ContestScreenState();
}

class _ContestScreenState extends State<ContestScreen> {
  String _selectedTab = 'all';

  final List<Map<String, String>> _tabs = [
    {'id': 'all', 'name': 'All Contests'},
    {'id': 'mega', 'name': 'Mega'},
    {'id': 'h2h', 'name': 'Head to Head'},
    {'id': 'small', 'name': 'Small League'},
  ];

  final List<Map<String, dynamic>> _contests = [
    {
      'id': 1,
      'name': 'Mega Contest',
      'prize': '50 Lakhs',
      'entries': '1,23,456',
      'maxEntries': '2,00,000',
      'entryFee': '49',
      'type': 'mega',
      'winnerPercentage': '50%',
    },
    {
      'id': 2,
      'name': 'Head to Head',
      'prize': '1,000',
      'entries': '2',
      'maxEntries': '2',
      'entryFee': '25',
      'type': 'h2h',
      'winnerPercentage': '100%',
    },
    {
      'id': 3,
      'name': 'Winner Takes All',
      'prize': '5,000',
      'entries': '10',
      'maxEntries': '10',
      'entryFee': '100',
      'type': 'small',
      'winnerPercentage': '100%',
    },
    {
      'id': 4,
      'name': 'Small League',
      'prize': '10,000',
      'entries': '45',
      'maxEntries': '50',
      'entryFee': '75',
      'type': 'small',
      'winnerPercentage': '60%',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredContests = _selectedTab == 'all'
        ? _contests
        : _contests.where((c) => c['type'] == _selectedTab).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Contests', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabContainer(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: filteredContests.length,
              itemBuilder: (context, index) {
                return _buildContestCard(filteredContests[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContainer() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _tabs.map((tab) {
             final isSelected = _selectedTab == tab['id'];
             return Padding(
               padding: const EdgeInsets.only(right: 10),
               child: GestureDetector(
                 onTap: () => setState(() => _selectedTab = tab['id']!),
                 child: Container(
                   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                   decoration: BoxDecoration(
                     color: isSelected ? AppColors.primary : AppColors.background,
                     borderRadius: BorderRadius.circular(20),
                   ),
                   child: Text(
                     tab['name']!,
                     style: TextStyle(
                       color: isSelected ? AppColors.white : AppColors.textLight,
                       fontWeight: FontWeight.bold,
                       fontSize: 14,
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

  Widget _buildContestCard(Map<String, dynamic> contest) {
    // Check for entries as string with commas
    final entriesStr = contest['entries'] as String;
    final maxEntriesStr = contest['maxEntries'] as String;
    
    // Simple progress calculation (rough)
    double progress = 0.5; // Default dummy
    try {
      final entries = int.parse(entriesStr.replaceAll(',', ''));
      final maxEntries = int.parse(maxEntriesStr.replaceAll(',', ''));
      if (maxEntries > 0) progress = entries / maxEntries;
    } catch (e) {
      // Ignore parse errors
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contest['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('Prize Pool: ₹${contest['prize']}', style: const TextStyle(color: AppColors.success, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$entriesStr/$maxEntriesStr', style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                  const SizedBox(height: 4),
                  Container(
                    width: 60,
                    height: 4,
                    decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(color: AppColors.success),
                    ),
                  )
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDetailItem(Icons.emoji_events, '${contest['winnerPercentage']} Win', AppColors.success),
              _buildDetailItem(Icons.people, '$entriesStr Spots', AppColors.textLight),
              _buildDetailItem(Icons.account_balance_wallet, '₹${contest['entryFee']}', AppColors.primary),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _joinContest(contest),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Join Contest', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String text, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
      ],
    );
  }

  Future<void> _joinContest(Map<String, dynamic> contest) async {
    final result = await BeautyDialog.showConfirmation(
      context,
      title: 'Join Contest',
      message: 'Join "${contest['name']}" for ₹${contest['entryFee']}?',
      confirmText: 'Create Team & Join',
      cancelText: 'Cancel',
      type: BeautyDialogType.info,
    );

    if (result == true && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CreateNewTeamScreen()),
      );
    }
  }
}
