import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/features/profile/screens/account_screen.dart';

class MyProfileScreen extends StatelessWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 10),
            _buildPlayingHistory(),
            _buildSection(
              icon: Icons.emoji_events,
              title: 'Global Ranking',
              subtitle: 'Join Contest to see your rank',
              actionTitle: 'View your global ranking',
            ),
            _buildSection(
              icon: Icons.group,
              title: 'Friends',
              subtitle: 'The more friends you invite...',
              actionTitle: 'Invite Friends',
              onTapAction: () {},
            ),
            _buildWallet(context),
            _buildPersonalDetails(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: AppColors.background,
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 2),
              color: AppColors.white,
            ),
            child: const Icon(Icons.person, size: 60, color: AppColors.textLight),
          ),
          const SizedBox(height: 10),
          const Text('Your Username', style: TextStyle(fontSize: 18, color: AppColors.text, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          const Text('Location', style: TextStyle(fontSize: 14, color: AppColors.warning)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPlayingHistory() {
    return Container(
      color: AppColors.teamHeader, // Dark header
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          const Text('Playing History', style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildHistoryCard(Icons.sports_cricket, '0', 'Contest')),
              const SizedBox(width: 10),
              Expanded(child: _buildHistoryCard(Icons.sports, '0', 'Match')),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildHistoryCard(Icons.emoji_events, '0', 'Series')), // hidden in android but putting it here
              const SizedBox(width: 10),
              Expanded(child: _buildHistoryCard(Icons.workspace_premium, '0', 'Wins')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(IconData icon, String value, String title) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: AppColors.darkRectangle, // Reddish solid background
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Icon(icon, color: AppColors.white, size: 30),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, style: const TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.bold)),
              Text(title, style: const TextStyle(color: AppColors.white, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required IconData icon, required String title, required String subtitle, required String actionTitle, VoidCallback? onTapAction}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkRectangle,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Icon(icon, size: 40, color: AppColors.white),
              const SizedBox(height: 5),
              Text(title, style: const TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          Container(
            height: 60,
            width: 1,
            color: AppColors.border,
            margin: const EdgeInsets.symmetric(horizontal: 15),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(actionTitle, style: const TextStyle(color: AppColors.text, fontSize: 14)),
                const SizedBox(height: 5),
                Text(subtitle, style: const TextStyle(color: AppColors.white, fontSize: 13)),
                if (onTapAction != null) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: onTapAction,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.white),
                      ),
                      child: const Text('Invite Friends', style: TextStyle(color: AppColors.white, fontSize: 12)),
                    ),
                  )
                ]
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildWallet(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white, // Actually using white here based on my_profile_screen.dart looking like activity_my_account
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Wallet', style: TextStyle(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.bold)),
                InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountScreen()));
                  },
                  child: const Icon(Icons.chevron_right, color: AppColors.primary),
                )
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.primary),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildWalletItem('₹ 0', 'Deposited', AppColors.primary),
                _buildWalletItem('₹ 0', 'Winnings', AppColors.primary),
                _buildWalletItem('₹ 0', 'Bonus', AppColors.textLight),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Add Balance', style: TextStyle(color: AppColors.white, fontSize: 10)),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildWalletItem(String amount, String title, Color titleColor) {
    return Column(
      children: [
        Text(amount, style: const TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(title, style: TextStyle(color: titleColor, fontSize: 11)),
      ],
    );
  }

  Widget _buildPersonalDetails(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Personal Details', style: TextStyle(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.bold)),
              Icon(Icons.edit, color: AppColors.primary, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.primary),
          const SizedBox(height: 15),
          const Text('yourmail@gmail.com', style: TextStyle(color: AppColors.text, fontSize: 15)),
          const SizedBox(height: 15),
          Row(
            children: [
              Icon(Icons.lock, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                child: const Text('Change Password', style: TextStyle(color: AppColors.white, fontSize: 12)),
              )
            ],
          ),
          const SizedBox(height: 15),
          InkWell(
            onTap: () {
               // Logout
            },
            child: Row(
              children: [
                Icon(Icons.logout, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                const Text('Logout', style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
