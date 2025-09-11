import 'package:flutter/material.dart';
import '../screens/main_screen.dart';
import '../screens/email_login_screen.dart';
import '../services/auth_service.dart';

class PadelCenterApp extends StatelessWidget {
  const PadelCenterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Padel Center',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        fontFamily: 'MonumentExtended',
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontFamily: 'MonumentExtended',
            fontWeight: FontWeight.w800,
          ),
          displayMedium: TextStyle(
            fontFamily: 'MonumentExtended',
            fontWeight: FontWeight.w800,
          ),
          displaySmall: TextStyle(
            fontFamily: 'MonumentExtended',
            fontWeight: FontWeight.w800,
          ),
          headlineLarge: TextStyle(
            fontFamily: 'MonumentExtended',
            fontWeight: FontWeight.w800,
          ),
          headlineMedium: TextStyle(
            fontFamily: 'MonumentExtended',
            fontWeight: FontWeight.w800,
          ),
          headlineSmall: TextStyle(
            fontFamily: 'MonumentExtended',
            fontWeight: FontWeight.w400,
          ),
          titleLarge: TextStyle(
            fontFamily: 'MonumentExtended',
            fontWeight: FontWeight.w800,
          ),
          titleMedium: TextStyle(
            fontFamily: 'MonumentExtended',
            fontWeight: FontWeight.w400,
          ),
          titleSmall: TextStyle(
            fontFamily: 'MonumentExtended',
            fontWeight: FontWeight.w400,
          ),
          bodyLarge: TextStyle(
            fontFamily: 'MonumentExtended',
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'MonumentExtended',
            fontWeight: FontWeight.w400,
          ),
          bodySmall: TextStyle(
            fontFamily: 'MonumentExtended',
            fontWeight: FontWeight.w400,
          ),
          labelLarge: TextStyle(
            fontFamily: 'MonumentExtended',
            fontWeight: FontWeight.w400,
          ),
          labelMedium: TextStyle(
            fontFamily: 'MonumentExtended',
            fontWeight: FontWeight.w400,
          ),
          labelSmall: TextStyle(
            fontFamily: 'MonumentExtended',
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      home: StreamBuilder(
        stream: AuthService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          final isLoggedIn = AuthService.isLoggedIn();
          return isLoggedIn ? const MainScreen() : const EmailLoginScreen();
        },
      ),
    );
  }
}
