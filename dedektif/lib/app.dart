import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'features/menu/main_menu_screen.dart';
import 'services/app_services.dart';
import 'widgets/effects/screen_shake.dart';

/// Uygulama kökü: servisleri sağlar, temayı kurar.
class DedektifApp extends StatelessWidget {
  const DedektifApp({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: services),
        Provider.value(value: services.catalog),
        Provider.value(value: services.audio),
        ChangeNotifierProvider.value(value: services.settings),
        ChangeNotifierProvider.value(value: services.purchases),
      ],
      child: MaterialApp(
        title: 'Dedektif',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(),
        // Sistem metinleri (geri, menü, iptal...) Türkçe görünsün.
        locale: const Locale('tr'),
        supportedLocales: const [Locale('tr')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        // Her ekran titreyebilsin diye en dışa sarılır.
        builder: (context, child) => ScreenShake(child: child!),
        home: const MainMenuScreen(),
      ),
    );
  }
}
