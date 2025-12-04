import 'package:flutter/material.dart';
import '../services/schedule_config_service.dart';

class AdminScheduleScreen extends StatefulWidget {
  const AdminScheduleScreen({super.key});

  @override
  State<AdminScheduleScreen> createState() => _AdminScheduleScreenState();
}

class _AdminScheduleScreenState extends State<AdminScheduleScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  // Configuración Lunes-Sábado
  final TextEditingController _weekdayStartController = TextEditingController(
    text: '09:00',
  );
  final TextEditingController _weekdayEndController = TextEditingController(
    text: '22:00',
  );
  final TextEditingController _weekdayDurationController =
      TextEditingController(text: '90');
  final TextEditingController _weekdayCourtsController = TextEditingController(
    text: '6',
  );
  List<Map<String, String>> _weekdayBreaks = [];

  // Configuración Domingo
  final TextEditingController _sundayStartController = TextEditingController(
    text: '10:00',
  );
  final TextEditingController _sundayEndController = TextEditingController(
    text: '18:00',
  );
  final TextEditingController _sundayDurationController = TextEditingController(
    text: '90',
  );
  final TextEditingController _sundayCourtsController = TextEditingController(
    text: '3',
  );
  List<Map<String, String>> _sundayBreaks = [];

  // Generación de pistas
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  Future<void> _loadConfigs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final configs = await ScheduleConfigService.getAllConfigs();

      if (configs.containsKey('weekday')) {
        final weekday = configs['weekday']!;
        _weekdayStartController.text = weekday['start_time']
            .toString()
            .substring(0, 5);
        _weekdayEndController.text = weekday['end_time'].toString().substring(
          0,
          5,
        );
        _weekdayDurationController.text = weekday['duration_minutes']
            .toString();
        _weekdayCourtsController.text = weekday['number_of_courts'].toString();
        _weekdayBreaks = List<Map<String, String>>.from(
          (weekday['break_periods'] as List).map(
            (b) => {'start': b['start'].toString(), 'end': b['end'].toString()},
          ),
        );
      }

      if (configs.containsKey('sunday')) {
        final sunday = configs['sunday']!;
        _sundayStartController.text = sunday['start_time'].toString().substring(
          0,
          5,
        );
        _sundayEndController.text = sunday['end_time'].toString().substring(
          0,
          5,
        );
        _sundayDurationController.text = sunday['duration_minutes'].toString();
        _sundayCourtsController.text = sunday['number_of_courts'].toString();
        _sundayBreaks = List<Map<String, String>>.from(
          (sunday['break_periods'] as List).map(
            (b) => {'start': b['start'].toString(), 'end': b['end'].toString()},
          ),
        );
      }
    } catch (e) {
      print('Error loading configs: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveConfigs() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Guardar configuración de Lunes-Sábado
      await ScheduleConfigService.saveConfig(
        dayType: 'weekday',
        startTime: _weekdayStartController.text,
        endTime: _weekdayEndController.text,
        durationMinutes: int.parse(_weekdayDurationController.text),
        numberOfCourts: int.parse(_weekdayCourtsController.text),
        breakPeriods: _weekdayBreaks,
      );

      // Guardar configuración de Domingo
      await ScheduleConfigService.saveConfig(
        dayType: 'sunday',
        startTime: _sundayStartController.text,
        endTime: _sundayEndController.text,
        durationMinutes: int.parse(_sundayDurationController.text),
        numberOfCourts: int.parse(_sundayCourtsController.text),
        breakPeriods: _sundayBreaks,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuración guardada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isSaving = false;
    });
  }

  Future<void> _generateSlots() async {
    print('=== GENERANDO PISTAS ===');
    print('Fecha inicio: $_startDate');
    print('Fecha fin: $_endDate');

    setState(() {
      _isSaving = true;
    });

    try {
      final results = await ScheduleConfigService.generateSlotsForDateRange(
        _startDate,
        _endDate,
      );

      print('Resultados recibidos: $results');
      print('Número de resultados: ${results.length}');

      int totalSlots = 0;
      for (var result in results) {
        print('Resultado individual: $result');
        totalSlots += result['slots_created'] as int;
      }

      print('Total de pistas generadas: $totalSlots');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Se generaron $totalSlots pistas exitosamente'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('ERROR al generar pistas: $e');
      print('StackTrace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar pistas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isSaving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Configuración de Horarios',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Configuración Lunes-Sábado
              _buildDayTypeConfig(
                title: '📅 LUNES A SÁBADO',
                startController: _weekdayStartController,
                endController: _weekdayEndController,
                durationController: _weekdayDurationController,
                courtsController: _weekdayCourtsController,
                breaks: _weekdayBreaks,
                onAddBreak: () {
                  setState(() {
                    _weekdayBreaks.add({'start': '12:00', 'end': '13:00'});
                  });
                },
                onRemoveBreak: (index) {
                  setState(() {
                    _weekdayBreaks.removeAt(index);
                  });
                },
              ),

              const SizedBox(height: 30),

              // Configuración Domingo
              _buildDayTypeConfig(
                title: '📅 DOMINGO',
                startController: _sundayStartController,
                endController: _sundayEndController,
                durationController: _sundayDurationController,
                courtsController: _sundayCourtsController,
                breaks: _sundayBreaks,
                onAddBreak: () {
                  setState(() {
                    _sundayBreaks.add({'start': '12:00', 'end': '13:00'});
                  });
                },
                onRemoveBreak: (index) {
                  setState(() {
                    _sundayBreaks.removeAt(index);
                  });
                },
              ),

              const SizedBox(height: 30),

              // Botón Guardar Configuración
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveConfigs,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF60519b),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Guardar Configuración',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 40),

              // Sección de Generación de Pistas
              Container(
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
                    const Text(
                      '🎯 GENERAR PISTAS',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDatePicker(
                            label: 'Fecha inicio',
                            date: _startDate,
                            onChanged: (date) {
                              setState(() {
                                _startDate = date;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDatePicker(
                            label: 'Fecha fin',
                            date: _endDate,
                            onChanged: (date) {
                              setState(() {
                                _endDate = date;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _generateSlots,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Generar Pistas',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayTypeConfig({
    required String title,
    required TextEditingController startController,
    required TextEditingController endController,
    required TextEditingController durationController,
    required TextEditingController courtsController,
    required List<Map<String, String>> breaks,
    required VoidCallback onAddBreak,
    required Function(int) onRemoveBreak,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: 'Hora inicio',
                  controller: startController,
                  hint: '09:00',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  label: 'Hora cierre',
                  controller: endController,
                  hint: '22:00',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: 'Duración (min)',
                  controller: durationController,
                  hint: '90',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  label: 'Nº pistas',
                  controller: courtsController,
                  hint: '6',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            '⏸️ Descansos',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          ...breaks.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, String> breakPeriod = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showTimePicker(
                                context,
                                breakPeriod['start']!,
                                (newTime) {
                                  setState(() {
                                    breaks[index]['start'] = newTime;
                                  });
                                },
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  breakPeriod['start']!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '-',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showTimePicker(
                                context,
                                breakPeriod['end']!,
                                (newTime) {
                                  setState(() {
                                    breaks[index]['end'] = newTime;
                                  });
                                },
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  breakPeriod['end']!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: () => onRemoveBreak(index),
                    ),
                  ],
                ),
              ),
            );
          }),
          TextButton.icon(
            onPressed: onAddBreak,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Añadir descanso',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime date,
    required Function(DateTime) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) {
              onChanged(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: const TextStyle(color: Colors.white),
                ),
                const Icon(Icons.calendar_today, color: Colors.white, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showTimePicker(
    BuildContext context,
    String currentTime,
    Function(String) onTimeSelected,
  ) {
    final parts = currentTime.split(':');
    final initialHour = int.parse(parts[0]);
    final initialMinute = int.parse(parts[1]);

    showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF60519b),
              onPrimary: Colors.white,
              surface: Color(0xFF1e202e),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    ).then((time) {
      if (time != null) {
        final hour = time.hour.toString().padLeft(2, '0');
        final minute = time.minute.toString().padLeft(2, '0');
        onTimeSelected('$hour:$minute');
      }
    });
  }

  @override
  void dispose() {
    _weekdayStartController.dispose();
    _weekdayEndController.dispose();
    _weekdayDurationController.dispose();
    _weekdayCourtsController.dispose();
    _sundayStartController.dispose();
    _sundayEndController.dispose();
    _sundayDurationController.dispose();
    _sundayCourtsController.dispose();
    super.dispose();
  }
}
