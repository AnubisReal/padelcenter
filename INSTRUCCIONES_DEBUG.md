# Instrucciones para depurar la animación de partido cerrado

## Paso 1: Limpiar datos de prueba

Agrega este código temporal en `main_screen.dart` dentro del método `initState()` para limpiar los datos:

```dart
@override
void initState() {
  super.initState();

  // TEMPORAL: Limpiar historial de animaciones para testing
  _clearSeenMatches();

  _loadMatches();
  _setupRealtimeListener();
  _checkForCompletedMatches();
}

Future<void> _clearSeenMatches() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('seen_completed_matches');
  print('🧹 Historial de animaciones limpiado');
}
```

## Paso 2: Probar con dos dispositivos

1. Abre la app en dos dispositivos diferentes
2. Únete al mismo partido con ambos dispositivos (por ejemplo, jugador 1 y jugador 2)
3. Desde un tercer dispositivo (o los mismos), completa el partido agregando los jugadores 3 y 4
4. Observa los logs en ambos dispositivos

## Logs a buscar:

- 🔔 = Evento de realtime recibido
- ✅ = Partido cerrado detectado
- 👤 = Usuario actual
- 👥 = Verificación si el usuario está en el partido
- 🎉 = Animación mostrada
- ⏭️ = Animación ya vista o evento ignorado
- ❌ = Error o condición no cumplida

## Paso 3: Verificar en la consola

Busca estos logs en orden:

1. `🔔 MatchScreen: REALTIME EVENT RECEIVED!`
2. `✅ Match XXX is CERRADO!`
3. `👥 Is user in match: true`
4. `🎉 SHOWING ANIMATION for match XXX`

Si alguno de estos no aparece, ahí está el problema.

## Problemas comunes:

### Si no ves el evento 🔔:

- El realtime no está funcionando
- Verifica que Supabase Realtime esté habilitado en tu proyecto
- Verifica que la tabla `matches` tenga Realtime habilitado

### Si ves 🔔 pero no ✅:

- El evento no es UPDATE o el status no es "cerrado"
- Verifica que el partido realmente se esté cerrando en la BD

### Si ves ✅ pero no 👥:

- El usuario no está en el partido
- Verifica que el usuario esté correctamente guardado en `match_players`

### Si ves 👥 pero no 🎉:

- La animación ya fue vista
- Limpia SharedPreferences con el código del Paso 1

## Paso 4: Remover código temporal

Una vez que funcione, ELIMINA el método `_clearSeenMatches()` y su llamada en `initState()`.
