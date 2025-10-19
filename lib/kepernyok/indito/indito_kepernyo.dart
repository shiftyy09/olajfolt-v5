// lib/kepernyok/indito/indito_kepernyo.dart
import 'package:flutter/material.dart';
import '../../alap/adatbazis/adatbazis_kezelo.dart';
import '../fooldal/fooldal_kepernyo.dart';

class InditoKepernyo extends StatefulWidget {
  const InditoKepernyo({super.key});

  @override
  State<InditoKepernyo> createState() => _InditoKepernyoState();
}

class _InditoKepernyoState extends State<InditoKepernyo>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _initializeApp();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )
      ..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  // ==========================================================
  // ===          JAVÍTVA A MINIMÁLIS VÁRAKOZÁSI IDŐVEL       ===
  // ==========================================================
  void _initializeApp() async {
    // 1. Elindítjuk az adatbázis betöltését (ez a háttérben fut)
    final dbFuture = AdatbazisKezelo.instance.database;

    // 2. Létrehozunk egy másik jövőbeli eseményt, ami egy fix idő múlva teljesül.
    // EZ A SOR GARANTÁLJA A MINIMÁLIS MEGJELENÉSI IDŐT.
    // Állítsd be, amilyen hosszúra szeretnéd (pl. 2000ms = 2 másodperc).
    final minDelayFuture = Future.delayed(const Duration(milliseconds: 2000));

    // 3. A Future.wait megvárja, amíg MINDKÉT művelet befejeződik.
    // - Ha a DB lassan tölt be (>2s), akkor a DB-re várunk.
    // - Ha a DB gyorsan betölt (<2s), akkor is megvárjuk a 2 másodpercet.
    await Future.wait([dbFuture, minDelayFuture]);

    // 4. Navigáció a főoldalra, csak ha a képernyő még létezik a fán.
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const FooldalKepernyo(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  // ==========================================================

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: Image.asset(
                'assets/images/olajfolt.png',
                width: 250,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Szerviz-napló',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 255, 164, 0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}