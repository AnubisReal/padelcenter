import 'package:flutter/material.dart';
import 'config/supabase_config.dart';
import 'app/app.dart';
import 'services/match_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Supabase
  await SupabaseConfig.initialize();

  // Inicializar suscripciones realtime
  MatchService.initRealtimeSubscriptions();

  runApp(const PadelCenterApp());
}
