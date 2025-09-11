import 'package:flutter/material.dart';

class PlayerInfoSection extends StatelessWidget {
  final String playerName;
  final Map<String, String?> playerData;
  final Function(String key, String value) onDataChanged;

  const PlayerInfoSection({
    super.key,
    required this.playerName,
    required this.playerData,
    required this.onDataChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Información del jugador
        const Text(
          'Información del Jugador',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        
        _buildInfoItem(
          'Lado de juego',
          'side',
          ['Derecha', 'Izquierda', 'Ambos'],
        ),
        
        _buildInfoItem(
          'Estilo de juego',
          'style',
          ['Ofensivo', 'Defensivo', 'Mixto'],
        ),
        
        _buildInfoItem(
          'Nivel',
          'level',
          ['Principiante', 'Intermedio', 'Avanzado', 'Profesional'],
        ),
        
        _buildTextInfoItem(
          'Pala favorita',
          'paddle',
          'Ej: Bullpadel Vertex 03',
        ),
        
        _buildTextInfoItem(
          'Club habitual',
          'club',
          'Ej: Club de Pádel Madrid',
        ),
        
        _buildTextInfoItem(
          'Número de teléfono',
          'phone',
          'Ej: +34 123 456 789',
        ),
      ],
    );
  }

  Widget _buildInfoItem(String title, String key, List<String> options) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: playerData[key],
                hint: Text(
                  'Seleccionar $title',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                    fontFamily: 'MonumentExtended',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                dropdownColor: const Color(0xFF1e202e),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'MonumentExtended',
                  fontWeight: FontWeight.w400,
                ),
                items: options.map((String option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    onDataChanged(key, newValue);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInfoItem(String title, String key, String placeholder) {
    // Crear controlador con el valor inicial
    final controller = TextEditingController(text: playerData[key] ?? '');
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: TextField(
              controller: controller,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'MonumentExtended',
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                  fontFamily: 'MonumentExtended',
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) => onDataChanged(key, value),
            ),
          ),
        ],
      ),
    );
  }
}
