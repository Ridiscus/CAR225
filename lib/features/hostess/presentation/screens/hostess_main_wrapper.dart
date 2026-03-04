import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:car225/core/theme/app_colors.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'hostess_home_screen.dart';
import 'hostess_search_screen.dart';
import 'hostess_scanner_screen.dart';
import 'hostess_history_screen.dart';
import 'hostess_profile_screen.dart';

class HostessMainWrapper extends StatefulWidget {
  const HostessMainWrapper({super.key});
  @override
  State<HostessMainWrapper> createState() => HostessMainWrapperState();
}

class HostessMainWrapperState extends State<HostessMainWrapper> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HostessHomeScreen(),
    const HostessSearchScreen(),
    const HostessScannerScreen(),
    const HostessHistoryScreen(),
    const HostessProfileScreen(),
  ];

  void setIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.black : const Color(0xFFF5F5F7);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: backgroundColor,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        extendBody: true,
        backgroundColor: backgroundColor,
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: SafeArea(
          top: false,
          child: CurvedNavigationBar(
            index: _currentIndex,
            height: 70,
            color: AppColors.primary,
            buttonBackgroundColor: AppColors.primary,
            backgroundColor: Colors.transparent,
            animationCurve: Curves.easeInOutCubic,
            animationDuration: const Duration(milliseconds: 400),
            items: const <Widget>[
              Icon(Icons.dashboard_rounded, color: Colors.white, size: 28),
              Icon(
                Icons.confirmation_number_rounded,
                color: Colors.white,
                size: 28,
              ),
              Icon(
                Icons.qr_code_scanner_rounded,
                color: Colors.white,
                size: 28,
              ),
              Icon(Icons.history_rounded, color: Colors.white, size: 28),
              Icon(Icons.person_rounded, color: Colors.white, size: 28),
            ],
            onTap: (index) {
              HapticFeedback.mediumImpact();
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ),
      ),
    );
  }
}
