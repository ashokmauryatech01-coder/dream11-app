import 'package:flutter/material.dart';
import 'package:fantasy_crick/common/widgets/beauty_dialog.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _matchReminders = true;
  bool _contestReminders = true;
  bool _deadlineReminders = true;
  int _reminderTime = 30;

  final List<Map<String, dynamic>> _upcomingMatches = [
    {'teams': 'MI vs CSK', 'time': 'Today 7:00 PM', 'enabled': true, 'type': 'match', 'icon': '🏏'},
    {'teams': 'RCB vs KKR', 'time': 'Tomorrow 3:00 PM', 'enabled': false, 'type': 'match', 'icon': '🏏'},
    {'teams': 'DC vs SRH', 'time': 'Tomorrow 7:00 PM', 'enabled': true, 'type': 'match', 'icon': '🏏'},
  ];

  final List<Map<String, dynamic>> _contestDeadlines = [
    {'title': 'Mega Contest Entry', 'time': 'Today 6:30 PM', 'enabled': true, 'type': 'contest', 'prize': '₹1 Crore'},
    {'title': 'Head to Head', 'time': 'Today 6:45 PM', 'enabled': true, 'type': 'contest', 'prize': '₹100'},
    {'title': 'Winner Takes All', 'time': 'Tomorrow 2:30 PM', 'enabled': false, 'type': 'contest', 'prize': '₹50,000'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showReminderSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSettingsBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reminders', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: _showReminderSettings),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textLight,
          indicatorColor: AppColors.primary,
          tabs: const [Tab(text: 'Matches'), Tab(text: 'Contests')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMatchReminders(),
          _buildContestReminders(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addCustomReminder(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_alarm, color: AppColors.white),
        label: const Text('Add Reminder', style: TextStyle(color: AppColors.white)),
      ),
    );
  }

  Widget _buildMatchReminders() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard(),
        const SizedBox(height: 16),
        const Text('Upcoming Matches', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._upcomingMatches.asMap().entries.map((entry) => _buildMatchCard(entry.key, entry.value)),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildContestReminders() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildContestInfoCard(),
        const SizedBox(height: 16),
        const Text('Contest Deadlines', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._contestDeadlines.asMap().entries.map((entry) => _buildContestCard(entry.key, entry.value)),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.notifications_active, color: AppColors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Never Miss a Match!', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text('Get notified $_reminderTime min before match starts', style: TextStyle(color: AppColors.white.withOpacity(0.9), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContestInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.secondary, AppColors.secondary.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.timer, color: AppColors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Don't Miss Contest Deadlines!", style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text('Reminded before entry closes', style: TextStyle(color: AppColors.white.withOpacity(0.9), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(int index, Map<String, dynamic> match) {
    return Dismissible(
      key: Key('match_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete, color: AppColors.white),
      ),
      onDismissed: (_) => setState(() => _upcomingMatches.removeAt(index)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(match['icon'], style: const TextStyle(fontSize: 24))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(match['teams'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.schedule, size: 14, color: AppColors.textLight),
                    const SizedBox(width: 4),
                    Text(match['time'], style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                  ]),
                ],
              ),
            ),
            Switch(
              value: match['enabled'],
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() => match['enabled'] = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContestCard(int index, Map<String, dynamic> contest) {
    return Dismissible(
      key: Key('contest_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete, color: AppColors.white),
      ),
      onDismissed: (_) => setState(() => _contestDeadlines.removeAt(index)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.emoji_events, color: AppColors.secondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contest['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text(contest['prize'], style: const TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.schedule, size: 14, color: AppColors.textLight),
                    const SizedBox(width: 4),
                    Text(contest['time'], style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                  ]),
                ],
              ),
            ),
            Switch(
              value: contest['enabled'],
              activeColor: AppColors.secondary,
              onChanged: (v) => setState(() => contest['enabled'] = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsBottomSheet() {
    return StatefulBuilder(
      builder: (context, setSheetState) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Reminder Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildSettingSwitch('Match Reminders', 'Get notified before matches', _matchReminders, (v) => setSheetState(() => _matchReminders = v)),
            _buildSettingSwitch('Contest Reminders', 'Reminder for contest deadlines', _contestReminders, (v) => setSheetState(() => _contestReminders = v)),
            _buildSettingSwitch('Deadline Alerts', 'Final warning before deadline', _deadlineReminders, (v) => setSheetState(() => _deadlineReminders = v)),
            const SizedBox(height: 20),
            const Text('Reminder Time Before Match', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [15, 30, 60].map((mins) => GestureDetector(
                onTap: () => setSheetState(() => _reminderTime = mins),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: _reminderTime == mins ? AppColors.primary : AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$mins min', style: TextStyle(color: _reminderTime == mins ? AppColors.white : AppColors.text, fontWeight: FontWeight.w600)),
                ),
              )).toList(),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingSwitch(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(subtitle, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
          ])),
          Switch(value: value, activeColor: AppColors.primary, onChanged: onChanged),
        ],
      ),
    );
  }

  Future<void> _addCustomReminder() async {
    await BeautyDialog.show(context, title: 'Coming Soon', message: 'Custom reminder feature will be available soon!', type: BeautyDialogType.info);
  }
}
