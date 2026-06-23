import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'services/background_sync.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Registra l'auto-sync periodico in background (best-effort).
  await const BackgroundSyncManager().initialize();

  runApp(const ProviderScope(child: OpenFitDataApp()));
}
