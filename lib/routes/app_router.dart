import 'package:flutter/material.dart';

import 'package:gymgen_ai/features/auth/presentation/screens/splash_screen.dart';
import 'package:gymgen_ai/features/auth/presentation/screens/login_screen.dart';
import 'package:gymgen_ai/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:gymgen_ai/features/auth/presentation/screens/signup_screen.dart';
import 'package:gymgen_ai/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:gymgen_ai/features/home/presentation/screens/home_tab.dart'; // Was home_screen
import 'package:gymgen_ai/features/assessment/presentation/screens/assessment_screen.dart';
import 'package:gymgen_ai/features/assessment/presentation/screens/assessment_history_screen.dart';
import 'package:gymgen_ai/features/dashboard/dashboard_screen.dart';
import 'package:gymgen_ai/features/workout/presentation/screens/workout_screen.dart';
import 'package:gymgen_ai/features/workout/presentation/screens/workout_execution_screen.dart';
import 'package:gymgen_ai/features/nutrition/presentation/screens/nutrition_screen.dart';
import 'package:gymgen_ai/features/coach/presentation/screens/coach_screen.dart';
import 'package:gymgen_ai/features/progress/presentation/screens/progress_screen.dart';
import 'package:gymgen_ai/features/profile/presentation/screens/profile_screen.dart';
import 'package:gymgen_ai/features/settings/presentation/screens/settings_screen.dart';

class AppRouter {
  static Route<dynamic> generate(RouteSettings settings) {
    switch (settings.name) {
      case SplashScreen.routeName:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case OnboardingScreen.routeName:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());

      case LoginScreen.routeName:
        final email = settings.arguments is String
            ? settings.arguments! as String
            : '';
        return MaterialPageRoute(
          builder: (_) => LoginScreen(initialEmail: email),
        );

      case SignupScreen.routeName:
        final email = settings.arguments is String
            ? settings.arguments! as String
            : '';
        return MaterialPageRoute(
          builder: (_) => SignupScreen(initialEmail: email),
        );

      case ForgotPasswordScreen.routeName:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());

      case HomeTab.routeName: // previously HomeScreen
        return MaterialPageRoute(builder: (_) => const HomeTab());

      case AssessmentScreen.routeName:
        return MaterialPageRoute(builder: (_) => const AssessmentScreen());

      case AssessmentHistoryScreen.routeName:
        return MaterialPageRoute(builder: (_) => const AssessmentHistoryScreen());

      case DashboardScreen.routeName:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());

      case WorkoutScreen.routeName:
        return MaterialPageRoute(builder: (_) => const WorkoutScreen());

      case WorkoutExecutionScreen.routeName:
        return MaterialPageRoute(builder: (_) => const WorkoutExecutionScreen());

      case NutritionScreen.routeName:
        return MaterialPageRoute(builder: (_) => const NutritionScreen());

      case CoachScreen.routeName:
        return MaterialPageRoute(builder: (_) => const CoachScreen());

      case ProgressScreen.routeName:
        return MaterialPageRoute(builder: (_) => const ProgressScreen());

      case ProfileScreen.routeName:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());

      case SettingsScreen.routeName:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());

      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}
