import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:urchat/screens/home_screen.dart';
import 'package:urchat/screens/auth/auth_screen.dart';
import 'package:urchat/service/api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;

  @override
  void initState() {
    super.initState();

    // 🫁 Breathing animation controller
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
      lowerBound: 0.95,
      upperBound: 1.05,
    )..repeat(reverse: true);

    _navigateNext();
  }

  Future<void> _navigateNext() async {
    // Wait 2.2s for logo animation / init
    await Future.delayed(const Duration(milliseconds: 2200));

    if (ApiService.hasStoredAuth && ApiService.isAuthenticated) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => Homescreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AuthScreen()),
      );
    }
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final minSide = screenSize.height > screenSize.width
        ? screenSize.width
        : screenSize.height;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(244, 236, 225, 1),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _breathingController,
              child: Container(
                width: minSide * 0.4,
                height: minSide * 0.4,
                child: Hero(
                  tag: "app_logo",
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      "assets/urchat_logo.png",
                      fit: BoxFit.contain,
                    ).animate().fadeIn(duration: 800.ms).scale(
                        begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            NesJumpingIconsLoadingIndicator(
              icons: [NesIcons.sword, NesIcons.shield, NesIcons.axe],
            ),
          ],
        ),
      ),
    );
  }
}
