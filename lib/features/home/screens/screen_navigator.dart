import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/features/auth/screens/otp_verification_screen.dart';
import 'package:fantasy_crick/features/auth/screens/signin_screen.dart';
import 'package:fantasy_crick/features/auth/screens/signup_screen.dart';
import 'package:fantasy_crick/features/contest/screens/choose_captain_screen.dart';
import 'package:fantasy_crick/features/contest/screens/contest_screen.dart';
import 'package:fantasy_crick/features/contest/screens/create_new_team_screen.dart';
import 'package:fantasy_crick/features/contest/screens/my_contest_screen.dart';
import 'package:fantasy_crick/features/contest/screens/my_team_screen.dart';
import 'package:fantasy_crick/features/contest/screens/player_added_screen.dart';
import 'package:fantasy_crick/features/contest/screens/player_history_screen.dart';
import 'package:fantasy_crick/features/contest/screens/player_info_screen.dart';
import 'package:fantasy_crick/features/contest/screens/player_performance_screen.dart';
import 'package:fantasy_crick/features/contest/screens/team_preview_screen1.dart';
import 'package:fantasy_crick/features/contest/screens/team_preview_screen2.dart';
import 'package:fantasy_crick/features/home/screens/home_screen.dart';
import 'package:fantasy_crick/features/matches/screens/before_match_start_screen.dart';
import 'package:fantasy_crick/features/matches/screens/match_completed_screen.dart';
import 'package:fantasy_crick/features/matches/screens/match_starts_screen.dart';
import 'package:fantasy_crick/features/matches/screens/my_matches_screen1.dart';
import 'package:fantasy_crick/features/matches/screens/my_matches_screen2.dart';
import 'package:fantasy_crick/features/matches/screens/my_matches_screen3.dart';
import 'package:fantasy_crick/features/matches/screens/on_going_match_screen.dart';
import 'package:fantasy_crick/features/profile/screens/about_us_screen.dart';
import 'package:fantasy_crick/features/profile/screens/account_screen.dart';
import 'package:fantasy_crick/features/profile/screens/faqs_screen.dart';
import 'package:fantasy_crick/features/profile/screens/language_screen.dart';
import 'package:fantasy_crick/features/profile/screens/leaderboard_screen.dart';
import 'package:fantasy_crick/features/profile/screens/my_profile_screen1.dart';
import 'package:fantasy_crick/features/profile/screens/privacy_policy_screen.dart';
import 'package:fantasy_crick/features/profile/screens/reminder_screen.dart';
import 'package:fantasy_crick/features/profile/screens/support_screen.dart';
import 'package:fantasy_crick/features/home/screens/series_screen.dart';
import 'package:fantasy_crick/features/home/screens/teams_screen.dart';
import 'package:fantasy_crick/features/live/screens/live_matches_screen.dart';
import 'package:fantasy_crick/features/home/screens/series_detail_screen.dart';
import 'package:fantasy_crick/features/home/screens/team_players_screen.dart';
import 'package:fantasy_crick/models/series_model.dart';
import 'package:fantasy_crick/models/cricket_team_model.dart';
import 'package:fantasy_crick/features/profile/screens/winning_screen.dart';
import 'package:fantasy_crick/features/splash/screens/splash_screen.dart';
import 'package:fantasy_crick/features/wallet/screens/wallet_screen.dart';

class ScreenNavigator extends StatelessWidget {
  const ScreenNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = _categories(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('FantasyCrick - All Screens', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return _CategorySection(category: category);
        },
      ),
    );
  }

  List<_Category> _categories(BuildContext context) {
    final allScreens = <_ScreenItem>[
      _ScreenItem('SplashScreen', 'Splash Screen', const SplashScreen()),
      _ScreenItem('SignInScreen', 'Sign In Screen', const SignInScreen()),
      _ScreenItem('SignUpScreen', 'Sign Up Screen', const SignUpScreen()),
      _ScreenItem('OTPVerificationScreen', 'OTP Verification Screen', const OtpVerificationScreen()),
      _ScreenItem('HomeScreen', 'Home Screen', const HomeScreen()),
      _ScreenItem('SeriesScreen', 'Series Screen', const SeriesScreen()),
      _ScreenItem('TeamsScreen', 'Teams Screen', const TeamsScreen()),
      _ScreenItem('TeamPlayersScreen', 'Team Players Screen', TeamPlayersScreen(team: CricketTeamModel(id: '1', name: 'Sample Team', shortName: 'ST', imageId: null))),
      _ScreenItem('SeriesDetailScreen', 'Series Detail Screen', SeriesDetailScreen(series: SeriesModel(id: '2', name: 'Sample Series'))),
      _ScreenItem('LiveMatchesScreen', 'Live Matches Screen', const LiveMatchesScreen()),
      _ScreenItem('ContestScreen', 'Contest Screen', const ContestScreen()),
      _ScreenItem('MyContestScreen', 'My Contest Screen', const MyContestScreen()),
      _ScreenItem('MyTeamScreen', 'My Team Screen', const MyTeamScreen()),
      _ScreenItem('WalletScreen', 'Wallet Screen', const WalletScreen()),
      _ScreenItem('AccountScreen', 'Account Screen', const AccountScreen()),
      _ScreenItem('CreateNewTeamScreen', 'Create New Team Screen', const CreateNewTeamScreen()),
      _ScreenItem('TeamPreviewScreen1', 'Team Preview Screen 1', const TeamPreviewScreen1()),
      _ScreenItem('TeamPreviewScreen2', 'Team Preview Screen 2', const TeamPreviewScreen2()),
      _ScreenItem('ChooseCaptainScreen', 'Choose Captain Screen', const ChooseCaptainScreen()),
      _ScreenItem('PlayerInfoScreen', 'Player Info Screen', const PlayerInfoScreen()),
      _ScreenItem('PlayerHistoryScreen', 'Player History Screen', const PlayerHistoryScreen()),
      _ScreenItem('PlayerAddedScreen', 'Player Added Screen', const PlayerAddedScreen()),
      _ScreenItem('PlayerPerformanceScreen', 'Player Performance Screen', const PlayerPerformanceScreen()),
      _ScreenItem('MyMatchesScreen1', 'My Matches Screen 1', const MyMatchesScreen1()),
      _ScreenItem('MyMatchesScreen2', 'My Matches Screen 2', const MyMatchesScreen2()),
      _ScreenItem('MyMatchesScreen3', 'My Matches Screen 3', const MyMatchesScreen3()),
      _ScreenItem('BeforeMatchStartScreen', 'Before Match Start Screen', const BeforeMatchStartScreen()),
      _ScreenItem('OnGoingMatchScreen', 'On Going Match Screen', const OnGoingMatchScreen()),
      _ScreenItem('MatchCompletedScreen', 'Match Completed Screen', const MatchCompletedScreen()),
      _ScreenItem('MatchStartsScreen', 'Match Starts Screen', const MatchStartsScreen()),
      _ScreenItem('MyProfileScreen1', 'My Profile Screen 1', const MyProfileScreen1()),
      _ScreenItem('LeaderboardScreen', 'Leaderboard Screen', const LeaderboardScreen()),
      _ScreenItem('WinningScreen', 'Winning Screen', const WinningScreen()),
      _ScreenItem('ReminderScreen', 'Reminder Screen', const ReminderScreen()),
      _ScreenItem('PrivacyPolicyScreen', 'Privacy Policy Screen', const PrivacyPolicyScreen()),
      _ScreenItem('AboutUsScreen', 'About Us Screen', const AboutUsScreen()),
      _ScreenItem('LanguageScreen', 'Language Screen', const LanguageScreen()),
      _ScreenItem('FAQsScreen', 'FAQs Screen', const FAQsScreen()),
      _ScreenItem('SupportScreen', 'Support Screen', const SupportScreen()),
    ];

    return [
      _Category('Authentication Screens', allScreens.sublist(0, 4)),
      _Category('Core App Screens', allScreens.sublist(4, 10)),
      _Category('Team Management Screens', allScreens.sublist(10, 14)),
      _Category('Player Screens', allScreens.sublist(14, 18)),
      _Category('Match Screens', allScreens.sublist(18, 26)),
      _Category('Profile & Utility Screens', allScreens.sublist(26)),
    ];
  }
}

class _CategorySection extends StatelessWidget {
  final _Category category;

  const _CategorySection({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 6),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.primary, width: 2)),
            ),
            child: Text(
              category.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text),
            ),
          ),
          const SizedBox(height: 10),
          ...category.screens.map((screen) {
            return InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => screen.widget),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        screen.title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text),
                      ),
                    ),
                    Text(
                      screen.name,
                      style: const TextStyle(fontSize: 11, color: AppColors.textLight, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _Category {
  final String title;
  final List<_ScreenItem> screens;

  const _Category(this.title, this.screens);
}

class _ScreenItem {
  final String name;
  final String title;
  final Widget widget;

  const _ScreenItem(this.name, this.title, this.widget);
}
