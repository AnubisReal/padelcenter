import 'package:supabase_flutter/supabase_flutter.dart';

class MatchService {
  static final _supabase = Supabase.instance.client;

  // Create a new match
  static Future<String?> createMatch({
    required String courtNumber,
    required String skillLevel,
    required String startTime,
    String status = 'abierto',
  }) async {
    try {
      final response = await _supabase
          .from('matches')
          .insert({
            'court_number': courtNumber,
            'skill_level': skillLevel,
            'start_time': startTime,
            'status': status,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      return response['id'];
    } catch (e) {
      print('Error creating match: $e');
      return null;
    }
  }

  // Get all matches
  static Future<List<Map<String, dynamic>>> getMatches() async {
    try {
      final response = await _supabase
          .from('matches')
          .select('*')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching matches: $e');
      return [];
    }
  }

  // Get match by ID
  static Future<Map<String, dynamic>?> getMatch(String matchId) async {
    try {
      final response = await _supabase
          .from('matches')
          .select('*')
          .eq('id', matchId)
          .single();

      return response;
    } catch (e) {
      print('Error fetching match: $e');
      return null;
    }
  }

  // Add player to match
  static Future<bool> addPlayerToMatch({
    required String matchId,
    required String userId,
    required int position, // 0-3 for the 4 positions
    required String playerName,
    String? avatarUrl,
  }) async {
    try {
      print(
        'MatchService: Inserting player $playerName at position $position for user $userId in match $matchId',
      );

      final result = await _supabase.from('match_players').insert({
        'match_id': matchId,
        'user_id': userId,
        'position': position,
        'player_name': playerName,
        'avatar_url': avatarUrl,
        'joined_at': DateTime.now().toIso8601String(),
      }).select();

      print('MatchService: Insert successful, result: $result');
      return true;
    } catch (e) {
      print('MatchService: Error adding player to match: $e');
      return false;
    }
  }

  // Remove player from match
  static Future<bool> removePlayerFromMatch({
    required String matchId,
    required int position,
  }) async {
    try {
      await _supabase
          .from('match_players')
          .delete()
          .eq('match_id', matchId)
          .eq('position', position);

      return true;
    } catch (e) {
      print('Error removing player from match: $e');
      return false;
    }
  }

  // Get players for a match
  static Future<List<Map<String, dynamic>>> getMatchPlayers(
    String matchId,
  ) async {
    try {
      final response = await _supabase
          .from('match_players')
          .select('*')
          .eq('match_id', matchId)
          .order('position');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching match players: $e');
      return [];
    }
  }

  // Count how many times a user is in a specific match
  static Future<int> countUserInMatch(String matchId, String userId) async {
    try {
      final response = await _supabase
          .from('match_players')
          .select('id')
          .eq('match_id', matchId)
          .eq('user_id', userId);

      return response.length;
    } catch (e) {
      print('Error counting user in match: $e');
      return 0;
    }
  }

  // Update match status
  static Future<bool> updateMatchStatus(String matchId, String status) async {
    try {
      print('MatchService: Updating match $matchId status to: $status');
      final result = await _supabase
          .from('matches')
          .update({'status': status})
          .eq('id', matchId)
          .select();

      print('MatchService: Update status result: $result');
      return true;
    } catch (e) {
      print('Error updating match status: $e');
      return false;
    }
  }

  // Update match level
  static Future<bool> updateMatchLevel(
    String matchId,
    String skillLevel,
  ) async {
    try {
      print('MatchService: Updating match $matchId level to: $skillLevel');
      final result = await _supabase
          .from('matches')
          .update({'skill_level': skillLevel})
          .eq('id', matchId)
          .select();

      print('MatchService: Update result: $result');
      return true;
    } catch (e) {
      print('Error updating match level: $e');
      return false;
    }
  }
}
