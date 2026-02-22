import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Map<String, List<Map<String, dynamic>>> _leaderboardData = {
    'weekly': [
      {'id': 1, 'rank': 1, 'name': 'Rahul Sharma', 'avatar': 'RS', 'points': 2456, 'teams': 45, 'winnings': '₹45,000', 'change': 'up', 'changeValue': 2},
      {'id': 2, 'rank': 2, 'name': 'Priya Patel', 'avatar': 'PP', 'points': 2389, 'teams': 42, 'winnings': '₹38,500', 'change': 'up', 'changeValue': 1},
      {'id': 3, 'rank': 3, 'name': 'Amit Kumar', 'avatar': 'AK', 'points': 2234, 'teams': 38, 'winnings': '₹32,000', 'change': 'down', 'changeValue': 1},
      {'id': 4, 'rank': 4, 'name': 'You', 'avatar': 'JD', 'points': 2156, 'teams': 35, 'winnings': '₹28,500', 'change': 'up', 'changeValue': 5, 'isCurrentUser': true},
      {'id': 5, 'rank': 5, 'name': 'Neha Gupta', 'avatar': 'NG', 'points': 2098, 'teams': 33, 'winnings': '₹25,000', 'change': 'same', 'changeValue': 0},
      {'id': 6, 'rank': 6, 'name': 'Vikram Singh', 'avatar': 'VS', 'points': 1987, 'teams': 31, 'winnings': '₹22,000', 'change': 'up', 'changeValue': 3},
      {'id': 7, 'rank': 7, 'name': 'Anjali Reddy', 'avatar': 'AR', 'points': 1876, 'teams': 29, 'winnings': '₹19,000', 'change': 'down', 'changeValue': 2},
      {'id': 8, 'rank': 8, 'name': 'Karan Mehta', 'avatar': 'KM', 'points': 1765, 'teams': 27, 'winnings': '₹16,000', 'change': 'same', 'changeValue': 0},
    ],
    'monthly': [
      {'id': 1, 'rank': 1, 'name': 'Vikram Singh', 'avatar': 'VS', 'points': 8456, 'teams': 156, 'winnings': '₹1,25,000', 'change': 'up', 'changeValue': 3},
      {'id': 2, 'rank': 2, 'name': 'Anjali Reddy', 'avatar': 'AR', 'points': 7892, 'teams': 142, 'winnings': '₹98,500', 'change': 'up', 'changeValue': 1},
      {'id': 3, 'rank': 3, 'name': 'Rahul Sharma', 'avatar': 'RS', 'points': 7654, 'teams': 135, 'winnings': '₹85,000', 'change': 'down', 'changeValue': 2},
      {'id': 4, 'rank': 4, 'name': 'You', 'avatar': 'JD', 'points': 7234, 'teams': 128, 'winnings': '₹72,500', 'change': 'up', 'changeValue': 8, 'isCurrentUser': true},
      {'id': 5, 'rank': 5, 'name': 'Priya Patel', 'avatar': 'PP', 'points': 6987, 'teams': 120, 'winnings': '₹65,000', 'change': 'same', 'changeValue': 0},
    ],
    'allTime': [
      {'id': 1, 'rank': 1, 'name': 'Master Cricket', 'avatar': 'MC', 'points': 45678, 'teams': 890, 'winnings': '₹12,45,000', 'change': 'same', 'changeValue': 0},
      {'id': 2, 'rank': 2, 'name': 'Fantasy King', 'avatar': 'FK', 'points': 42345, 'teams': 823, 'winnings': '₹10,89,000', 'change': 'same', 'changeValue': 0},
      {'id': 3, 'rank': 3, 'name': 'Cricket Guru', 'avatar': 'CG', 'points': 39876, 'teams': 756, 'winnings': '₹9,45,000', 'change': 'up', 'changeValue': 1},
      {'id': 4, 'rank': 4, 'name': 'You', 'avatar': 'JD', 'points': 34567, 'teams': 654, 'winnings': '₹7,89,000', 'change': 'up', 'changeValue': 12, 'isCurrentUser': true},
    ],
  };

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
        title: const Text('Leaderboard', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textLight,
          indicatorColor: AppColors.primary,
          tabs: const [Tab(text: 'Weekly'), Tab(text: 'Monthly'), Tab(text: 'All Time')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLeaderboardList('weekly'),
          _buildLeaderboardList('monthly'),
          _buildLeaderboardList('allTime'),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList(String period) {
    final data = _leaderboardData[period]!;
    return Column(
      children: [
        _buildTopThree(data.take(3).toList()),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            itemBuilder: (context, index) => _buildLeaderboardItem(data[index], index),
          ),
        ),
      ],
    );
  }

  Widget _buildTopThree(List<Map<String, dynamic>> topThree) {
    if (topThree.length < 3) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildTopPlayer(topThree[1], 2, 80),
          _buildTopPlayer(topThree[0], 1, 100),
          _buildTopPlayer(topThree[2], 3, 70),
        ],
      ),
    );
  }

  Widget _buildTopPlayer(Map<String, dynamic> player, int position, double height) {
    final colors = [Colors.amber, Colors.grey.shade400, Colors.brown.shade300];
    final icons = [Icons.emoji_events, Icons.military_tech, Icons.workspace_premium];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            CircleAvatar(
              radius: position == 1 ? 35 : 28,
              backgroundColor: AppColors.white,
              child: Text(player['avatar'] as String, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: position == 1 ? 18 : 14)),
            ),
            Positioned(
              bottom: -5,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: colors[position - 1], shape: BoxShape.circle),
                child: Icon(icons[position - 1], color: AppColors.white, size: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(player['name'] as String, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
        Text('${player['points']} pts', style: TextStyle(color: AppColors.white.withOpacity(0.9), fontSize: 11)),
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: 60,
          height: height,
          decoration: BoxDecoration(
            color: colors[position - 1].withOpacity(0.3),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Center(child: Text('#$position', style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 20))),
        ),
      ],
    );
  }

  Widget _buildLeaderboardItem(Map<String, dynamic> item, int index) {
    final bool isCurrentUser = item['isCurrentUser'] == true;
    final String change = item['change'] as String;
    final int changeValue = item['changeValue'] as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCurrentUser ? AppColors.primary.withOpacity(0.1) : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser ? Border.all(color: AppColors.primary, width: 2) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 35,
            child: index < 3
                ? Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: index == 0 ? Colors.amber : index == 1 ? Colors.grey.shade400 : Colors.brown.shade300,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(Icons.emoji_events, color: AppColors.white, size: 16),
                  )
                : Text('#${item['rank']}', style: TextStyle(fontWeight: FontWeight.bold, color: isCurrentUser ? AppColors.primary : AppColors.textLight)),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            backgroundColor: isCurrentUser ? AppColors.primary : AppColors.primary.withOpacity(0.1),
            child: Text(item['avatar'] as String, style: TextStyle(color: isCurrentUser ? AppColors.white : AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'] as String, style: TextStyle(fontWeight: FontWeight.bold, color: isCurrentUser ? AppColors.primary : AppColors.text)),
                Text('${item['teams']} teams • ${item['winnings']}', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${item['points']} pts', style: TextStyle(fontWeight: FontWeight.bold, color: isCurrentUser ? AppColors.primary : AppColors.success)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    change == 'up' ? Icons.arrow_upward : change == 'down' ? Icons.arrow_downward : Icons.remove,
                    size: 12,
                    color: change == 'up' ? AppColors.success : change == 'down' ? AppColors.error : AppColors.textLight,
                  ),
                  if (changeValue > 0) Text('$changeValue', style: TextStyle(fontSize: 11, color: change == 'up' ? AppColors.success : change == 'down' ? AppColors.error : AppColors.textLight)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
