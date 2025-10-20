// lib/main.dart
import 'package:car_maintenance_app/szolgaltatasok/ertesites_szolgaltatas.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'kepernyok/indito/indito_kepernyo.dart';

// === ÚJ IMPORT A MAGYAROSÍTÁSHOZ ===
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Intl.defaultLocale = 'hu_HU';
  await initializeDateFormatting();

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

      // === EZ AZ ÚJ BLOKK A MAGYAROSÍTÁSHOZ ===
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('hu', 'HU'), // Magyar nyelv engedélyezése
      ],
      locale: const Locale('hu', 'HU'),
      // ======================================

      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: const Color(0xFF121212),
        fontFamily: 'Roboto',
      ),
      home: const InditoKepernyo(),
      debugShowCheckedModeBanner: false,
    );
  }
}