// lib/main.dart
import 'package:car_maintenance_app/szolgaltatasok/ertesites_szolgaltatas.dart';
import 'package:flutter/material.dart';
import 'package:car_maintenance_app/kepernyok/fooldal/fooldal_kepernyo.dart';

// ======================= ÚJ, FONTOS IMPORTOK =======================
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
// =================================================================

Future<void> main() async {
  // Ez a sor biztosítja, hogy a Flutter kötések inicializálva legyenek,
  // mielőtt aszinkron műveletet végzünk.
  WidgetsFlutterBinding.ensureInitialized();

  // ======================= ÚJ INICIALIZÁLÁS =======================
  // Beállítjuk az alapértelmezett nyelvet (opcionális, de jó gyakorlat)
  Intl.defaultLocale = 'hu_HU';
  // Betöltjük a magyar (és egyéb) dátumformázási adatokat.
  await initializeDateFormatting();
  // ===============================================================

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
      home: const FooldalKepernyo(),
      debugShowCheckedModeBanner: false,
    );
  }
}