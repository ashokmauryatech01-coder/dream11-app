import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/core/services/entity_sport_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import 'dart:io';

class EsTeamPreviewScreen extends StatefulWidget {
  final Map<String, dynamic> team;
  const EsTeamPreviewScreen({super.key, required this.team});

  @override
  State<EsTeamPreviewScreen> createState() => _EsTeamPreviewScreenState();
}

class _EsTeamPreviewScreenState extends State<EsTeamPreviewScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic> _playerPoints = {};
  Map<String, String> _playerNamesMap = {};
  Map<String, String> _playerRolesMap = {};
  String _matchScore = '';
  String _matchStatusNote = '';
  double _calculatedTotal = 0;
  bool _isLoadingPoints = false;
  AnimationController? _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fetchPoints();
    _animationController?.forward();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  Future<void> _fetchPoints() async {
    final matchIdStr = widget.team['match_id']?.toString() ?? '';
    final matchId = int.tryParse(matchIdStr) ?? 0;
    if (matchId == 0) return;

    setState(() => _isLoadingPoints = true);
    try {
      final pointsData = await EntitySportService.getMatchPoints(matchId);
      final squadData = await EntitySportService.getFantasySquad(matchId);
      
      final pointsMap = <String, dynamic>{};
      final namesMap = <String, String>{};
      final rolesMap = <String, String>{};

      // Extract Match Score & Status
      final teamA = pointsData['teama'] as Map? ?? {};
      final teamB = pointsData['teamb'] as Map? ?? {};
      final sA = teamA['scores'] ?? teamA['scores_full'] ?? '';
      final sB = teamB['scores'] ?? teamB['scores_full'] ?? '';
      final nA = teamA['short_name'] ?? teamA['name'] ?? 'T1';
      final nB = teamB['short_name'] ?? teamB['name'] ?? 'T2';
      
      String scoreText = '';
      if (sA.isNotEmpty || sB.isNotEmpty) {
        scoreText = '$nA: $sA vs $nB: $sB';
      }
      
      final statusNote = pointsData['status_note']?.toString() ?? '';

      // Extract Players from points API
      final ta = pointsData['points']?['teama']?['playing11'] as List? ?? [];
      final tb = pointsData['points']?['teamb']?['playing11'] as List? ?? [];

      for (var p in [...ta, ...tb]) {
        if (p is Map) {
          final pid = p['pid']?.toString() ?? '';
          if (pid.isNotEmpty) {
            pointsMap[pid] = p['point'];
            namesMap[pid] = p['name']?.toString() ?? '';
            rolesMap[pid] = p['role']?.toString().toUpperCase() ?? '';
          }
        }
      }

      // Supplement from Squad API
      final squadPlayers = squadData['players'] as List? ?? [];
      for (var p in squadPlayers) {
        if (p is Map) {
          final pid = p['pid']?.toString() ?? p['player_id']?.toString() ?? '';
          if (pid.isNotEmpty) {
            final name = p['name']?.toString() ?? p['title']?.toString() ?? '';
            if (name.isNotEmpty && (!namesMap.containsKey(pid) || namesMap[pid]!.isEmpty)) {
              namesMap[pid] = name;
            }
            if (!rolesMap.containsKey(pid) || rolesMap[pid]!.isEmpty) {
              rolesMap[pid] = p['role']?.toString().toUpperCase() ?? p['playing_role']?.toString().toUpperCase() ?? '';
            }
          }
        }
      }

      // Calculate Total with Captain/VC multipliers
      double teamTotal = 0;
      final teamPlayers = widget.team['players'] as List? ?? [];
      final capId = widget.team['captain_id']?.toString();
      final vcId = widget.team['vice_captain_id']?.toString();
      
      for (var p in teamPlayers) {
        final pid = (p is Map ? (p['id'] ?? p['player_id'] ?? p['pid']) : p).toString();
        final rawVal = pointsMap[pid];
        double basePts = double.tryParse(rawVal?.toString() ?? '0') ?? 0;
        double finalPts = basePts;
        if (pid == capId) finalPts *= 2.0; else if (pid == vcId) finalPts *= 1.5;
        teamTotal += finalPts;
      }

      if (mounted) {
        setState(() {
          _playerPoints = pointsMap;
          _playerNamesMap = namesMap;
          _playerRolesMap = rolesMap;
          _calculatedTotal = teamTotal;
          _matchScore = scoreText;
          _matchStatusNote = statusNote;
          _isLoadingPoints = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPoints = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final players = widget.team['players'] as List? ?? [];
    final teamName = widget.team['name']?.toString() ?? 'My Team';

    final wks = players.where((p) => _getRole(p) == 'WK').toList();
    final bats = players.where((p) => _getRole(p) == 'BAT').toList();
    final ars = players.where((p) => _getRole(p) == 'AR').toList();
    final bowls = players.where((p) => _getRole(p) == 'BOWL').toList();

    return Scaffold(
      backgroundColor: const Color(0xFF034D34),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(teamName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            if (_matchScore.isNotEmpty)
              Text(_matchScore, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold))
            else
              const Text('Live Match Points', style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          _pointsWidget(_calculatedTotal.toStringAsFixed(1)),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.6,
              child: Image.asset(
                'assets/images/cricket_players_new.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: const Color(0xFF034D34)),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.6), Colors.transparent, Colors.black.withOpacity(0.9)],
                ),
              ),
            ),
          ),
          _buildPitchOverlay(),
          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                   if (_matchStatusNote.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.8), borderRadius: BorderRadius.circular(20)),
                      child: Text(_matchStatusNote, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  const SizedBox(height: 5),
                  _buildSection(wks, 'WK', 0.0),
                  const Spacer(),
                  _buildSection(bats, 'BAT', 0.2),
                  const Spacer(),
                  _buildSection(ars, 'AR', 0.4),
                  const Spacer(),
                  _buildSection(bowls, 'BOWL', 0.6),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          if (_isLoadingPoints)
            const Positioned(top: 100, left: 0, right: 0, child: Center(child: LinearProgressIndicator(backgroundColor: Colors.transparent, valueColor: AlwaysStoppedAnimation<Color>(Colors.white24)))),
        ],
      ),
    );
  }

  Widget _pointsWidget(String pts) {
    return Container(
      margin: const EdgeInsets.only(right: 16, top: 4, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(pts, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, height: 1.1)),
          const Text('TEAM PTS', style: TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5, height: 1.1)),
        ],
      ),
    );
  }

  String _getRole(dynamic p) {
    final String pid = (p is Map ? (p['id'] ?? p['player_id'] ?? p['pid']) : p).toString();
    if (_playerRolesMap.containsKey(pid)) {
      final r = _playerRolesMap[pid]!;
      if (r.contains('WK')) return 'WK';
      if (r.contains('BAT')) return 'BAT';
      if (r.contains('AR') || r.contains('ALL')) return 'AR';
      if (r.contains('BOWL')) return 'BOWL';
    }
    if (p is! Map) return 'BAT';
    final role = (p['playing_role'] ?? p['role'])?.toString().toLowerCase() ?? 'bat';
    if (role.contains('wk')) return 'WK';
    if (role.contains('bat')) return 'BAT';
    if (role.contains('ar')) return 'AR';
    if (role.contains('bowl')) return 'BOWL';
    return 'BAT';
  }

  Widget _buildPitchOverlay() {
    return Positioned.fill(
      child: CustomPaint(painter: PitchPainter()),
    );
  }

  Widget _buildSection(List<dynamic> list, String role, double delay) {
    if (list.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Wrap(
        spacing: 12, runSpacing: 12,
        alignment: WrapAlignment.center,
        children: list.map((p) => _animatedPlayer(p, delay)).toList(),
      ),
    );
  }

  Widget _animatedPlayer(dynamic p, double delay) {
    if (_animationController == null) return _playerWidget(p);
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _animationController!,
        curve: Interval(delay, (delay + 0.4).clamp(0.0, 1.0), curve: Curves.easeIn),
      ),
      child: ScaleTransition(
        scale: CurvedAnimation(
          parent: _animationController!,
          curve: Interval(delay, (delay + 0.4).clamp(0.0, 1.0), curve: Curves.elasticOut),
        ),
        child: _playerWidget(p),
      ),
    );
  }

  Widget _playerWidget(dynamic p) {
    final String pid = (p is Map ? (p['id'] ?? p['player_id'] ?? p['pid']) : p).toString();
    final bool isMap = p is Map;
    final String role = _getRole(p);
    final String apiName = _playerNamesMap[pid] ?? '';
    final String name = apiName.isNotEmpty ? apiName : (isMap ? (p['name'] ?? p['title'] ?? 'Player').toString() : 'Player');
    final String imageUrl = isMap ? (p['photo_url'] ?? p['image'] ?? p['thumb_url'] ?? '').toString() : '';
    final rawPts = _playerPoints[pid]?.toString() ?? (isMap ? (p['point'] ?? p['points'] ?? '0').toString() : '0');
    final double basePts = double.tryParse(rawPts) ?? 0;
    
    final pivot = isMap ? (p['pivot'] as Map?) : null;
    final isCaptain = (pivot != null && pivot['is_captain'] == 1) || pid == widget.team['captain_id']?.toString();
    final isVC = (pivot != null && pivot['is_vice_captain'] == 1) || pid == widget.team['vice_captain_id']?.toString();

    double finalPts = basePts;
    if (isCaptain) finalPts *= 2.0; else if (isVC) finalPts *= 1.5;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 58, height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 8, offset: const Offset(0, 4))],
                color: Colors.white,
              ),
              child: ClipOval(
                child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl, fit: BoxFit.cover, 
                      placeholder: (_, __) => _rolePlaceholder(role),
                      errorWidget: (_, __, ___) => _rolePlaceholder(role),
                    )
                  : _rolePlaceholder(role),
              ),
            ),
            if (isCaptain || isVC)
              Positioned(
                top: -2, right: -2,
                child: Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: isCaptain ? const Color(0xFFFFC107) : const Color(0xFF2196F3),
                    shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                  child: Center(child: Text(isCaptain ? 'C' : 'VC', style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900))),
                ),
              ),
            Positioned(
              bottom: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B2430),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24, width: 1),
                  boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 2)],
                ),
                child: Text('${finalPts.toStringAsFixed(1)} pts', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(minWidth: 70),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _roleIcon(role),
              const SizedBox(width: 4),
              Flexible(child: Text(_shortName(name), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.2), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _rolePlaceholder(String role) {
    String assetPath;
    switch(role) {
      case 'WK': assetPath = 'assets/images/wk_placeholder.png'; break;
      case 'AR': assetPath = 'assets/images/ar_placeholder.png'; break;
      case 'BOWL': assetPath = 'assets/images/bowler_placeholder.png'; break;
      default: assetPath = 'assets/images/player_placeholder.png';
    }
    return Image.asset(assetPath, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Image.asset('assets/images/player_placeholder.png', fit: BoxFit.cover));
  }

  Widget _roleIcon(String role) {
    IconData icon;
    Color color;
    switch(role) {
      case 'WK': icon = Icons.front_hand_rounded; color = const Color(0xFFFF9800); break;
      case 'BAT': icon = Icons.sports_cricket_rounded; color = const Color(0xFF4CAF50); break;
      case 'AR': icon = Icons.star_rounded; color = const Color(0xFFE91E63); break;
      case 'BOWL': icon = Icons.sports_baseball_rounded; color = const Color(0xFF2196F3); break;
      default: icon = Icons.person; color = Colors.white;
    }
    return Icon(icon, size: 10, color: color);
  }

  String _shortName(String name) {
    if (!name.contains(' ')) return name.toUpperCase();
    final parts = name.split(' ');
    if (parts.length < 2) return name.toUpperCase();
    return '${parts.first[0]}. ${parts.last}'.toUpperCase();
  }
}

class PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white24..style = PaintingStyle.stroke..strokeWidth = 1;
    final fillPaint = Paint()..color = Colors.white.withOpacity(0.01)..style = PaintingStyle.fill;
    final pitchRect = Rect.fromCenter(center: Offset(size.width/2, size.height/2), width: 50, height: 120);
    canvas.drawRect(pitchRect, fillPaint);
    canvas.drawRect(pitchRect, paint);
    canvas.drawLine(Offset(size.width/2 - 25, size.height/2 - 45), Offset(size.width/2 + 25, size.height/2 - 45), paint);
    canvas.drawLine(Offset(size.width/2 - 25, size.height/2 + 45), Offset(size.width/2 + 25, size.height/2 + 45), paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width/2, size.height/2), width: size.width * 0.9, height: size.height * 0.6), paint);
  }
  @override bool shouldRepaint(CustomPainter oldDelegate) => false;
}
