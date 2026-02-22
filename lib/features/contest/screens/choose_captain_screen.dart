import 'package:flutter/material.dart';
import 'package:fantasy_crick/common/widgets/beauty_dialog.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';

class ChooseCaptainScreen extends StatefulWidget {
  const ChooseCaptainScreen({super.key});

  @override
  State<ChooseCaptainScreen> createState() => _ChooseCaptainScreenState();
}

class _ChooseCaptainScreenState extends State<ChooseCaptainScreen> {
  String? _captain;
  String? _viceCaptain;

  final List<String> _players = [
    'Rohit Sharma',
    'Virat Kohli',
    'MS Dhoni',
    'Jasprit Bumrah',
    'Hardik Pandya',
    'Ravindra Jadeja',
    'KL Rahul',
    'David Warner',
  ];

  Future<void> _confirmSelection() async {
    if (_captain == null || _viceCaptain == null) {
      await BeautyDialog.show(
        context,
        title: 'Select Leaders',
        message: 'Please select both a Captain and Vice Captain.',
        type: BeautyDialogType.warning,
      );
      return;
    }

    if (_captain == _viceCaptain) {
      await BeautyDialog.show(
        context,
        title: 'Invalid Selection',
        message: 'Captain and Vice Captain cannot be the same player.',
        type: BeautyDialogType.error,
      );
      return;
    }

    await BeautyDialog.show(
      context,
      title: 'Selection Complete',
      message: 'Captain and Vice Captain selected successfully!',
      type: BeautyDialogType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Choose Captain', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildSummary(),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _players.length,
              itemBuilder: (context, index) {
                final player = _players[index];
                return _buildPlayerRow(player);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Confirm', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSummaryItem('Captain', _captain ?? 'Select'),
          _buildSummaryItem('Vice Captain', _viceCaptain ?? 'Select'),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.text)),
      ],
    );
  }

  Widget _buildPlayerRow(String player) {
    final isCaptain = _captain == player;
    final isVice = _viceCaptain == player;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isCaptain || isVice ? AppColors.primary : AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(player.substring(0, 1), style: const TextStyle(color: AppColors.primary)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(player, style: const TextStyle(fontWeight: FontWeight.bold))),
          _buildRoleButton('C', isCaptain, () => setState(() => _captain = player)),
          const SizedBox(width: 8),
          _buildRoleButton('VC', isVice, () => setState(() => _viceCaptain = player)),
        ],
      ),
    );
  }

  Widget _buildRoleButton(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(color: selected ? AppColors.white : AppColors.textLight, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
