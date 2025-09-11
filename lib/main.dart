import 'package:flutter/material.dart';
import 'config/supabase_config.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Supabase
  await SupabaseConfig.initialize();
  
  runApp(const PadelCenterApp());
}
