import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/features/profile/screens/support_screen.dart';

class FAQsScreen extends StatefulWidget {
  const FAQsScreen({super.key});

  @override
  State<FAQsScreen> createState() => _FAQsScreenState();
}

class _FAQsScreenState extends State<FAQsScreen> {
  final List<String> _expandedItems = [];

  final List<Map<String, dynamic>> _faqCategories = [
    {
      'id': 'general',
      'name': 'General',
      'icon': Icons.help_outline,
      'questions': [
        {
          'id': 'q1',
          'question': 'What is FantasyCrick?',
          'answer': 'FantasyCrick is a fantasy cricket platform where you can create virtual teams of real cricket players and earn points based on their actual performance in matches.',
        },
        {
          'id': 'q2',
          'question': 'How do I get started?',
          'answer': 'Simply sign up, create your team, join contests, and start playing! You can join free contests or paid ones to win real prizes.',
        },
        {
          'id': 'q3',
          'question': 'Is it legal to play?',
          'answer': 'Yes! Fantasy cricket is a game of skill and is legal in most Indian states. Please check your local laws before playing.',
        },
      ],
    },
    {
      'id': 'scoring',
      'name': 'Scoring & Points',
      'icon': Icons.score,
      'questions': [
        {
          'id': 'q4',
          'question': 'How are points calculated?',
          'answer': 'Points are calculated based on players\' actual performance in matches. Runs, wickets, catches, stumping, and other contributions earn points.',
        },
        {
          'id': 'q5',
          'question': 'What is captain and vice-captain?',
          'answer': 'Captain gets 2x points and vice-captain gets 1.5x points. Choose them wisely to maximize your score!',
        },
        {
          'id': 'q6',
          'question': 'When are points updated?',
          'answer': 'Points are updated in real-time during the match. Final points are confirmed after match completion.',
        },
      ],
    },
    {
      'id': 'payment',
      'name': 'Payment & Wallet',
      'icon': Icons.account_balance_wallet,
      'questions': [
        {
          'id': 'q7',
          'question': 'How do I add money to my wallet?',
          'answer': 'You can add money using UPI, credit/debit cards, net banking, or other payment methods available in the app.',
        },
        {
          'id': 'q8',
          'question': 'How do I withdraw winnings?',
          'answer': 'Go to Wallet > Withdrawal, select amount, choose payment method, and confirm. Winnings are processed within 24-48 hours.',
        },
        {
          'id': 'q9',
          'question': 'Is my money safe?',
          'answer': 'Yes! We use bank-grade security and encryption. All transactions are secure and your money is protected.',
        },
      ],
    },
    {
      'id': 'team',
      'name': 'Team & Contests',
      'icon': Icons.people,
      'questions': [
        {
          'id': 'q10',
          'question': 'How many players can I select?',
          'answer': 'You can select 11 players within a budget of 100 credits. Each player has different credit values.',
        },
        {
          'id': 'q11',
          'question': 'Can I edit my team after joining?',
          'answer': 'Yes, you can edit your team any time before the match deadline. After deadline, teams are locked.',
        },
        {
          'id': 'q12',
          'question': 'What happens if a player doesn\'t play?',
          'answer': 'If a selected player doesn\'t play, you get 0 points for that player. There\'s no substitution.',
        },
      ],
    },
  ];

  void _toggleExpand(String categoryId, String questionId) {
    final key = '$categoryId-$questionId';
    setState(() {
      if (_expandedItems.contains(key)) {
        _expandedItems.remove(key);
      } else {
        _expandedItems.add(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('FAQs', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () => _showSearchDialog()),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSearchBar(),
          const SizedBox(height: 20),
          ..._faqCategories.map((category) => _buildCategoryCard(category)),
          const SizedBox(height: 20),
          _buildContactSupport(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () => _showSearchDialog(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: AppColors.textLight.withOpacity(0.7)),
            const SizedBox(width: 12),
            Text('Search for answers...', style: TextStyle(color: AppColors.textLight.withOpacity(0.7), fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final questions = category['questions'] as List;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Icon(category['icon'] as IconData, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(category['name'] as String, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
              ],
            ),
          ),
          const Divider(height: 1),
          ...questions.map((question) => _buildQuestionItem(category['id'] as String, question as Map<String, dynamic>)),
        ],
      ),
    );
  }

  Widget _buildQuestionItem(String categoryId, Map<String, dynamic> question) {
    final key = '$categoryId-${question['id']}';
    final isExpanded = _expandedItems.contains(key);
    return Column(
      children: [
        InkWell(
          onTap: () => _toggleExpand(categoryId, question['id'] as String),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: Text(question['question'] as String, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15))),
                Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: AppColors.primary),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
              child: Text(question['answer'] as String, style: const TextStyle(color: AppColors.textLight, height: 1.5)),
            ),
          ),
          crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildContactSupport() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.support_agent, color: AppColors.white, size: 48),
          const SizedBox(height: 12),
          const Text('Still have questions?', style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Can\'t find what you\'re looking for? Our support team is here to help!', textAlign: TextAlign.center, style: TextStyle(color: AppColors.white.withOpacity(0.9))),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SupportScreen())),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.white, foregroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.chat), SizedBox(width: 8), Text('Contact Support', style: TextStyle(fontWeight: FontWeight.bold))]),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filteredQuestions = <Map<String, dynamic>>[];
            if (searchQuery.isNotEmpty) {
              for (var category in _faqCategories) {
                for (var question in category['questions'] as List) {
                  if ((question['question'] as String).toLowerCase().contains(searchQuery.toLowerCase()) ||
                      (question['answer'] as String).toLowerCase().contains(searchQuery.toLowerCase())) {
                    filteredQuestions.add({...question as Map<String, dynamic>, 'category': category['name']});
                  }
                }
              }
            }
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                padding: const EdgeInsets.all(20),
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      autofocus: true,
                      onChanged: (value) => setDialogState(() => searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Search FAQs...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (searchQuery.isEmpty) const Text('Start typing to search...', style: TextStyle(color: AppColors.textLight))
                    else if (filteredQuestions.isEmpty) const Text('No results found', style: TextStyle(color: AppColors.textLight))
                    else Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredQuestions.length,
                        itemBuilder: (context, index) {
                          final item = filteredQuestions[index];
                          return ListTile(
                            title: Text(item['question'] as String, style: const TextStyle(fontWeight: FontWeight.w500)),
                            subtitle: Text(item['category'] as String, style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                            onTap: () => Navigator.pop(context),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
