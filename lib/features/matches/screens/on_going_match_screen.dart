import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/core/services/match_service.dart';
import 'package:fantasy_crick/models/match_model.dart';
import 'package:fantasy_crick/models/scoreboard_model.dart';
import 'package:fantasy_crick/features/matches/screens/match_detail_screen.dart';

class OnGoingMatchScreen extends StatefulWidget {
  final MatchModel? match;

  const OnGoingMatchScreen({super.key, this.match});

  @override
  State<OnGoingMatchScreen> createState() => _OnGoingMatchScreenState();
}

class _OnGoingMatchScreenState extends State<OnGoingMatchScreen> {
  final MatchService _matchService = MatchService();
  ScoreboardModel? _scoreboard;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadScoreboard();
  }

  Future<void> _loadScoreboard() async {
    if (widget.match == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      setState(() => _loading = true);
      final sb = await _matchService.getMatchScoreboard(widget.match!.id);
      if (!mounted) return;
      setState(() {
        _scoreboard = sb;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String get _matchTitle {
    if (widget.match == null) return 'Live Match';
    final t = widget.match!.teams;
    if (t.length >= 2) return '${t[0].shortName} vs ${t[1].shortName}';
    return t.isNotEmpty ? t[0].shortName : 'Live Match';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Live Match', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
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
            _buildLiveHeader(),
            const SizedBox(height: 16),
            _buildScoreCard(),
            const SizedBox(height: 16),
            if (_scoreboard != null && _scoreboard!.hasData) ...[
              _buildCurrentBatters(),
              const SizedBox(height: 16),
              _buildCurrentBowlers(),
              const SizedBox(height: 16),
            ],
            _buildContestSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveHeader() {
    final team1 = widget.match?.teams.isNotEmpty == true ? widget.match!.teams[0] : null;
    final team2 = widget.match != null && widget.match!.teams.length > 1 ? widget.match!.teams[1] : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (team1?.imageUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: CachedNetworkImage(imageUrl: team1!.imageUrl!, width: 28, height: 28, errorWidget: (ctx, url, err) => const SizedBox()),
                    ),
                  Text(_matchTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  if (team2?.imageUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: CachedNetworkImage(imageUrl: team2!.imageUrl!, width: 28, height: 28, errorWidget: (ctx, url, err) => const SizedBox()),
                    ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(6)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    const Text('LIVE', style: TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          if (widget.match?.seriesName != null) ...[
            const SizedBox(height: 6),
            Text(widget.match!.seriesName!, style: const TextStyle(fontSize: 11, color: AppColors.textLight), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreCard() {
    final innings = _scoreboard?.secondInnings ?? _scoreboard?.firstInnings;
    final total = innings?.total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)))
          else if (total != null) ...[
            Text(total.formatted, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
            const SizedBox(height: 4),
            Text(widget.match?.format ?? '', style: const TextStyle(color: AppColors.textLight)),
          ] else ...[
            Text(_matchTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              widget.match != null ? '${widget.match!.venue.name}, ${widget.match!.venue.city}' : 'Score will appear here',
              style: const TextStyle(color: AppColors.textLight, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentBatters() {
    final innings = _scoreboard?.secondInnings ?? _scoreboard?.firstInnings;
    if (innings == null || innings.batters.isEmpty) return const SizedBox();
    // Show last 2 batters (current batting pair)
    final currentBatters = innings.batters.length > 2 ? innings.batters.sublist(innings.batters.length - 2) : innings.batters;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Batting', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          ...currentBatters.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(b.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                    Text('${b.runs}(${b.balls})', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildCurrentBowlers() {
    final innings = _scoreboard?.secondInnings ?? _scoreboard?.firstInnings;
    if (innings == null || innings.bowlers.isEmpty) return const SizedBox();
    final currentBowler = innings.bowlers.last;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bowling', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(currentBowler.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
              Text('${currentBowler.wickets}/${currentBowler.runs} (${currentBowler.overs} ov)', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContestSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your Contest', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Stat(label: 'Rank', value: '#45'),
              _Stat(label: 'Points', value: '256'),
              _Stat(label: 'Prize', value: '₹500'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Set Alerts', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
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
