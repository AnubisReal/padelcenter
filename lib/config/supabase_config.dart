import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // TODO: Reemplaza con tus credenciales reales de Supabase
  static const String supabaseUrl = 'https://ypattzuvdjtzirgfpilf.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlwYXR0enV2ZGp0emlyZ2ZwaWxmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc1MzAzNTAsImV4cCI6MjA3MzEwNjM1MH0.x3uLZ1ymnvw36Yjb8uOvp3ooSzOrzVddY5lcwEkeU9o';

  static Future<void> initialize() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }
}

// Getter global para acceder a Supabase fácilmente
final supabase = Supabase.instance.client;
