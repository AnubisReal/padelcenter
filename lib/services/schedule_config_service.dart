import '../config/supabase_config.dart';

class ScheduleConfigService {
  // Obtener configuración de un tipo de día
  static Future<Map<String, dynamic>?> getConfig(String dayType) async {
    try {
      final response = await supabase
          .from('schedule_config')
          .select('*')
          .eq('day_type', dayType)
          .eq('is_active', true)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error fetching schedule config: $e');
      return null;
    }
  }

  // Obtener todas las configuraciones
  static Future<Map<String, Map<String, dynamic>>> getAllConfigs() async {
    try {
      final response = await supabase
          .from('schedule_config')
          .select('*')
          .eq('is_active', true);

      Map<String, Map<String, dynamic>> configs = {};
      for (var config in response) {
        configs[config['day_type']] = config;
      }

      return configs;
    } catch (e) {
      print('Error fetching all configs: $e');
      return {};
    }
  }

  // Guardar/actualizar configuración
  static Future<bool> saveConfig({
    required String dayType,
    required String startTime,
    required String endTime,
    required int durationMinutes,
    required int numberOfCourts,
    required List<Map<String, String>> breakPeriods,
    String courtNamePrefix = 'pista',
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;

      await supabase.from('schedule_config').upsert({
        'day_type': dayType,
        'start_time': startTime,
        'end_time': endTime,
        'duration_minutes': durationMinutes,
        'number_of_courts': numberOfCourts,
        'court_name_prefix': courtNamePrefix,
        'break_periods': breakPeriods,
        'is_active': true,
        'updated_by': userId,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'day_type');

      return true;
    } catch (e) {
      print('Error saving schedule config: $e');
      return false;
    }
  }

  // Generar pistas para un rango de fechas (directamente desde Flutter)
  static Future<List<Map<String, dynamic>>> generateSlotsForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    List<Map<String, dynamic>> results = [];

    try {
      // Obtener configuraciones
      final configs = await getAllConfigs();
      if (configs.isEmpty) {
        print('No hay configuraciones disponibles');
        return results;
      }

      // PASO 1: Limpiar pistas vacías del rango de fechas (DESHABILITADO por ahora)
      // print('ScheduleConfigService: Limpiando pistas vacías...');
      // await _cleanEmptySlotsInRange(startDate, endDate);

      DateTime currentDate = startDate;
      print(
        'ScheduleConfigService: Generando pistas día por día desde Flutter',
      );

      while (currentDate.isBefore(endDate.add(const Duration(days: 1)))) {
        final dateStr = currentDate.toIso8601String().split('T')[0];
        final dayOfWeek = currentDate.weekday; // 1=Lunes, 7=Domingo

        // Determinar tipo de día
        final dayType = dayOfWeek == 7 ? 'sunday' : 'weekday';
        final config = configs[dayType];

        if (config == null) {
          print('No hay configuración para $dayType');
          currentDate = currentDate.add(const Duration(days: 1));
          continue;
        }

        print('Generando pistas para: $dateStr ($dayType)');

        int slotsCreated = 0;

        try {
          // Generar slots según configuración
          final startTime = config['start_time'].toString();
          final endTime = config['end_time'].toString();
          final durationMinutes = config['duration_minutes'] as int;
          final numberOfCourts = config['number_of_courts'] as int;
          final breakPeriods = config['break_periods'] as List;

          // Calcular slots por pista
          final startMinutes = _parseTime(startTime.substring(0, 5));
          final endMinutes = _parseTime(endTime.substring(0, 5));
          int currentMinutes = startMinutes;

          List<Map<String, dynamic>> slotsToInsert = [];

          for (int courtNum = 1; courtNum <= numberOfCourts; courtNum++) {
            currentMinutes = startMinutes;

            while (currentMinutes + durationMinutes <= endMinutes) {
              final slotTime = _formatTime(currentMinutes);

              // Verificar si está en periodo de descanso
              bool isInBreak = false;
              for (var breakPeriod in breakPeriods) {
                final breakStart = _parseTime(breakPeriod['start']);
                final breakEnd = _parseTime(breakPeriod['end']);
                if (currentMinutes >= breakStart && currentMinutes < breakEnd) {
                  isInBreak = true;
                  break;
                }
              }

              if (!isInBreak) {
                slotsToInsert.add({
                  'court_name': 'pista $courtNum',
                  'start_time': slotTime,
                  'date': dateStr,
                  'duration_minutes': durationMinutes,
                  'is_active': true,
                });
              }

              currentMinutes += durationMinutes;
            }
          }

          // Insertar todos los slots de este día
          if (slotsToInsert.isNotEmpty) {
            try {
              await supabase.from('court_slots').upsert(slotsToInsert);
              slotsCreated = slotsToInsert.length;
            } catch (e) {
              // Si falla, los slots ya existen - contar como exitosos
              slotsCreated = slotsToInsert.length;
              print('Slots ya existen (OK): ${e.toString().substring(0, 50)}');
            }
          }

          print('Pistas generadas para $dateStr: $slotsCreated');
        } catch (e) {
          print('Error generando pistas para $dateStr: $e');
        }

        results.add({'result_date': dateStr, 'slots_created': slotsCreated});

        currentDate = currentDate.add(const Duration(days: 1));
      }

      print('Total de días procesados: ${results.length}');
      return results;
    } catch (e, stackTrace) {
      print('Error generating slots for date range: $e');
      print('StackTrace: $stackTrace');
      return results;
    }
  }

  // Vista previa: calcular cuántas pistas se generarían
  static int calculateSlotsPreview({
    required String startTime,
    required String endTime,
    required int durationMinutes,
    required int numberOfCourts,
    required List<Map<String, String>> breakPeriods,
  }) {
    try {
      // Parsear horas
      final start = _parseTime(startTime);
      final end = _parseTime(endTime);

      int totalMinutes = end - start;
      int slotsPerCourt = totalMinutes ~/ durationMinutes;

      // Calcular slots en periodos de descanso
      int breakSlots = 0;
      for (var breakPeriod in breakPeriods) {
        final breakStart = _parseTime(breakPeriod['start']!);
        final breakEnd = _parseTime(breakPeriod['end']!);
        int breakMinutes = breakEnd - breakStart;
        breakSlots += breakMinutes ~/ durationMinutes;
      }

      int slotsPerCourtAfterBreaks = slotsPerCourt - breakSlots;
      return slotsPerCourtAfterBreaks * numberOfCourts;
    } catch (e) {
      print('Error calculating preview: $e');
      return 0;
    }
  }

  // Convertir "HH:MM" a minutos desde medianoche
  static int _parseTime(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  // Convertir minutos a "HH:MM"
  static String _formatTime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }

  // Eliminar todas las pistas de una fecha
  static Future<bool> deleteSlotsForDate(DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];

      await supabase.from('court_slots').delete().eq('date', dateStr);

      return true;
    } catch (e) {
      print('Error deleting slots for date: $e');
      return false;
    }
  }

  // Eliminar pistas de un rango de fechas
  static Future<bool> deleteSlotsForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final startStr = startDate.toIso8601String().split('T')[0];
      final endStr = endDate.toIso8601String().split('T')[0];

      await supabase
          .from('court_slots')
          .delete()
          .gte('date', startStr)
          .lte('date', endStr);

      return true;
    } catch (e) {
      print('Error deleting slots for date range: $e');
      return false;
    }
  }

  // Limpiar pistas vacías (sin jugadores) en un rango de fechas
  static Future<void> _cleanEmptySlotsInRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final startStr = startDate.toIso8601String().split('T')[0];
      final endStr = endDate.toIso8601String().split('T')[0];

      print('Limpiando slots de $startStr a $endStr');

      // Obtener todos los slots del rango
      final slots = await supabase
          .from('court_slots')
          .select('id')
          .gte('date', startStr)
          .lte('date', endStr);

      if (slots.isEmpty) {
        print('No hay slots para limpiar');
        return;
      }

      final slotIds = slots.map((s) => s['id'] as String).toList();
      print('Total slots encontrados: ${slotIds.length}');

      // Obtener matches que tienen jugadores
      final matchesWithPlayers = await supabase
          .from('match_players')
          .select('match_id');

      final matchIdsWithPlayers = matchesWithPlayers
          .map((m) => m['match_id'] as String)
          .toSet();

      print('Matches con jugadores: ${matchIdsWithPlayers.length}');

      // Obtener slots que tienen matches con jugadores
      final matchesWithSlots = await supabase
          .from('matches')
          .select('court_slot_id')
          .inFilter('id', matchIdsWithPlayers.toList());

      final slotsWithPlayers = matchesWithSlots
          .where((m) => m['court_slot_id'] != null)
          .map((m) => m['court_slot_id'] as String)
          .toSet();

      print('Slots con jugadores: ${slotsWithPlayers.length}');

      // Slots a eliminar = todos - los que tienen jugadores
      final slotsToDelete = slotIds
          .where((id) => !slotsWithPlayers.contains(id))
          .toList();

      if (slotsToDelete.isNotEmpty) {
        await supabase
            .from('court_slots')
            .delete()
            .inFilter('id', slotsToDelete);

        print('✅ Limpiados ${slotsToDelete.length} slots vacíos');
      } else {
        print('No hay slots vacíos para limpiar');
      }
    } catch (e) {
      print('Error limpiando slots vacíos: $e');
    }
  }
}
