import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';

class MyMatchesScreen extends StatefulWidget {
  const MyMatchesScreen({super.key});

  @override
  State<MyMatchesScreen> createState() => _MyMatchesScreenState();
}

class _MyMatchesScreenState extends State<MyMatchesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
        title: const Text('My Matches', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textLight,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Live'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUpcomingTab(),
          _buildLiveTab(),
          _buildCompletedTab(),
        ],
      ),
    );
  }

  Widget _buildUpcomingTab() {
    final matches = [
      {'id': 1, 'team1': 'MI', 'team2': 'CSK', 'date': 'Today', 'time': '7:30 PM', 'venue': 'Wankhede Stadium, Mumbai', 'teams': 2, 'contests': 3},
      {'id': 2, 'team1': 'RCB', 'team2': 'KKR', 'date': 'Tomorrow', 'time': '3:30 PM', 'venue': 'M. Chinnaswamy Stadium, Bangalore', 'teams': 1, 'contests': 2},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];
        return _buildMatchCard(
          match: match,
          child: Row(
            children: [
              Expanded(child: _buildActionButton('Edit Team', Icons.edit, isPrimary: false)),
              const SizedBox(width: 10),
              Expanded(child: _buildActionButton('Join Contest', Icons.emoji_events, isPrimary: false)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLiveTab() {
    final matches = [
      {'id': 4, 'team1': 'GT', 'team2': 'LSG', 'date': 'Today', 'time': '3:30 PM', 'venue': 'Ahmebad', 'liveScore': '145/3 (15.2)', 'over': '16th Over', 'teams': 1, 'contests': 2},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];
        return _buildMatchCard(
          match: match,
          isLive: true,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                child: Column(
                  children: [
                    Text(match['liveScore'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(match['over'] as String, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              _buildActionButton('View Live', Icons.remove_red_eye, isPrimary: true, fullWidth: true),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompletedTab() {
     final matches = [
      {'id': 5, 'team1': 'MI', 'team2': 'RCB', 'date': 'May 25', 'time': '7:30 PM', 'venue': 'Mumbai', 'teams': 2, 'contests': 4, 'result': 'MI won by 6 wickets', 'points': 156, 'rank': 45, 'prize': '₹500'},
      {'id': 6, 'team1': 'CSK', 'team2': 'KKR', 'date': 'May 24', 'time': '7:30 PM', 'venue': 'Chennai', 'teams': 1, 'contests': 3, 'result': 'CSK won by 27 runs', 'points': 234, 'rank': 12, 'prize': '₹1,200'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];
        final prize = match['prize'] as String;
        final won = prize != '₹0';
        
        return _buildMatchCard(
          match: match,
          statusLabel: won ? 'WON' : 'LOST',
          statusColor: won ? AppColors.success : AppColors.textLight,
          child: Column(
            children: [
              Text(match['result'] as String, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.white, fontSize: 10)), // Wait, this was in badge logic in JS.
              // Adapting layout
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 10),
                child: Text(match['result'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat('Teams', '${match['teams']}'),
                  _buildStat('Points', '${match['points']}'),
                  _buildStat('Rank', '${match['rank']}'),
                  _buildStat('Prize', prize, color: won ? AppColors.success : AppColors.textLight),
                ],
              ),
              const SizedBox(height: 15),
              _buildActionButton('View Details', Icons.visibility, isPrimary: true, fullWidth: true),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMatchCard({
    required Map<String, dynamic> match,
    Widget? child,
    bool isLive = false,
    String? statusLabel,
    Color? statusColor,
  }) {
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
            children: [
              if (isLive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(4)),
                  child: const Text('LIVE', style: TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              else if (statusLabel != null)
                 Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(4)),
                  child: Text(statusLabel, style: const TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              else
                const SizedBox(),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(match['date'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${match['time']} • ${match['venue']}', style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(match['team1'] as String, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
               const Text('VS', style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
               Text(match['team2'] as String, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          if (!isLive && statusLabel == null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Teams', '${match['teams']}'),
                _buildStat('Contests', '${match['contests']}'),
              ],
            ),
          
          if (child != null)
            Padding(
              padding: const EdgeInsets.only(top: 15),
              child: child,
            )
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color ?? AppColors.text)),
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, {bool isPrimary = true, bool fullWidth = false}) {
    final button = ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? AppColors.primary : AppColors.background,
        foregroundColor: isPrimary ? AppColors.white : AppColors.primary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 5),
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );

    if (fullWidth) return SizedBox(width: double.infinity, child: button);
    return button;
  }
}
