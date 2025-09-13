import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../widgets/floating_bottom_nav.dart';
import '../widgets/settings_button.dart';
import '../widgets/player_info_section.dart';
import '../widgets/logout_button.dart';
import '../widgets/match_card.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/match_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  // Cache de las pantallas para mantener el estado
  final List<Widget> _screens = [
    const MatchScreen(),
    const BookingScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.center,
            colors: [Color(0xFF60519b), Color(0xFF1e202e)],
            stops: [0.0, 1.0],
          ),
        ),
        child: Stack(
          children: [
            IndexedStack(index: _currentIndex, children: _screens),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: FloatingBottomNav(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen>
    with AutomaticKeepAliveClientMixin {
  String selectedLevel = 'todas';
  List<Map<String, dynamic>> allMatches = [];
  bool isLoading = true;

  @override
  bool get wantKeepAlive => true;

  final List<String> skillLevels = ['todas', 'bajo', 'medio', 'medio alto'];

  final List<Map<String, String>> defaultMatches = [
    {'courtNumber': 'pista 1', 'skillLevel': 'nivel', 'startTime': '09:00'},
    {'courtNumber': 'pista 2', 'skillLevel': 'nivel', 'startTime': '10:30'},
    {'courtNumber': 'pista 3', 'skillLevel': 'nivel', 'startTime': '20:00'},
    {'courtNumber': 'pista 4', 'skillLevel': 'nivel', 'startTime': '14:00'},
    {'courtNumber': 'pista 5', 'skillLevel': 'nivel', 'startTime': '16:30'},
    {'courtNumber': 'pista 6', 'skillLevel': 'nivel', 'startTime': '18:00'},
  ];

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Cargar partidos existentes y conteos de jugadores en paralelo (OPTIMIZADO)
      final futures = await Future.wait([
        MatchService.getMatches(),
        MatchService.getMatchPlayerCounts(),
      ]);

      final existingMatches = futures[0] as List<Map<String, dynamic>>;
      final playerCounts = futures[1] as Map<String, int>;

      print(
        'MainScreen: Loaded ${existingMatches.length} existing matches from database',
      );
      print('MainScreen: Player counts: $playerCounts');

      // Crear un mapa para buscar partidos existentes por combinación de datos
      // Priorizar partidos que tengan jugadores usando los conteos
      Map<String, Map<String, dynamic>> existingMatchMap = {};

      for (var match in existingMatches) {
        String key = '${match['court_number']}_${match['start_time']}';
        String matchId = match['id'];
        int currentPlayerCount = playerCounts[matchId] ?? 0;

        // Si ya existe un partido para esta clave, verificar cuál tiene más jugadores
        if (existingMatchMap.containsKey(key)) {
          String existingMatchId = existingMatchMap[key]!['id'];
          int existingPlayerCount = playerCounts[existingMatchId] ?? 0;

          // Si el nuevo partido tiene jugadores y el actual no, usar el nuevo
          if (currentPlayerCount > 0 && existingPlayerCount == 0) {
            existingMatchMap[key] = match;
          } else if (currentPlayerCount > existingPlayerCount) {
            // Si el nuevo tiene más jugadores, usarlo
            existingMatchMap[key] = match;
          }
          // Si ambos tienen jugadores o el actual tiene más, mantener el actual
        } else {
          existingMatchMap[key] = match;
        }
      }

      // Procesar partidos por defecto
      List<Map<String, dynamic>> processedMatches = [];

      for (var defaultMatch in defaultMatches) {
        String key =
            '${defaultMatch['courtNumber']}_${defaultMatch['startTime']}';

        if (existingMatchMap.containsKey(key)) {
          // Usar partido existente de la base de datos
          var existingMatch = existingMatchMap[key]!;
          processedMatches.add({
            'matchId': existingMatch['id'],
            'courtNumber': existingMatch['court_number'],
            'skillLevel': existingMatch['skill_level'],
            'startTime': existingMatch['start_time'],
            'status': existingMatch['status'] ?? 'abierto',
          });
        } else {
          // Usar partido por defecto (se creará cuando se abra el MatchCard)
          processedMatches.add({
            'matchId': null,
            'courtNumber': defaultMatch['courtNumber']!,
            'skillLevel': defaultMatch['skillLevel']!,
            'startTime': defaultMatch['startTime']!,
            'status': 'abierto',
          });
        }
      }

      print('MainScreen: Final processed matches: ${processedMatches.length}');

      setState(() {
        allMatches = processedMatches;
        isLoading = false;
      });

      print('MainScreen: UI updated with ${allMatches.length} matches');
    } catch (e) {
      print('Error loading matches: $e');
      // En caso de error, usar partidos por defecto
      setState(() {
        allMatches = defaultMatches
            .map(
              (match) => {
                'matchId': null,
                'courtNumber': match['courtNumber']!,
                'skillLevel': match['skillLevel']!,
                'startTime': match['startTime']!,
                'status': 'abierto',
              },
            )
            .toList();
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get filteredMatches {
    if (selectedLevel == 'todas') {
      return allMatches;
    }
    return allMatches
        .where((match) => match['skillLevel'] == selectedLevel)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 50.0, 20.0, 0.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'partidos',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            // Filtros de nivel
            SizedBox(
              height: 40,
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.transparent,
                      Colors.black,
                      Colors.black,
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.1, 0.9, 1.0],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 0, right: 20),
                  itemCount: skillLevels.length,
                  itemBuilder: (context, index) {
                    final level = skillLevels[index];
                    final isSelected = selectedLevel == level;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedLevel = level;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            level,
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF1e202e)
                                  : Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Lista de partidos
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadMatches,
                      color: Colors.white,
                      backgroundColor: const Color(0xFF60519b),
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 100),
                        itemCount: filteredMatches.length,
                        itemBuilder: (context, index) {
                          final match = filteredMatches[index];
                          return MatchCard(
                            matchId: match['matchId'],
                            courtNumber: match['courtNumber']!,
                            skillLevel: match['skillLevel']!,
                            startTime: match['startTime']!,
                            status: match['status'] ?? 'abierto',
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen>
    with AutomaticKeepAliveClientMixin {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  List<Map<String, dynamic>> availableCourts = [];
  bool isLoadingCourts = false;
  Map<String, dynamic>? confirmedReservation;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _initializeLocale();
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('es_ES', null);
    Intl.defaultLocale = 'es_ES';
  }

  Future<void> _loadAvailableCourts() async {
    if (_selectedDay == null) return;

    setState(() {
      isLoadingCourts = true;
    });

    try {
      // Cargar partidos existentes de la base de datos
      final existingMatches = await MatchService.getMatches();

      // Pistas por defecto (las mismas que en el home)
      final List<Map<String, String>> defaultCourts = [
        {'courtNumber': 'pista 1', 'skillLevel': 'nivel', 'startTime': '09:00'},
        {'courtNumber': 'pista 2', 'skillLevel': 'nivel', 'startTime': '10:30'},
        {'courtNumber': 'pista 3', 'skillLevel': 'nivel', 'startTime': '20:00'},
        {'courtNumber': 'pista 4', 'skillLevel': 'nivel', 'startTime': '14:00'},
        {'courtNumber': 'pista 5', 'skillLevel': 'nivel', 'startTime': '16:30'},
        {'courtNumber': 'pista 6', 'skillLevel': 'nivel', 'startTime': '18:00'},
      ];

      // Cargar conteos de jugadores para optimizar (OPTIMIZADO)
      final playerCounts = await MatchService.getMatchPlayerCounts();

      // Crear mapa de partidos existentes
      Map<String, Map<String, dynamic>> existingMatchMap = {};

      for (var match in existingMatches) {
        String key = '${match['court_number']}_${match['start_time']}';
        String matchId = match['id'];
        int currentPlayerCount = playerCounts[matchId] ?? 0;

        if (existingMatchMap.containsKey(key)) {
          String existingMatchId = existingMatchMap[key]!['id'];
          int existingPlayerCount = playerCounts[existingMatchId] ?? 0;

          // Priorizar el partido con más jugadores
          if (currentPlayerCount > existingPlayerCount) {
            existingMatchMap[key] = match;
          }
        } else {
          existingMatchMap[key] = match;
        }
      }

      // Procesar pistas disponibles (solo las que NO están cerradas)
      List<Map<String, dynamic>> courts = [];

      for (var defaultCourt in defaultCourts) {
        String key =
            '${defaultCourt['courtNumber']}_${defaultCourt['startTime']}';

        if (existingMatchMap.containsKey(key)) {
          var existingMatch = existingMatchMap[key]!;
          // Solo agregar si NO está cerrado
          if (existingMatch['status'] != 'cerrado') {
            courts.add({
              'matchId': existingMatch['id'],
              'courtNumber': existingMatch['court_number'],
              'skillLevel': existingMatch['skill_level'],
              'startTime': existingMatch['start_time'],
              'status': existingMatch['status'] ?? 'abierto',
            });
          }
        } else {
          // Pista por defecto (siempre disponible)
          courts.add({
            'matchId': null,
            'courtNumber': defaultCourt['courtNumber']!,
            'skillLevel': defaultCourt['skillLevel']!,
            'startTime': defaultCourt['startTime']!,
            'status': 'abierto',
          });
        }
      }

      setState(() {
        availableCourts = courts;
        isLoadingCourts = false;
      });
    } catch (e) {
      print('Error loading available courts: $e');
      setState(() {
        isLoadingCourts = false;
      });
    }
  }

  void _reserveCourt(Map<String, dynamic> court) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1e202e),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Reservar Pista',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pista: ${court['courtNumber']}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Horario: ${court['startTime']}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Fecha: ${DateFormat('EEEE, d MMMM yyyy', 'es_ES').format(_selectedDay!)}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '¿Deseas reservar esta pista?',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _confirmReservation(court);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF60519b),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Reservar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmReservation(Map<String, dynamic> court) {
    setState(() {
      confirmedReservation = {
        ...court,
        'reservationDate': _selectedDay,
        'reservationId': DateTime.now().millisecondsSinceEpoch.toString(),
      };
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reserva confirmada para ${court['courtNumber']} a las ${court['startTime']}',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );

    // Aquí puedes agregar lógica adicional para guardar la reserva en la base de datos
    print(
      'Reserva creada: ${court['courtNumber']} - ${court['startTime']} - ${_selectedDay}',
    );
  }

  // Función para obtener nombres de meses en español
  String _getMonthName(DateTime date) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 50.0, 20.0, 0.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'reservas',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // Calendario
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: TableCalendar<dynamic>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                calendarFormat: _calendarFormat,
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                    confirmedReservation =
                        null; // Reset reservation when changing day
                  });
                  _loadAvailableCourts();
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },

                // Configuración de localización
                locale: 'es_ES',
                startingDayOfWeek: StartingDayOfWeek.monday,

                // Estilos del calendario
                calendarStyle: CalendarStyle(
                  // Días normales
                  defaultTextStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  // Día seleccionado
                  selectedTextStyle: const TextStyle(
                    color: Color(0xFF1e202e),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  // Día de hoy
                  todayTextStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  todayDecoration: BoxDecoration(
                    color: const Color(0xFF60519b).withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  // Días fuera del mes
                  outsideTextStyle: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 16,
                  ),
                  // Días de fin de semana
                  weekendTextStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  // Marcadores
                  markerDecoration: const BoxDecoration(
                    color: Color(0xFF60519b),
                    shape: BoxShape.circle,
                  ),
                ),

                // Estilos del header
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  leftChevronIcon: const Icon(
                    Icons.chevron_left,
                    color: Colors.white,
                  ),
                  rightChevronIcon: const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                  ),
                  titleTextStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  titleTextFormatter: (date, locale) => _getMonthName(date),
                ),

                // Estilos de los días de la semana
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                  weekendStyle: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Información del día seleccionado
            if (_selectedDay != null)
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mis Reservas',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (confirmedReservation != null)
                        // Mostrar reserva confirmada
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Reserva confirmada',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      confirmedReservation!['courtNumber'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          color: Colors.white.withOpacity(0.7),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          confirmedReservation!['startTime'],
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.8,
                                            ),
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          color: Colors.white.withOpacity(0.7),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            DateFormat(
                                              'EEEE, d MMMM yyyy',
                                              'es_ES',
                                            ).format(
                                              confirmedReservation!['reservationDate'],
                                            ),
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(
                                                0.8,
                                              ),
                                              fontSize: 16,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'RESERVADO',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Center(
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      confirmedReservation = null;
                                    });
                                    _loadAvailableCourts();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white.withOpacity(
                                      0.1,
                                    ),
                                    side: BorderSide(
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Ver otras pistas',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (isLoadingCourts)
                        const Expanded(
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        )
                      else if (availableCourts.isEmpty)
                        Expanded(
                          child: Center(
                            child: Text(
                              'Selecciona un día para ver pistas disponibles',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pistas disponibles:',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  itemCount: availableCourts.length,
                                  itemBuilder: (context, index) {
                                    final court = availableCourts[index];
                                    return GestureDetector(
                                      onTap: () => _reserveCourt(court),
                                      child: Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.2,
                                            ),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    court['courtNumber'],
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  Text(
                                                    court['startTime'],
                                                    style: TextStyle(
                                                      color: Colors.white
                                                          .withOpacity(0.7),
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green
                                                        .withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    border: Border.all(
                                                      color: Colors.green,
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    court['status'],
                                                    style: const TextStyle(
                                                      color: Colors.green,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Icon(
                                                  Icons.arrow_forward_ios,
                                                  color: Colors.white
                                                      .withOpacity(0.5),
                                                  size: 16,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  String _playerName = 'Nombre del Jugador';
  String? _profileImagePath;
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  bool get wantKeepAlive => true;

  Map<String, String?> playerData = {
    'side': null,
    'style': null,
    'level': null,
    'paddle': '',
    'club': '',
    'phone': '',
  };

  @override
  void initState() {
    super.initState();
    _loadPlayerData();
  }

  Future<void> _loadPlayerData() async {
    final profile = await ProfileService.getUserProfile();
    setState(() {
      if (profile != null) {
        _playerName = profile['display_name'] ?? 'Nombre del Jugador';
        _profileImagePath = profile['avatar_url'];

        // Cargar datos adicionales del perfil
        playerData['side'] = profile['side_of_play'];
        playerData['style'] = profile['play_style'];
        playerData['level'] = profile['level'];
        playerData['paddle'] = profile['paddle'] ?? '';
        playerData['club'] = profile['club'] ?? '';
        playerData['phone'] = profile['phone'] ?? '';
      }
      _isLoading = false;
    });
  }

  Future<void> _savePlayerName(String name) async {
    final success = await ProfileService.updateUserProfile(
      displayName: name,
      avatarUrl: _profileImagePath,
      sideOfPlay: playerData['side'],
      playStyle: playerData['style'],
      level: playerData['level'],
      paddle: playerData['paddle'],
      club: playerData['club'],
      phone: playerData['phone'],
    );

    if (success) {
      setState(() {
        _playerName = name;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar el nombre'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveProfileImage(String imagePath) async {
    // Subir imagen a Supabase
    final avatarUrl = await ProfileService.uploadAvatar(imagePath);

    if (avatarUrl != null) {
      // Actualizar perfil con nueva URL
      final success = await ProfileService.updateUserProfile(
        displayName: _playerName,
        avatarUrl: avatarUrl,
        sideOfPlay: playerData['side'],
        playStyle: playerData['style'],
        level: playerData['level'],
        paddle: playerData['paddle'],
        club: playerData['club'],
        phone: playerData['phone'],
      );

      if (success) {
        setState(() {
          _profileImagePath = avatarUrl;
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al subir la imagen'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updatePlayerData(String key, String value) {
    setState(() {
      playerData[key] = value;
    });

    // Guardar automáticamente cuando se cambia un campo
    _saveAllPlayerData();
  }

  Future<void> _saveAllPlayerData() async {
    final success = await ProfileService.updateUserProfile(
      displayName: _playerName,
      avatarUrl: _profileImagePath,
      sideOfPlay: playerData['side'],
      playStyle: playerData['style'],
      level: playerData['level'],
      paddle: playerData['paddle'],
      club: playerData['club'],
      phone: playerData['phone'],
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al guardar los datos'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onSettingsPressed() {
    // TODO: Implementar navegación a configuración
    print('Settings pressed');
  }

  void _onLogoutPressed() async {
    await AuthService.signOut();
  }

  void _onAvatarTapped() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2a2d3a),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text(
                'Galería',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera, color: Colors.white),
              title: const Text(
                'Cámara',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _pickImageFromCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) {
        await _saveProfileImage(image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al acceder a la galería'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (image != null) {
        await _saveProfileImage(image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al acceder a la cámara'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEditNameDialog() {
    final TextEditingController controller = TextEditingController(
      text: _playerName,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2a2d3a),
        title: const Text(
          'Editar Nombre',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Nombre del jugador',
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF60519b)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _savePlayerName(controller.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text(
              'Guardar',
              style: TextStyle(color: Color(0xFF60519b)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            // Botón de configuración en esquina superior derecha
            Positioned(
              top: 20,
              right: 20,
              child: SettingsButton(onPressed: _onSettingsPressed),
            ),

            // Contenido principal
            SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // Avatar de perfil
                  GestureDetector(
                    onTap: _onAvatarTapped,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        image: _profileImagePath != null
                            ? DecorationImage(
                                image: _profileImagePath!.startsWith('http')
                                    ? NetworkImage(_profileImagePath!)
                                          as ImageProvider
                                    : FileImage(File(_profileImagePath!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _profileImagePath == null
                          ? const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Nombre del jugador (clickeable)
                  GestureDetector(
                    onTap: _showEditNameDialog,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _playerName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.edit, color: Colors.white70, size: 20),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Información del jugador
                  PlayerInfoSection(
                    playerName: _playerName,
                    playerData: playerData,
                    onDataChanged: _updatePlayerData,
                  ),

                  const SizedBox(height: 40),

                  // Botón de logout
                  LogoutButton(onPressed: _onLogoutPressed),

                  const SizedBox(height: 100), // Espacio para la navegación
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
