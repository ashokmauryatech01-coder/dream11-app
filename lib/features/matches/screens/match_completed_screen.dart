import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/core/services/match_service.dart';
import 'package:fantasy_crick/models/match_model.dart';
import 'package:fantasy_crick/models/scoreboard_model.dart';
import 'package:fantasy_crick/features/contest/screens/my_contest_screen.dart';
import 'package:fantasy_crick/features/matches/screens/match_detail_screen.dart';

class MatchCompletedScreen extends StatefulWidget {
  final MatchModel? match;

  const MatchCompletedScreen({super.key, this.match});

  @override
  State<MatchCompletedScreen> createState() => _MatchCompletedScreenState();
}

class _MatchCompletedScreenState extends State<MatchCompletedScreen> {
  final MatchService _matchService = MatchService();
  ScoreboardModel? _scoreboard;
  bool _loadingScore = true;

  @override
  void initState() {
    super.initState();
    _loadScoreboard();
  }

  Future<void> _loadScoreboard() async {
    if (widget.match == null) {
      setState(() => _loadingScore = false);
      return;
    }
    try {
      setState(() => _loadingScore = true);
      final sb = await _matchService.getMatchScoreboard(widget.match!.id);
      if (!mounted) return;
      setState(() {
        _scoreboard = sb;
        _loadingScore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingScore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Match Completed', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
        actions: [
          if (widget.match != null)
            IconButton(
              icon: const Icon(Icons.scoreboard_outlined),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => MatchDetailScreen(match: widget.match!)));
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadScoreboard,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildResultCard(),
            const SizedBox(height: 16),
            if (_loadingScore)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)))
            else if (_scoreboard != null && _scoreboard!.hasData) ...[
              _buildScoreSummary(),
              const SizedBox(height: 16),
            ],
            _buildContestResult(context),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final team1 = widget.match?.teams.isNotEmpty == true ? widget.match!.teams[0] : null;
    final team2 = widget.match != null && widget.match!.teams.length > 1 ? widget.match!.teams[1] : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          if (widget.match?.matchDesc != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(widget.match!.matchDesc!, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTeamCol(team1),
              const Text('VS', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textLight, fontSize: 16)),
              _buildTeamCol(team2),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.match?.status ?? 'Completed',
              style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
          if (widget.match != null) ...[
            const SizedBox(height: 8),
            Text(
              '${widget.match!.venue.name}, ${widget.match!.venue.city}',
              style: const TextStyle(color: AppColors.textLight, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamCol(Team? team) {
    return Column(
      children: [
        if (team?.imageUrl != null)
          CachedNetworkImage(
            imageUrl: team!.imageUrl!,
            width: 40,
            height: 40,
            errorWidget: (ctx, url, err) => _buildPlaceholder(team.shortName),
          )
        else
          _buildPlaceholder(team?.shortName ?? '?'),
        const SizedBox(height: 6),
        Text(team?.shortName ?? 'TBD', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildPlaceholder(String text) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: Center(child: Text(text.isNotEmpty ? text[0] : '?', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18))),
    );
  }

  Widget _buildScoreSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Score', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          if (_scoreboard?.firstInnings?.total != null)
            _scoreRow('1st Innings', _scoreboard!.firstInnings!.total!.formatted),
          if (_scoreboard?.secondInnings?.total != null)
            _scoreRow('2nd Innings', _scoreboard!.secondInnings!.total!.formatted),
        ],
      ),
    );
  }

  Widget _scoreRow(String label, String score) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
          Text(score, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildContestResult(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your Contest Result', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Stat(label: 'Rank', value: '#12'),
              _Stat(label: 'Points', value: '234'),
              _Stat(label: 'Prize', value: '₹1,200'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const MyContestScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('View Details', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
