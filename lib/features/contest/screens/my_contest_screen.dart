import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/features/contest/screens/create_new_team_screen.dart';

class MyContestScreen extends StatefulWidget {
  const MyContestScreen({super.key});

  @override
  State<MyContestScreen> createState() => _MyContestScreenState();
}

class _MyContestScreenState extends State<MyContestScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _liveContests = [
    {
      'match': 'MI vs CSK',
      'contestName': 'Mega Contest',
      'teams': 2,
      'rank': 45,
      'totalTeams': 123456,
      'points': 245,
      'prize': '₹500',
    },
    {
      'match': 'RCB vs KKR',
      'contestName': 'Head to Head',
      'teams': 1,
      'rank': 1,
      'totalTeams': 2,
      'points': 189,
      'prize': '₹1000',
    },
  ];

  final List<Map<String, dynamic>> _upcomingContests = [
    {
      'match': 'DC vs SRH',
      'contestName': 'Small League',
      'teams': 1,
      'entryFee': '₹50',
      'time': '7:30 PM',
    },
    {
      'match': 'RR vs PBKS',
      'contestName': 'Winner Takes All',
      'teams': 1,
      'entryFee': '₹100',
      'time': '3:30 PM',
    },
  ];

  final List<Map<String, dynamic>> _completedContests = [
    {
      'match': 'MI vs RCB',
      'contestName': 'Mega Contest',
      'teams': 2,
      'rank': 123,
      'totalTeams': 98765,
      'points': 156,
      'prize': '₹0',
      'won': false,
    },
    {
      'match': 'CSK vs KKR',
      'contestName': 'Head to Head',
      'teams': 1,
      'rank': 1,
      'totalTeams': 2,
      'points': 234,
      'prize': '₹1000',
      'won': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Contests', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textLight,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Live'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLiveTab(),
          _buildUpcomingTab(),
          _buildCompletedTab(),
        ],
      ),
    );
  }

  Widget _buildLiveTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _liveContests.length,
      itemBuilder: (context, index) {
        final contest = _liveContests[index];
        return _buildContestCard(
          headerTag: _buildTag('LIVE', AppColors.error),
          contest: contest,
          footer: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat('Teams', '${contest['teams']}'),
              _buildStat('Rank', '${contest['rank']}/${contest['totalTeams']}'),
              _buildStat('Points', '${contest['points']}'),
              _buildStat('Prize', contest['prize'], valueColor: AppColors.success),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUpcomingTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _upcomingContests.length,
      itemBuilder: (context, index) {
        final contest = _upcomingContests[index];
        return _buildContestCard(
          headerTag: Row(
            children: [
              const Icon(Icons.schedule, size: 14, color: AppColors.textLight),
              const SizedBox(width: 4),
              Text(contest['time'], style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
            ],
          ),
          contest: contest,
          footer: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStat('Teams', '${contest['teams']}'),
              _buildStat('Entry Fee', contest['entryFee']),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CreateNewTeamScreen()),
                  );
                },
                icon: const Icon(Icons.edit, size: 16, color: AppColors.primary),
                label: const Text('Edit Team', style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompletedTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _completedContests.length,
      itemBuilder: (context, index) {
        final contest = _completedContests[index];
        final bool won = contest['won'] as bool;
        return _buildContestCard(
          headerTag: _buildTag(won ? 'WON' : 'LOST', won ? AppColors.success : AppColors.textLight),
          contest: contest,
          footer: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat('Teams', '${contest['teams']}'),
              _buildStat('Rank', '${contest['rank']}/${contest['totalTeams']}'),
              _buildStat('Points', '${contest['points']}'),
              _buildStat('Prize', contest['prize'], valueColor: won ? AppColors.success : AppColors.textLight),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContestCard({required Widget headerTag, required Map<String, dynamic> contest, required Widget footer}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contest['match'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(contest['contestName'], style: const TextStyle(color: AppColors.textLight)),
                ],
              ),
              headerTag,
            ],
          ),
          const SizedBox(height: 16),
          footer,
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, {Color? valueColor}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: valueColor ?? AppColors.text)),
      ],
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: const TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
