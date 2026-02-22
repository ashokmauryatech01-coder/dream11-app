import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _matchReminders = true;
  bool _contestReminders = true;
  bool _resultReminders = true;
  bool _promotionReminders = false;

  final List<Map<String, dynamic>> _notifications = [
    {
      'id': 1,
      'title': 'Match Starting Soon!',
      'message': 'MI vs CSK starts in 30 minutes. Create your team now!',
      'time': '30 min ago',
      'type': 'match',
      'read': false,
    },
    {
      'id': 2,
      'title': 'Contest Won! 🎉',
      'message': 'Congratulations! You won ₹500 in Mega Contest.',
      'time': '2 hours ago',
      'type': 'win',
      'read': false,
    },
    {
      'id': 3,
      'title': 'Bonus Credit',
      'message': 'You received ₹100 referral bonus!',
      'time': '5 hours ago',
      'type': 'bonus',
      'read': true,
    },
    {
      'id': 4,
      'title': 'New Contest Available',
      'message': 'RCB vs KKR - Join contests with prize pool up to ₹1 Crore!',
      'time': '1 day ago',
      'type': 'contest',
      'read': true,
    },
    {
      'id': 5,
      'title': 'Match Result',
      'message': 'MI won by 5 wickets. Check your points now!',
      'time': '2 days ago',
      'type': 'result',
      'read': true,
    },
  ];

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'match':
        return Icons.sports_cricket;
      case 'win':
        return Icons.emoji_events;
      case 'bonus':
        return Icons.card_giftcard;
      case 'contest':
        return Icons.leaderboard;
      case 'result':
        return Icons.flag;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'match':
        return AppColors.primary;
      case 'win':
        return AppColors.success;
      case 'bonus':
        return AppColors.warning;
      case 'contest':
        return Colors.purple;
      case 'result':
        return Colors.blue;
      default:
        return AppColors.textLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsSheet(),
          ),
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () {
              setState(() {
                for (var notification in _notifications) {
                  notification['read'] = true;
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications marked as read')),
              );
            },
          ),
        ],
      ),
      body: _notifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return _buildNotificationCard(notification);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off, size: 80, color: AppColors.textLight.withOpacity(0.5)),
          const SizedBox(height: 20),
          const Text(
            'No Notifications',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text),
          ),
          const SizedBox(height: 8),
          const Text(
            'You\'re all caught up!',
            style: TextStyle(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final bool isRead = notification['read'] as bool;
    final String type = notification['type'] as String;

    return Dismissible(
      key: Key(notification['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: AppColors.white),
      ),
      onDismissed: (direction) {
        setState(() {
          _notifications.removeWhere((item) => item['id'] == notification['id']);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification deleted')),
        );
      },
      child: GestureDetector(
        onTap: () {
          setState(() {
            notification['read'] = true;
          });
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isRead ? AppColors.white : AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: isRead ? null : Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getNotificationColor(type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  _getNotificationIcon(type),
                  color: _getNotificationColor(type),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification['title'] as String,
                            style: TextStyle(
                              fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification['message'] as String,
                      style: const TextStyle(color: AppColors.textLight, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notification['time'] as String,
                      style: TextStyle(color: AppColors.textLight.withOpacity(0.7), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Notification Settings',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSettingToggle(
                    'Match Reminders',
                    'Get notified before matches start',
                    Icons.sports_cricket,
                    AppColors.primary,
                    _matchReminders,
                    (value) {
                      setModalState(() => _matchReminders = value);
                      setState(() => _matchReminders = value);
                    },
                  ),
                  _buildSettingToggle(
                    'Contest Reminders',
                    'Reminders for contest deadlines',
                    Icons.emoji_events,
                    AppColors.success,
                    _contestReminders,
                    (value) {
                      setModalState(() => _contestReminders = value);
                      setState(() => _contestReminders = value);
                    },
                  ),
                  _buildSettingToggle(
                    'Result Notifications',
                    'Get notified when matches end',
                    Icons.flag,
                    AppColors.warning,
                    _resultReminders,
                    (value) {
                      setModalState(() => _resultReminders = value);
                      setState(() => _resultReminders = value);
                    },
                  ),
                  _buildSettingToggle(
                    'Promotional Offers',
                    'Special offers and bonuses',
                    Icons.card_giftcard,
                    AppColors.error,
                    _promotionReminders,
                    (value) {
                      setModalState(() => _promotionReminders = value);
                      setState(() => _promotionReminders = value);
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSettingToggle(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(subtitle, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
