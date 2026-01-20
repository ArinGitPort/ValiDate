import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/warranty_provider.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize Supabase
    await Supabase.initialize(
      url: 'https://vlkawfpwyjxlcmczilad.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZsa2F3ZnB3eWp4bGNtY3ppbGFkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg4MTM2MjgsImV4cCI6MjA4NDM4OTYyOH0.vnArnJe4YrKrDEgpTZJ0KGhvg56gK1WcVWTfqOwCqpE',
    );
    
    // Initialize Notifications & Timezones
    await NotificationService().initialize();

    runApp(const ValiDateApp());
  }, (error, stack) {
    debugPrint('CRITICAL APP ERROR: $error');
    debugPrint(stack.toString());
  });
}

class ValiDateApp extends StatelessWidget {
  const ValiDateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WarrantyProvider()..init(),
      child: MaterialApp(
        title: 'ValiDate',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      ),
    );
  }
}
