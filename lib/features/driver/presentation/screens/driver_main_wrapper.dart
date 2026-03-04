import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/driver_provider.dart';
import 'driver_dashboard_screen.dart';
import 'driver_trips_screen.dart';
import 'driver_history_screen.dart';
import 'driver_reports_screen.dart';
import 'driver_profile_screen.dart';

class DriverMainWrapper extends StatefulWidget {
  const DriverMainWrapper({super.key});
  @override
  State<DriverMainWrapper> createState() => _DriverMainWrapperState();
}

class _DriverMainWrapperState extends State<DriverMainWrapper> {
  final List<Widget> _screens = [
    const DriverDashboardScreen(),
    const DriverTripsScreen(),
    const DriverHistoryScreen(),
    const DriverReportsScreen(),
    const DriverProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final driverProvider = Provider.of<DriverProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.darkBackground
        : AppColors.background;

    return Scaffold(
      extendBody: true,
      backgroundColor: backgroundColor,
      body: IndexedStack(
        index: driverProvider.currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        bottom: Platform.isAndroid ? true : false,
        child: CurvedNavigationBar(
          index: driverProvider.currentIndex,
          height: 65.0,
          color: AppColors.primary,
          buttonBackgroundColor: AppColors.primary,
          backgroundColor: Colors.transparent,
          animationCurve: Curves.easeInOut,
          animationDuration: const Duration(milliseconds: 400),
          items: const <Widget>[
            Icon(Icons.dashboard_outlined, color: Colors.white),
            Icon(Icons.directions_bus_outlined, color: Colors.white),
            Icon(Icons.history, color: Colors.white),
            Icon(Icons.report_problem_outlined, color: Colors.white),
            Icon(Icons.person_outline, color: Colors.white),
          ],
          onTap: (index) {
            driverProvider.setIndex(index);
          },
        ),
      ),
    );
  }
}
