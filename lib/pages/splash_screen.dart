import 'package:attendee/auth/supabase_auth.dart';
import 'package:attendee/pages/login_page.dart';
import 'package:attendee/pages/user_main_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'admin_dashboard.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _setSystemUI();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    _navigateToLoginPage();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  void _navigateToLoginPage() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final bool isLoggedIn = await OauthHelper.isUserLoggedIn();

    late final Widget destination;

    if (!isLoggedIn) {
      destination = const LoginPage();
    } else {
      final currUser = await OauthHelper.getCurrentUser();

      final permissions =
          (currUser['permissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
              [];

      final isManager = permissions.any(
            (p) => p == 'cbnv/manageall' || p == 'cbnv/update',
      );

      if (isManager) {
        destination = AdminDashboard(user: currUser);
      } else {
        destination = UserMainPage(user: currUser);
      }
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          /// Background Image
          Image.asset(
            'assets/images/splash_gradient.png',
            fit: BoxFit.cover,
          ),

          /// Dark Overlay
          Container(
            color: Colors.black.withOpacity(0.15),
          ),

          /// Content
          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      /// Logo
                      Container(
                        width: 180,
                        height: 180,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      /// Loading
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.8,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}