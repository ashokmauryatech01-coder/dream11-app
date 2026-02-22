import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Account', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              _buildBalanceCard(),
              const SizedBox(height: 15),
              _buildWithdrawButton(),
              const SizedBox(height: 15),
              _buildRecentTransactions(),
              const SizedBox(height: 15),
              _buildKycSection(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Card(
      elevation: 3,
      shadowColor: Colors.black26,
      color: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          const SizedBox(height: 15),
          const Text('Total Balance', style: TextStyle(fontSize: 16, color: AppColors.black)),
          const SizedBox(height: 10),
          const Text('Deposited & Winnings', style: TextStyle(fontSize: 13, color: AppColors.primary)),
          const SizedBox(height: 10),
          const Text('₹ 0', style: TextStyle(fontSize: 16, color: AppColors.primary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Text('Add Balance', style: TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 15),
          const Divider(height: 1, color: AppColors.border),
          
          _buildBalanceRow('Deposited', '₹ 0', true),
          const Divider(height: 1, color: AppColors.border),
          _buildBalanceRow('Winnings', '₹ 0', true),
          const Divider(height: 1, color: AppColors.border),
          _buildBalanceRow('Bonus', '₹ 0', false),
        ],
      ),
    );
  }

  Widget _buildBalanceRow(String title, String amount, bool showEditIcon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: AppColors.text, fontSize: 14)),
          Row(
            children: [
              Text(amount, style: const TextStyle(color: AppColors.primary, fontSize: 14)),
              if (showEditIcon) ...[
                const SizedBox(width: 10),
                const Icon(Icons.info_outline, size: 16, color: AppColors.primary),
              ]
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.primary),
        borderRadius: BorderRadius.circular(25),
      ),
      child: const Text('Withdraw', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildRecentTransactions() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, spreadRadius: 1)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('My Recent Transactions', style: TextStyle(fontSize: 16, color: AppColors.primary, fontWeight: FontWeight.w500)),
          const Icon(Icons.chevron_right, color: AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildKycSection() {
    return Card(
      elevation: 3,
      color: AppColors.darkRectangle, // Reddish background
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          const SizedBox(height: 15),
          const Text('Know Your Customer', style: TextStyle(fontSize: 16, color: AppColors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Update your KYC document for withdraw amount',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.white),
            ),
          ),
          const SizedBox(height: 15),
          const Divider(height: 1, color: AppColors.white),
          
          _buildKycRow('PAN Card', 'Upload'),
          const Divider(height: 1, color: AppColors.white),
          _buildKycRow('Aadhaar Card', 'Upload'),
        ],
      ),
    );
  }

  Widget _buildKycRow(String title, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: AppColors.white, fontSize: 14)),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(action, style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.pending_actions, size: 16, color: AppColors.white), // Pending icon
            ],
          ),
        ],
      ),
    );
  }
}
