import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/warranty_item.dart';
import 'models/activity_log.dart';
import 'providers/warranty_provider.dart';
import 'theme/app_theme.dart';
import 'screens/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  // Register Adapters
  Hive.registerAdapter(WarrantyItemAdapter());
  Hive.registerAdapter(ActivityLogAdapter());

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
        theme: AppTheme.lightTheme,
        themeMode: ThemeMode.light,
        home: const MainLayout(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
