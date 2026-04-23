import 'dart:async';
import 'package:flutter/material.dart';
import 'onboarding_screen.dart';
import '../screens/user/main_nav_screen.dart';
import '../screens/auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  final bool isLoggedIn; // Tambahkan variabel ini

  // Update Constructor untuk menerima status login
  const SplashScreen({super.key, required this.isLoggedIn});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool changeView = false;

  @override
  void initState() {
    super.initState();

    // Efek perubahan warna background setelah 2 detik
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          changeView = true;
        });
      }
    });

    // Pindah halaman setelah 4 detik
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        if (widget.isLoggedIn) {
          // Jika sudah login, langsung ke navigasi utama
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainNavScreen()),
          );
        } else {
          // Jika belum login, ke Onboarding dulu (atau LoginScreen)
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(seconds: 2),
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: changeView
                ? [
                    const Color(0xFF1565C0), // Biru agak terang
                    const Color(0xFF093FB4), // Biru utama
                  ]
                : [Colors.white, Colors.white],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(seconds: 1),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: Image.asset(
                // Pastikan path asset ini benar di folder kamu
                changeView ? 'assets/logo_white.png' : 'assets/logo_blue.png',
                key: ValueKey(changeView),
                width: 200,
              ),
            ),
            const SizedBox(height: 50),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                changeView ? Colors.white : const Color(0xFF093FB4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
