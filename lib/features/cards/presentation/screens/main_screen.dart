import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
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
          // iOS標準のイージング曲線を使用
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curvedAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.1, 0),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            ),
          );
        },
        child: IndexedStack(
          key: ValueKey(_currentIndex),
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            top: BorderSide(color: colorScheme.outline, width: 0.5),
          ),
        ),
        child: SafeArea(
          child: Theme(
            data: Theme.of(context).copyWith(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                currentIndex: _currentIndex,
                onTap: (index) {
                  if (_currentIndex != index) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _currentIndex = index;
                    });
                  }
                },
                iconSize: 28.0,
                selectedFontSize: 10.0,
                unselectedFontSize: 10.0,
                selectedItemColor: colorScheme.primary,
                unselectedItemColor: colorScheme.onSurface.withValues(
                  alpha: 0.4,
                ),
                showSelectedLabels: true,
                showUnselectedLabels: true,
                elevation: 0,
                items: [
                  BottomNavigationBarItem(
                    icon: Container(
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(CupertinoIcons.house),
                    ),
                    activeIcon: Container(
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(CupertinoIcons.house_fill),
                    ),
                    label: l10n.home,
                  ),
                  BottomNavigationBarItem(
                    icon: Container(
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(CupertinoIcons.repeat),
                    ),
                    activeIcon: Container(
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(CupertinoIcons.repeat),
                    ),
                    label: '固定費',
                  ),
                  BottomNavigationBarItem(
                    icon: Container(
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(CupertinoIcons.graph_square),
                    ),
                    activeIcon: Container(
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(CupertinoIcons.graph_square_fill),
                    ),
                    label: '推移',
                  ),
                  BottomNavigationBarItem(
                    icon: Container(
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(CupertinoIcons.settings),
                    ),
                    activeIcon: Container(
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(CupertinoIcons.settings_solid),
                    ),
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
