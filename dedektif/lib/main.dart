import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'services/app_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Oyun dikey ekranda oynanır.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final services = await AppServices.createDefault();
  runApp(DedektifApp(services: services));
}
