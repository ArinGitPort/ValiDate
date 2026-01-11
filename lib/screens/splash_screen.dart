import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main_layout.dart';
import '../theme/app_theme.dart';

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
    
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive); // Removed to prevent layout issues

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

    // Navigate to Main Screen after delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        // SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge); // Removed
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainLayout()), 
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
      backgroundColor: AppTheme.white, // Clean background
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
