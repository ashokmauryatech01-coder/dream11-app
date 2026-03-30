  import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/common/widgets/beauty_dialog.dart';
import 'package:fantasy_crick/core/services/profile_service.dart';
import 'package:fantasy_crick/features/wallet/screens/add_cash_screen.dart';
import 'package:fantasy_crick/features/wallet/screens/withdrawal_screen.dart';
import 'package:fantasy_crick/common/widgets/cricket_animation.dart';
import 'package:fantasy_crick/common/widgets/dashboard_animation.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  double _balance = 0.0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBalance();
    _loadTransactions();
  }

  Future<void> _loadBalance() async {
    setState(() => _isLoading = true);
    try {
      final balance = await ProfileService.getWalletBalance();
      setState(() {
        _balance = balance ?? 0.0;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading balance: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTransactions() async {
    if (_isLoadingHistory) return;
    setState(() => _isLoadingHistory = true);
    try {
      final history = await ProfileService.getTransactionHistory(limit: 20);
      setState(() {
        _transactions = history;
        _isLoadingHistory = false;
      });
    } catch (e) {
      print('Error loading transactions: $e');
      setState(() => _isLoadingHistory = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Wallet', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textLight,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Balance'),
            Tab(text: 'Transactions'),
            Tab(text: 'Withdrawal'),
          ],
        ),
      ),
      body: DashboardAnimation(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildBalanceTab(),
            _buildTransactionsTab(),
            _buildWithdrawalTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Balance',
                        style: TextStyle(color: AppColors.white.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isLoading ? '...' : '₹${_balance.toStringAsFixed(0)}',
                        style: const TextStyle(color: AppColors.white, fontSize: 36, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const Center(
                  child: CricketAnimation(
                    type: AnimationType.coin,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildBalanceItem('Winnings', '₹3,456', Icons.emoji_events, AppColors.success),
          _buildBalanceItem('Bonus', '₹1,000', Icons.card_giftcard, AppColors.warning),
          _buildBalanceItem('Deposited', '₹778', Icons.account_balance_wallet, AppColors.primary),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildActionButton('ADD MONEY', Icons.add_rounded, () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddCashScreen()),
                );
                _loadBalance();
              })),
              const SizedBox(width: 15),
              Expanded(child: _buildActionButton('WITHDRAW', Icons.file_download_outlined, () async {
                 await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WithdrawalScreen()),
                );
                _loadBalance();
              })),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(String label, String amount, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 14)),
          ),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.text)),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.white, size: 20),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
        ],
      ),
    );
  }


  void _showWithdrawDialog() {
    BeautyDialog.show(
      context,
      title: 'Withdraw Initiated',
      message: 'Your withdrawal request has been submitted. Processing time: 24-48 hours.',
      type: BeautyDialogType.success,
    );
  }

  Widget _buildTransactionsTab() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 64, color: AppColors.textLight.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text('No transactions yet', style: TextStyle(color: AppColors.textLight)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTransactions,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _transactions.length,
        itemBuilder: (context, index) {
          final item = _transactions[index];
          final type = (item['type'] ?? '').toString().toLowerCase();
          final String title = type.toUpperCase();
          final String desc = item['description'] ?? 'Transaction';
          final double amt = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
          final String date = item['created_at'] ?? '';
          final bool isCredit = type == 'deposit' || type == 'winning' || type == 'refund' || type == 'referral';
          
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (isCredit ? AppColors.success : AppColors.error).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isCredit ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded,
                    color: isCredit ? AppColors.success : AppColors.error,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text(desc, style: const TextStyle(color: AppColors.text, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(date, style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
                    ],
                  ),
                ),
                Text(
                  '${isCredit ? "+" : "-"}₹${amt.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: isCredit ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWithdrawalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Withdraw Winnings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Text('Available for withdrawal: ₹3,456', style: TextStyle(color: AppColors.textLight)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildWithdrawMethod('Bank Transfer', Icons.account_balance),
                    _buildWithdrawMethod('UPI', Icons.phone_android),
                    _buildWithdrawMethod('Paytm', Icons.account_balance_wallet),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _showWithdrawDialog(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Proceed to Withdraw', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Withdrawal Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                Text('• Minimum withdrawal: ₹100', style: TextStyle(color: AppColors.textLight)),
                Text('• Processing time: 24-48 hours', style: TextStyle(color: AppColors.textLight)),
                Text('• No withdrawal fees', style: TextStyle(color: AppColors.textLight)),
                Text('• KYC verification required', style: TextStyle(color: AppColors.textLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawMethod(String name, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: AppColors.primary),
        const SizedBox(height: 8),
        Text(name, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
