import '../config/supabase_config.dart';

class CourtSlotService {
  // Obtener pistas disponibles para una fecha específica
  static Future<List<Map<String, dynamic>>> getAvailableSlotsForDate(
    DateTime date,
  ) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];

      final response = await supabase
          .from('court_slots')
          .select('*')
          .eq('date', dateStr)
          .eq('is_active', true)
          .order('start_time', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching court slots: $e');
      return [];
    }
  }

  // Obtener pistas activas solo para hoy y con hora futura
  static Future<List<Map<String, dynamic>>> getActiveSlotsForToday() async {
    try {
      final now = DateTime.now();
      final dateStr = now.toIso8601String().split('T')[0];
      final currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00';

      print('CourtSlotService: Buscando slots para fecha: $dateStr');
      print('CourtSlotService: Hora actual: $currentTime');

      final response = await supabase
          .from('court_slots')
          .select('*')
          .eq('date', dateStr)
          .eq('is_active', true)
          .gte('start_time', currentTime)
          .order('start_time', ascending: true);

      print('CourtSlotService: Slots encontrados: ${response.length}');
      if (response.isNotEmpty) {
        print('CourtSlotService: Primer slot: ${response[0]}');
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching active slots: $e');
      return [];
    }
  }

  // Crear nueva pista/horario (Admin)
  static Future<String?> createSlot({
    required String courtName,
    required String startTime,
    required DateTime date,
    int durationMinutes = 90,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      final dateStr = date.toIso8601String().split('T')[0];

      final response = await supabase
          .from('court_slots')
          .insert({
            'court_name': courtName,
            'start_time': startTime,
            'date': dateStr,
            'duration_minutes': durationMinutes,
            'is_active': true,
            'created_by': userId,
          })
          .select('id')
          .single();

      return response['id'];
    } catch (e) {
      print('Error creating court slot: $e');
      return null;
    }
  }

  // Crear múltiples pistas en lote (Admin)
  static Future<bool> createMultipleSlots({
    required List<String> courtNames,
    required List<String> startTimes,
    required DateTime date,
    int durationMinutes = 90,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      final dateStr = date.toIso8601String().split('T')[0];

      List<Map<String, dynamic>> slots = [];
      for (var courtName in courtNames) {
        for (var startTime in startTimes) {
          slots.add({
            'court_name': courtName,
            'start_time': startTime,
            'date': dateStr,
            'duration_minutes': durationMinutes,
            'is_active': true,
            'created_by': userId,
          });
        }
      }

      await supabase.from('court_slots').insert(slots);
      return true;
    } catch (e) {
      print('Error creating multiple slots: $e');
      return false;
    }
  }

  // Desactivar pista (Admin)
  static Future<bool> deactivateSlot(String slotId) async {
    try {
      await supabase
          .from('court_slots')
          .update({'is_active': false})
          .eq('id', slotId);

      return true;
    } catch (e) {
      print('Error deactivating slot: $e');
      return false;
    }
  }

  // Eliminar pista (Admin)
  static Future<bool> deleteSlot(String slotId) async {
    try {
      await supabase.from('court_slots').delete().eq('id', slotId);
      return true;
    } catch (e) {
      print('Error deleting slot: $e');
      return false;
    }
  }

  // Obtener todas las pistas (para admin)
  static Future<List<Map<String, dynamic>>> getAllSlots() async {
    try {
      final response = await supabase
          .from('court_slots')
          .select('*')
          .order('date', ascending: false)
          .order('start_time', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching all slots: $e');
      return [];
    }
  }
}
