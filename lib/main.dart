import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/warranty_item.dart';
import 'providers/warranty_provider.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  // Register Adapter (generated)
  // Note: Adapter registration is handled inside WarrantyProvider.init() in my previous code? 
  // No, Provider.init() registers it but Provider needs to be created first.
  // Actually, standard practice is registering in main before opening boxes.
  // Let's modify Provider to just open box, and register adapter here.
  Hive.registerAdapter(WarrantyItemAdapter());

  runApp(const ValiDateApp());
}

class ValiDateApp extends StatelessWidget {
  const ValiDateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => WarrantyProvider()..init(), 
          // .init() opens the box.
        ),
      ],
      child: MaterialApp(
        title: 'ValiDate',
        theme: AppTheme.darkTheme, // Force dark theme as per instruction
        themeMode: ThemeMode.dark,
        home: const DashboardScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
