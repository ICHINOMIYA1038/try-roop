import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'router.dart';
import 'services/subscription_service.dart';

// Demo mode is controlled at build time via --dart-define=DEMO_MODE=true.
// Release builds default to false. Falls back to true at runtime only if
// Firebase initialization fails in debug builds.
bool isDemoMode = const bool.fromEnvironment('DEMO_MODE', defaultValue: false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Firebase init failed, falling back to demo mode: $e');
      isDemoMode = true;
    } else {
      rethrow;
    }
  }

  // Initialize RevenueCat (skip in demo mode)
  if (!isDemoMode) {
    try {
      await SubscriptionService.init();
    } catch (e) {
      debugPrint('RevenueCat initialization failed: $e');
    }
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'TryRoop Campus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF9F7F4),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF8A3D),
          surface: const Color(0xFFF9F7F4),
          onSurface: const Color(0xFF433D39),
          primary: const Color(0xFFFF8A3D),
          secondary: const Color(0xFFE5DCD5), // Warm beige
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF9F7F4),
          foregroundColor: Color(0xFF433D39),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Color(0xFF433D39),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: Colors.black.withOpacity(0.03),
              width: 1,
            ),
          ),
        ),
        dividerTheme: DividerThemeData(
          color: const Color(0xFF433D39).withOpacity(0.05),
          thickness: 1,
        ),
      ),
      routerConfig: router,
    );
  }
}
