import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/inventory_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/database_service.dart';
import 'theme/app_theme.dart';
import 'screens/pin_lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Initialize Hive database
  await DatabaseService.initialize();

  runApp(const BoxviseApp());
}

class BoxviseApp extends StatelessWidget {
  const BoxviseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InventoryProvider()..loadBoxes(),
      child: Consumer<InventoryProvider>(
        builder: (context, provider, _) {
          return MaterialApp(
            title: 'Boxvise - Smart Inventory',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.getLightTheme(provider.primaryColor),
            darkTheme: AppTheme.getDarkTheme(provider.primaryColor),
            themeMode: provider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: provider.showOnboarding 
                ? const OnboardingScreen() 
                : const PinLockScreen(child: DashboardScreen()),
          );
        },
      ),
    );
  }
}
