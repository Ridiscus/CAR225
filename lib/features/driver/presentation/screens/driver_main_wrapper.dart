import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:car225/core/theme/app_colors.dart';
import '../providers/driver_provider.dart';
import 'driver_dashboard_screen.dart';
import 'driver_reports_screen.dart';
import 'driver_scanner_screen.dart';
import 'driver_messages_screen.dart';

class DriverMainWrapper extends StatefulWidget {
  const DriverMainWrapper({super.key});
  @override
  State<DriverMainWrapper> createState() => _DriverMainWrapperState();
}

class _DriverMainWrapperState extends State<DriverMainWrapper> {
  final List<Widget> _screens = [
    const DriverDashboardScreen(),
    const DriverScannerScreen(),
    const DriverMessagesScreen(),
    const DriverReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final driverProvider = Provider.of<DriverProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.darkBackground
        : AppColors.background;

    return Scaffold(
      backgroundColor: backgroundColor,
      // 1. On garde extendBody pour l'effet de transparence derrière la courbe
      extendBody: true, 
      body: IndexedStack(
        index: driverProvider.currentIndex,
        children: _screens,
      ),
      // 2. On enveloppe la barre dans un SafeArea pour éviter qu'elle ne soit sous le système
      bottomNavigationBar: SafeArea(
        child: CurvedNavigationBar(
          index: driverProvider.currentIndex,
          height: 60,
          items: const [
            Icon(Icons.dashboard_rounded, size: 30, color: Colors.white),
            Icon(Icons.qr_code_scanner_rounded, size: 30, color: Colors.white),
            Icon(Icons.mail_rounded, size: 30, color: Colors.white),
            Icon(Icons.warning_amber_rounded, size: 30, color: Colors.white),
          ],
          color: AppColors.primary,
          buttonBackgroundColor: AppColors.primary,
          backgroundColor: Colors.transparent, 
          animationCurve: Curves.easeInOut,
          animationDuration: const Duration(milliseconds: 300),
          onTap: (index) {
            driverProvider.setIndex(index);
          },
        ),
      ),
    );
  }
}