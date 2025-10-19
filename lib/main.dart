// lib/main.dart
import 'package:car_maintenance_app/szolgaltatasok/ertesites_szolgaltatas.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

// === FONTOS VÁLTOZTATÁS: A Főoldal helyett az Indítóképernyőt importáljuk ===
import 'kepernyok/indito/indito_kepernyo.dart';

Future<void> main() async {
  // Ez a sor biztosítja, hogy a Flutter kötések inicializálva legyenek,
  // mielőtt aszinkron műveletet végzünk.
  WidgetsFlutterBinding.ensureInitialized();

  // Beállítjuk az alapértelmezett nyelvet (opcionális, de jó gyakorlat)
  Intl.defaultLocale = 'hu_HU';
  // Betöltjük a magyar (és egyéb) dátumformázási adatokat.
  await initializeDateFormatting();

  // Értesítés szolgáltatás inicializálása és engedélykérés
  final ErtesitesSzolgaltatas ertesitesSzolgaltatas = ErtesitesSzolgaltatas();
  await ertesitesSzolgaltatas.init();
  await ertesitesSzolgaltatas.requestPermissions();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Olajfolt Szerviz-napló',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: const Color(0xFF121212),
        fontFamily: 'Roboto',
      ),
      // ==========================================================
      // ===          ITT VAN A JAVÍTÁS LÉNYEGE                  ===
      // ==========================================================
      // Az alkalmazás most már az Indítóképernyővel indul, ami garantálja
      // a logó megjelenését a beállított ideig.
      home: const InditoKepernyo(),
      // FooldalKepernyo() helyett InditoKepernyo()
      // ==========================================================
      debugShowCheckedModeBanner: false,
    );
  }
}