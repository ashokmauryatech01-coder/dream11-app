import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/core/services/profile_service.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _walletData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await ProfileService.getCompleteUserProfile();
      final wallet = await ProfileService.getUserWallets(0); // Will use saved user ID
      
      setState(() {
        _userProfile = profile;
        _walletData = wallet;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user profile: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    await _loadUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        title: const Text('User Profile'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header Card
                  _buildProfileHeader(),
                  const SizedBox(height: 20),
                  
                  // Personal Information Card
                  _buildPersonalInfoCard(),
                  const SizedBox(height: 20),
                  
                  // Wallet Information Card
                  _buildWalletInfoCard(),
                  const SizedBox(height: 20),
                  
                  // UPI Information Card
                  _buildUPIInfoCard(),
                  const SizedBox(height: 20),
                  
                  // Account Statistics Card
                  _buildStatsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: 3),
            ),
            child: Center(
              child: Text(
                _userProfile?['full_name']?.toString().isNotEmpty == true
                    ? _userProfile!['full_name'].toString()[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Name and Email
          Text(
            _userProfile?['full_name']?.toString() ?? 'User Name',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            _userProfile?['email']?.toString() ?? 'user@example.com',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return _buildInfoCard(
      title: 'Personal Information',
      icon: Icons.person,
      children: [
        _buildInfoRow('Full Name', _userProfile?['full_name']?.toString() ?? 'N/A'),
        _buildInfoRow('Email', _userProfile?['email']?.toString() ?? 'N/A'),
        _buildInfoRow('Phone', _userProfile?['phone']?.toString() ?? 'N/A'),
        _buildInfoRow('Member Since', _formatDate(_userProfile?['created_at'])),
      ],
    );
  }

  Widget _buildWalletInfoCard() {
    return _buildInfoCard(
      title: 'Wallet Information',
      icon: Icons.account_balance_wallet,
      children: [
        _buildInfoRow(
          'Current Balance',
          '₹${(_walletData?['balance'] ?? 0.0).toStringAsFixed(2)}',
          valueStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        _buildInfoRow('Total Added', '₹${(_walletData?['total_added'] ?? 0.0).toStringAsFixed(2)}'),
        _buildInfoRow('Total Withdrawn', '₹${(_walletData?['total_withdrawn'] ?? 0.0).toStringAsFixed(2)}'),
        _buildInfoRow('Last Transaction', _formatDate(_walletData?['last_transaction_date'])),
        _buildInfoRow(
          'Transactions',
          'View History',
          isButton: true,
          onTap: () {
            Navigator.pushNamed(context, '/wallet-transactions');
          },
        ),
        _buildInfoRow(
          'Withdraw',
          'Withdraw Funds',
          isButton: true,
          onTap: () {
            Navigator.pushNamed(context, '/withdrawal');
          },
        ),
      ],
    );
  }

  Widget _buildUPIInfoCard() {
    return _buildInfoCard(
      title: 'UPI Information',
      icon: Icons.account_balance_wallet_rounded,
      children: [
        _buildInfoRow('UPI ID', _userProfile?['upi_id']?.toString() ?? 'Not Set'),
        _buildInfoRow('Status', _userProfile?['upi_id']?.toString().isNotEmpty == true ? 'Verified' : 'Not Verified'),
      ],
    );
  }

  Widget _buildStatsCard() {
    return _buildInfoCard(
      title: 'Account Statistics',
      icon: Icons.analytics,
      children: [
        _buildInfoRow('Total Matches', _userProfile?['total_matches']?.toString() ?? '0'),
        _buildInfoRow('Total Wins', _userProfile?['total_wins']?.toString() ?? '0'),
        _buildInfoRow('Win Rate', '${((_userProfile?['win_rate'] ?? 0.0) * 100).toStringAsFixed(1)}%'),
        _buildInfoRow('Total Earnings', '₹${(_userProfile?['total_earnings'] ?? 0.0).toStringAsFixed(2)}'),
      ],
    );
  }

  Widget _buildInfoCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {TextStyle? valueStyle, bool isButton = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textLight,
            ),
          ),
          Flexible(
            child: isButton
                ? GestureDetector(
                    onTap: onTap,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  )
                : Text(
                    value,
                    style: valueStyle ?? const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.text,
                    ),
                    textAlign: TextAlign.right,
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(date.toString());
      return '${dateTime.day}-${dateTime.month}-${dateTime.year}';
    } catch (e) {
      return 'N/A';
    }
  }
}
