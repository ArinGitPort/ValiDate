import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'main_layout.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1, milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    // Navigate based on auth state after delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        final user = Supabase.instance.client.auth.currentUser;
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => user != null ? const MainLayout() : const LoginScreen(),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFCFC), // Requested custom white
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Ensure it shrinks to fit content
          children: [
            // Icon
            ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SizedBox(
                   width: 120,
                   height: 120,
                   child: Image.asset(
                     'assets/images/validate_icon.png',
                     errorBuilder: (context, error, stackTrace) {
                       debugPrint("Error loading icon: $error");
                       return const Icon(Icons.broken_image, size: 60, color: Colors.grey);
                     },
                   ),
                ),
              ),
            ),
            const SizedBox(height: 48),
            // Title
            FadeTransition(
              opacity: _fadeAnimation,
              child: SizedBox(
                width: 180,
                child: Image.asset(
                  'assets/images/validate_title.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                     debugPrint("Error loading title: $error");
                     return const Text("ValiDate", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold));
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
