import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:creditcarddiary/l10n/app_localizations.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'line_chart_screen.dart';
import 'fixed_cost_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const FixedCostScreen(),
    const LineChartScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      extendBody: false,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: Container(
          key: ValueKey<int>(_currentIndex),
          child: _screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(top: BorderSide(color: colorScheme.outline, width: 1)),
        ),
        child: SafeArea(
          child: Theme(
            data: Theme.of(context).copyWith(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                iconSize: 24.0,
                selectedFontSize: 14.0,
                unselectedFontSize: 14.0, // Consistent font size
                selectedItemColor: colorScheme.primary,
                unselectedItemColor: colorScheme.onSurface.withValues(
                  alpha: 0.6,
                ),
                showSelectedLabels: true,
                showUnselectedLabels: true,
                elevation: 0,
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(CupertinoIcons.house),
                    activeIcon: const Icon(CupertinoIcons.house_fill),
                    label: l10n.home,
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.repeat),
                    label: '固定費',
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(CupertinoIcons.graph_square),
                    label: '推移',
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(CupertinoIcons.settings),
                    activeIcon: const Icon(CupertinoIcons.settings_solid),
                    label: l10n.settings,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
