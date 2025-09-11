import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../config/supabase_config.dart';

class ProfileService {
  // Obtener perfil del usuario actual
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return null;

      final response = await supabase
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Crear o actualizar perfil del usuario
  static Future<bool> updateUserProfile({
    required String displayName,
    String? avatarUrl,
    String? sideOfPlay,
    String? playStyle,
    String? level,
    String? paddle,
    String? club,
    String? phone,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      final profileData = {
        'id': user.id,
        'email': user.email,
        'display_name': displayName,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Solo agregar campos que no sean null
      if (avatarUrl != null) profileData['avatar_url'] = avatarUrl;
      if (sideOfPlay != null) profileData['side_of_play'] = sideOfPlay;
      if (playStyle != null) profileData['play_style'] = playStyle;
      if (level != null) profileData['level'] = level;
      if (paddle != null) profileData['paddle'] = paddle;
      if (club != null) profileData['club'] = club;
      if (phone != null) profileData['phone'] = phone;

      await supabase.from('profiles').upsert(profileData);

      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  // Subir imagen de avatar
  static Future<String?> uploadAvatar(String imagePath) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return null;

      // Estructura de carpeta: user_id/filename.jpg
      final fileName = '${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await supabase.storage
          .from('avatars')
          .upload(fileName, File(imagePath));

      final publicUrl = supabase.storage
          .from('avatars')
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      print('Error uploading avatar: $e');
      return null;
    }
  }
}
