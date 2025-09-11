import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class AuthService {
  // Autenticación con email y contraseña (registro)
  static Future<AuthResponse?> signUpWithEmail(String email, String password) async {
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      print('Error signing up with email: $e');
      return null;
    }
  }

  // Autenticación con email y contraseña (login)
  static Future<AuthResponse?> signInWithEmail(String email, String password) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      print('Error signing in with email: $e');
      return null;
    }
  }

  // Resetear contraseña
  static Future<bool> resetPassword(String email) async {
    try {
      await supabase.auth.resetPasswordForEmail(email);
      return true;
    } catch (e) {
      print('Error resetting password: $e');
      return false;
    }
  }

  // Cerrar sesión
  static Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Obtener usuario actual
  static User? getCurrentUser() {
    return supabase.auth.currentUser;
  }

  // Verificar si el usuario está logueado
  static bool isLoggedIn() {
    return supabase.auth.currentUser != null;
  }

  // Stream para escuchar cambios de autenticación
  static Stream<AuthState> get authStateChanges {
    return supabase.auth.onAuthStateChange;
  }
}
