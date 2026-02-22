import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/core/services/match_service.dart';
import 'package:fantasy_crick/models/match_model.dart';
import 'package:fantasy_crick/models/scoreboard_model.dart';
import 'package:fantasy_crick/features/home/utils/app_utils.dart';

class MatchDetailScreen extends StatefulWidget {
  final MatchModel match;

  const MatchDetailScreen({super.key, required this.match});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MatchService _matchService = MatchService();

  ScoreboardModel? _scoreboard;
  bool _loadingScoreboard = true;
  String? _scoreboardError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadScoreboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadScoreboard() async {
    try {
      setState(() {
        _loadingScoreboard = true;
        _scoreboardError = null;
      });
      final scoreboard = await _matchService.getMatchScoreboard(widget.match.id);
      if (!mounted) return;
      setState(() {
        _scoreboard = scoreboard;
        _loadingScoreboard = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingScoreboard = false;
        _scoreboardError = 'Scoreboard not available';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final team1 = widget.match.teams.isNotEmpty ? widget.match.teams[0] : null;
    final team2 = widget.match.teams.length > 1 ? widget.match.teams[1] : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            iconTheme: const IconThemeData(color: AppColors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.primary, Color(0xFF1A237E)],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      if (widget.match.seriesName != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            widget.match.seriesName!,
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildTeamHeader(team1),
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text('VS', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  widget.match.format,
                                  style: const TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          _buildTeamHeader(team2),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${widget.match.venue.name}, ${widget.match.venue.city}',
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        AppUtils.formatMatchDate(widget.match.dateTime),
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.white,
              labelColor: AppColors.white,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(text: 'Info'),
                Tab(text: '1st Innings'),
                Tab(text: '2nd Innings'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildInfoTab(),
            _buildInningsTab(_scoreboard?.firstInnings, '1st Innings'),
            _buildInningsTab(_scoreboard?.secondInnings, '2nd Innings'),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamHeader(Team? team) {
    return Column(
      children: [
        if (team?.imageUrl != null)
          CachedNetworkImage(
            imageUrl: team!.imageUrl!,
            width: 44,
            height: 44,
            placeholder: (context, url) => _buildSmallPlaceholder(team.shortName),
            errorWidget: (context, url, error) => _buildSmallPlaceholder(team.shortName),
          )
        else
          _buildSmallPlaceholder(team?.shortName ?? '?'),
        const SizedBox(height: 6),
        Text(
          team?.shortName ?? 'TBD',
          style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildSmallPlaceholder(String text) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(text.isNotEmpty ? text[0] : '?', style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard('Match Info', [
            _infoRow('Match', widget.match.matchDesc ?? widget.match.teams.map((t) => t.shortName).join(" vs ")),
            _infoRow('Format', widget.match.format),
            _infoRow('Status', widget.match.status.toUpperCase()),
            if (widget.match.seriesCategory != null)
              _infoRow('Category', widget.match.seriesCategory!),
            if (widget.match.dateHeader != null)
              _infoRow('Date', widget.match.dateHeader!),
          ]),
          const SizedBox(height: 12),
          _buildInfoCard('Venue', [
            _infoRow('Ground', widget.match.venue.name),
            _infoRow('City', widget.match.venue.city),
            if (widget.match.venue.country != null)
              _infoRow('Country', widget.match.venue.country!),
          ]),
          if (_scoreboard != null && _scoreboard!.hasData) ...[
            const SizedBox(height: 12),
            _buildScoreSummaryCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Score Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const Divider(),
          if (_scoreboard?.firstInnings?.total != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('1st Innings', style: TextStyle(color: AppColors.textLight)),
                  Text(
                    _scoreboard!.firstInnings!.total!.formatted,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
          if (_scoreboard?.secondInnings?.total != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('2nd Innings', style: TextStyle(color: AppColors.textLight)),
                Text(
                  _scoreboard!.secondInnings!.total!.formatted,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const Divider(),
          ...rows,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 13))),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildInningsTab(InningsData? innings, String title) {
    if (_loadingScoreboard) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_scoreboardError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppColors.textLight),
            const SizedBox(height: 12),
            Text(_scoreboardError!, style: const TextStyle(color: AppColors.textLight)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadScoreboard,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Retry', style: TextStyle(color: AppColors.white)),
            ),
          ],
        ),
      );
    }

    if (innings == null || innings.batters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_cricket, size: 48, color: AppColors.textLight.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text('$title data not available yet', style: const TextStyle(color: AppColors.textLight)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadScoreboard,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Total Score
            if (innings.total != null)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      innings.total!.formatted,
                      style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 24),
                    ),
                  ],
                ),
              ),

            // Batters Card
            _buildBattersCard(innings.batters),
            const SizedBox(height: 12),

            // Bowlers Card
            _buildBowlersCard(innings.bowlers),
            const SizedBox(height: 12),

            // Extras
            if (innings.extras != null) ...[
              _buildExtrasCard(innings.extras!),
              const SizedBox(height: 12),
            ],

            // Powerplay
            if (innings.powerplays != null) ...[
              _buildPowerplayCard(innings.powerplays!),
              const SizedBox(height: 12),
            ],

            // Fall of Wickets
            if (innings.fallOfWickets != null && innings.fallOfWickets!.detail.isNotEmpty) ...[
              _buildFallOfWicketsCard(innings.fallOfWickets!),
              const SizedBox(height: 12),
            ],

            // Did not bat
            if (innings.didNotBat != null && innings.didNotBat!.players.isNotEmpty) ...[
              _buildDidNotBatCard(innings.didNotBat!),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBattersCard(List<BatterData> batters) {
    return Container(
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Batter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textLight))),
                Expanded(child: Text('R', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textLight), textAlign: TextAlign.center)),
                Expanded(child: Text('B', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textLight), textAlign: TextAlign.center)),
                Expanded(child: Text('4s', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textLight), textAlign: TextAlign.center)),
                Expanded(child: Text('6s', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textLight), textAlign: TextAlign.center)),
                Expanded(child: Text('SR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textLight), textAlign: TextAlign.center)),
              ],
            ),
          ),
          ...batters.map((batter) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(batter.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                        Expanded(child: Text(batter.runs, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center)),
                        Expanded(child: Text(batter.balls, style: const TextStyle(fontSize: 13, color: AppColors.textLight), textAlign: TextAlign.center)),
                        Expanded(child: Text(batter.fours, style: const TextStyle(fontSize: 13, color: AppColors.textLight), textAlign: TextAlign.center)),
                        Expanded(child: Text(batter.sixes, style: const TextStyle(fontSize: 13, color: AppColors.textLight), textAlign: TextAlign.center)),
                        Expanded(child: Text(batter.strikeRate, style: const TextStyle(fontSize: 13, color: AppColors.textLight), textAlign: TextAlign.center)),
                      ],
                    ),
                    if (batter.dismissal.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(batter.dismissal, style: const TextStyle(fontSize: 10, color: AppColors.textLight, fontStyle: FontStyle.italic)),
                      ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildBowlersCard(List<BowlerData> bowlers) {
    return Container(
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Bowler', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textLight))),
                Expanded(child: Text('O', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textLight), textAlign: TextAlign.center)),
                Expanded(child: Text('M', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textLight), textAlign: TextAlign.center)),
                Expanded(child: Text('R', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textLight), textAlign: TextAlign.center)),
                Expanded(child: Text('W', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textLight), textAlign: TextAlign.center)),
                Expanded(child: Text('ECO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textLight), textAlign: TextAlign.center)),
              ],
            ),
          ),
          ...bowlers.map((bowler) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
                ),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text(bowler.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                    Expanded(child: Text(bowler.overs, style: const TextStyle(fontSize: 13, color: AppColors.textLight), textAlign: TextAlign.center)),
                    Expanded(child: Text(bowler.maidens, style: const TextStyle(fontSize: 13, color: AppColors.textLight), textAlign: TextAlign.center)),
                    Expanded(child: Text(bowler.runs, style: const TextStyle(fontSize: 13, color: AppColors.textLight), textAlign: TextAlign.center)),
                    Expanded(child: Text(bowler.wickets, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center)),
                    Expanded(child: Text(bowler.economy, style: const TextStyle(fontSize: 13, color: AppColors.textLight), textAlign: TextAlign.center)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildExtrasCard(ExtrasData extras) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Extras', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Flexible(
            child: Text(
              '${extras.total} (${extras.detail})',
              style: const TextStyle(fontSize: 13, color: AppColors.textLight),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPowerplayCard(PowerplayData powerplay) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(powerplay.label.isNotEmpty ? powerplay.label : 'Powerplay', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text('${powerplay.overs} ov, ${powerplay.runs} runs', style: const TextStyle(fontSize: 13, color: AppColors.textLight)),
        ],
      ),
    );
  }

  Widget _buildFallOfWicketsCard(FallOfWicketsData fow) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(fow.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: fow.detail
                .map((d) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(d, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDidNotBatCard(DidNotBatData dnb) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Did Not Bat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          Text(dnb.players.join(', '), style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
        ],
      ),
    );
  }
}
