import 'package:attendee/pages/admin_salary_page.dart';
import 'package:attendee/pages/admin_statistics_page.dart';
import 'package:attendee/pages/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'admin_home_page.dart';

class AdminDashboard extends StatefulWidget {
  final Map<String, dynamic> user;
  const AdminDashboard({required this.user, super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late final Map<String, dynamic> user;
  late List<Widget> screens;
  int index = 0;

  @override
  void initState() {
    super.initState();
    user = widget.user;
    screens = [
      AdminHomePage(user: user),
      const AdminStatisticsPage(),
      const AdminSalaryPage(),
      SettingPage(user: user),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.light;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: isDark ? const Color(0xFF161B22) : Colors.white,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    ));

    return SafeArea(
      child: Scaffold(
        body: screens[index],
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => setState(() => index = i),
          height: 65,
          backgroundColor: isDark ? Colors.white : const Color(0xFF161B22),
          indicatorColor: const Color(0xFF4361EE).withOpacity(0.15),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon:
                  Icon(Icons.home_rounded, color: Color(0xFF4361EE)),
              label: 'Trang chủ',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon:
                  Icon(Icons.bar_chart_rounded, color: Color(0xFF4361EE)),
              label: 'Thống kê',
            ),
            NavigationDestination(
              icon: Icon(Icons.payments_outlined),
              selectedIcon:
                  Icon(Icons.payments_rounded, color: Color(0xFF4361EE)),
              label: 'Lương',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon:
                  Icon(Icons.settings_rounded, color: Color(0xFF4361EE)),
              label: 'Cài đặt',
            ),
          ],
        ),
      ),
    );
  }
}