import 'package:flutter/material.dart';
import 'package:fantasy_crick/core/constants/app_colors.dart';
import 'package:fantasy_crick/features/splash/screens/splash_screen.dart';
import 'package:fantasy_crick/features/auth/screens/signin_screen.dart';
import 'package:fantasy_crick/features/home/screens/home_screen.dart';
import 'package:fantasy_crick/features/home/screens/series_screen.dart';
import 'package:fantasy_crick/features/home/screens/teams_screen.dart';
import 'package:fantasy_crick/features/live/screens/live_matches_screen.dart';
import 'package:fantasy_crick/features/live/screens/live_score_screen.dart';
import 'package:fantasy_crick/features/home/screens/series_detail_screen.dart';
import 'package:fantasy_crick/features/home/screens/team_players_screen.dart';
import 'package:fantasy_crick/models/series_model.dart';
import 'package:fantasy_crick/models/cricket_team_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fantasy Crick',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/signin': (context) => const SignInScreen(),
        '/home': (context) => const HomeScreen(),
        '/series': (context) => const SeriesScreen(),
        '/teams': (context) => const TeamsScreen(),
        '/live-matches': (context) => const LiveMatchesScreen(),
        '/live-scores': (context) => const LiveScoreScreen(),
      },
    );
  }
}
