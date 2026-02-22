import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/core/services/match_service.dart';
import 'package:fantasy_crick/models/match_model.dart';
import 'package:fantasy_crick/features/home/widgets/match_card.dart';
import 'package:fantasy_crick/features/matches/screens/on_going_match_screen.dart';

class MyMatchesScreen3 extends StatelessWidget {
  const MyMatchesScreen3({super.key});

  @override
  Widget build(BuildContext context) {
    final matches = [
      {'team1': 'MI', 'team2': 'RCB', 'result': 'MI won by 6 wickets', 'points': 156, 'rank': 45, 'prize': '₹500'},
      {'team1': 'CSK', 'team2': 'KKR', 'result': 'CSK won by 27 runs', 'points': 234, 'rank': 12, 'prize': '₹1,200'},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Matches 3', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: matches.length,
        itemBuilder: (context, index) {
          final match = matches[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  LiveMatchesSection(),
                Text('${match['team1']} vs ${match['team2']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(match['result']?.toString() ?? 'Completed', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat('Points', '${match['points']}'),
                    _buildStat('Rank', '${match['rank']}'),
                    _buildStat('Prize', match['prize']?.toString() ?? '₹0', valueColor: AppColors.success),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStat(String label, String value, {Color valueColor = AppColors.text}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }
  }

  // Live matches section widget for matches screen
  class LiveMatchesSection extends StatefulWidget {
    @override
    State<LiveMatchesSection> createState() => _LiveMatchesSectionState();
  }

  class _LiveMatchesSectionState extends State<LiveMatchesSection> {
    final MatchService _matchService = MatchService();
    bool _loading = true;
    String? _error;
    List<MatchModel> _liveMatches = [];

    @override
    void initState() {
      super.initState();
      _loadLiveMatches();
    }

    Future<void> _loadLiveMatches() async {
      setState(() {
        _loading = true;
        _error = null;
      });
      try {
        final matches = await _matchService.getLiveMatches();
        if (!mounted) return;
        setState(() {
          _liveMatches = matches;
          _loading = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'Failed to load live matches.';
        });
      }
    }

    @override
    Widget build(BuildContext context) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Live Matches', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
          const SizedBox(height: 10),
          if (_loading)
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          if (_error != null && _liveMatches.isEmpty)
            Center(child: Text(_error!, style: const TextStyle(color: AppColors.textLight))),
          if (_liveMatches.isEmpty && !_loading && _error == null)
            const Center(child: Text('No live matches right now', style: TextStyle(color: AppColors.textLight))),
          if (_liveMatches.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _liveMatches.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: MatchCard(
                    match: _liveMatches[index],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OnGoingMatchScreen(match: _liveMatches[index]),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
        ],
      );
  }
}
