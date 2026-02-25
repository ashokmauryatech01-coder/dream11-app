import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/core/services/api_client.dart';

class EsHowToPlayScreen extends StatefulWidget {
  const EsHowToPlayScreen({super.key});

  @override
  State<EsHowToPlayScreen> createState() => _EsHowToPlayScreenState();
}

class _EsHowToPlayScreenState extends State<EsHowToPlayScreen> {
  bool _loading = true;
  List<dynamic> _steps = [];
  List<dynamic> _scoring = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiClient.get('/how-to-play');
      if (!mounted) return;
      setState(() {
        _steps = res?['data']?['steps'] ?? [];
        _scoring = res?['data']?['scoring'] ?? [];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        // Fallback demo data
        _steps = [
          {"title": "Select a Match", "description": "Choose from upcoming cricket matches.", "tips": "Look for matches with familiar teams."},
        ];
        _scoring = [
          {"type": "Batting Points", "points": [{"action": "Run", "points": "+1"}, {"action": "Boundary Bonus", "points": "+1"}]}
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('How To Play', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Getting Started', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 16),
                  ..._steps.asMap().entries.map((e) => _stepCard(e.key + 1, e.value)),
                  const SizedBox(height: 32),
                  const Text('Scoring System', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 16),
                  ..._scoring.map((s) => _scoringTable(s)),
                  const SizedBox(height: 50),
                ],
              ),
            ),
    );
  }

  Widget _stepCard(int index, dynamic step) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: AppColors.primary, radius: 14, child: Text('$index', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
              const SizedBox(width: 12),
              Expanded(child: Text(step['title']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            ],
          ),
          const SizedBox(height: 12),
          Text(step['description']?.toString() ?? '', style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.5)),
          if (step['tips'] != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(step['tips'].toString(), style: TextStyle(color: Colors.amber.shade800, fontSize: 13, fontWeight: FontWeight.w500))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _scoringTable(dynamic scoringObj) {
    final title = scoringObj['type']?.toString() ?? '';
    final points = (scoringObj['points'] as List<dynamic>?) ?? [];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12))),
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          const Divider(height: 1),
          // Rows
          ...points.map((p) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(p['action']?.toString() ?? '', style: TextStyle(color: Colors.grey[800], fontSize: 14)),
                Text(p['points']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14)),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }
}
