import 'package:flutter/material.dart';
import 'package:gymgen_ai/core/widgets/galaxy_background.dart';

class GalaxyScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  const GalaxyScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Let the galaxy show through
      extendBody: true,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: Stack(
        children: [
          // 1. The animated background
          const Positioned.fill(
            child: GalaxyBackground(),
          ),
          // 2. Your actual screen content
          Positioned.fill(
            child: body,
          ),
        ],
      ),
    );
  }
}