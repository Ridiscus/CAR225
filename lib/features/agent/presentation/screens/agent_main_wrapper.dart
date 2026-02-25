import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../../../../core/theme/app_colors.dart';
import 'agent_home_screen.dart';
import 'agent_history_screen.dart';
import 'agent_profile_screen.dart';
import 'ticket_scanner_screen.dart';
import 'ticket_search_screen.dart';

class AgentMainWrapper extends StatefulWidget {
  const AgentMainWrapper({super.key});
  @override
  State<AgentMainWrapper> createState() => AgentMainWrapperState();
}

class AgentMainWrapperState extends State<AgentMainWrapper> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const AgentHomeScreen(),
    const TicketSearchScreen(),
    const TicketScannerScreen(),
    const AgentHistoryScreen(),
    const AgentProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
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
          bottom: Platform.isAndroid ? true : false,
          child: CurvedNavigationBar(
            index: _currentIndex,
            height: 70,
            color: AppColors.primary,
            buttonBackgroundColor: AppColors.primary,
            backgroundColor: Colors.transparent,
            animationCurve: Curves.easeInOutCubic,
            animationDuration: const Duration(milliseconds: 400),
            items: <Widget>[
              _buildNavItem(iconData: "assets/icons/home.png", index: 0),
              _buildNavItem(iconData: Icons.search_rounded, index: 1),
              _buildNavItem(
                iconData: Icons.qr_code_scanner_rounded,
                index: 2,
                isScanner: true,
              ),
              _buildNavItem(iconData: "assets/icons/time_alert.png", index: 3),
              _buildNavItem(iconData: "assets/icons/account.png", index: 4),
            ],
            onTap: setIndex,
          ),
        ),
      ),
    );
  }

  void setIndex(int index) {
    if (index != _currentIndex) {
      HapticFeedback.mediumImpact();
      // Nettoyer rapidement le SnackBar actuel lors du changement d'onglet
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      setState(() {
        _currentIndex = index;
      });
    }
  }

  Widget _buildNavItem({
    required dynamic iconData,
    required int index,
    bool isScanner = false,
  }) {
    final bool isSelected = _currentIndex == index;

    // Pour le scanner central
    if (isScanner) {
      return Container(
        padding: EdgeInsets.all(isSelected ? 10 : 0),
        decoration: isSelected
            ? const BoxDecoration(color: Colors.white, shape: BoxShape.circle)
            : null,
        child: Icon(
          iconData as IconData,
          color: isSelected ? AppColors.primary : Colors.white,
          size: isSelected ? 30 : 28,
        ),
      );
    }

    // Pour les autres icônes
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: isSelected
          ? const BoxDecoration(color: Colors.white, shape: BoxShape.circle)
          : null,
      child: iconData is String
          ? Image.asset(
              iconData,
              color: isSelected ? AppColors.primary : Colors.white,
              width: 22,
              height: 22,
              fit: BoxFit.contain,
            )
          : Icon(
              iconData as IconData,
              color: isSelected ? AppColors.primary : Colors.white,
              size: 24,
            ),
    );
  }
}
