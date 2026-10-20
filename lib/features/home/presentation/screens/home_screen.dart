import 'package:flutter/material.dart';
import 'package:gymgen_ai/features/dashboard/dashboard_screen.dart';

/// Compatibility entry point for older navigation references. The dashboard
/// reads current account data from the shared providers rather than demo values.
class HomeScreen extends StatelessWidget {
  static const routeName = '/legacy-home';

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const DashboardScreen();
}
