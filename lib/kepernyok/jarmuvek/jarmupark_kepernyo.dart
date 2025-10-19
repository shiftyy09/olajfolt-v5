import 'dart:io'; // Fájlkezeléshez
import 'package:flutter/material.dart';
import 'package:diacritic/diacritic.dart';
import 'package:intl/intl.dart';
import '../../alap/adatbazis/adatbazis_kezelo.dart';
import '../../modellek/jarmu.dart';
import 'jarmu_hozzaadasa.dart';
import 'szerviznaplo_kepernyo.dart';

class JarmuparkKepernyo extends StatefulWidget {
  const JarmuparkKepernyo({super.key});

  @override
  State<JarmuparkKepernyo> createState() => _JarmuparkKepernyoState();
}

class _JarmuparkKepernyoState extends State<JarmuparkKepernyo> {
  Future<List<Jarmu>>? _vehiclesFuture;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  void _loadVehicles() {
    setState(() {
      _vehiclesFuture = AdatbazisKezelo.instance.getVehicles().then(
            (maps) => maps.map((map) => Jarmu.fromMap(map)).toList(),
      );
    });
  }

  void _navigateAndReload(Widget page) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
    if (result == true) {
      _loadVehicles();
    }
  }

  void _navigateToServiceLog(Jarmu jarmu) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SzerviznaploKepernyo(vehicle: jarmu),
      ),
    );
  }

  void _deleteVehicle(Jarmu vehicle) async {
    final bool? confirmed = await showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15)),
            title:
            const Text(
                'Törlés megerősítése', style: TextStyle(color: Colors.white)),
            content: Text(
                'Biztosan törölni szeretnéd a(z) ${vehicle.make} ${vehicle
                    .model} járművet és minden hozzá tartozó adatot?',
                style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child:
                  const Text('Mégse', style: TextStyle(color: Colors.white70))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Törlés',
                    style:
                    TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      final db = AdatbazisKezelo.instance;
      await db.deleteServicesForVehicle(vehicle.id!);
      await db.delete('vehicles', vehicle.id!);
      _loadVehicles();
    }
  }

  String _getLogoPath(String make) {
    String safeName = removeDiacritics(make.toLowerCase());
    safeName = safeName.replaceAll(RegExp(r'\s+'), '-');
    safeName = safeName.replaceAll(RegExp(r'[^a-z0-9\-]'), '');
    return 'assets/images/$safeName.png';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
          title: const Text('Járműpark'),
          backgroundColor: Colors.transparent,
          elevation: 0),
      body: FutureBuilder<List<Jarmu>>(
        future: _vehiclesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.orange));
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Hiba: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red)));
          }
          final vehicles = snapshot.data ?? [];
          if (vehicles.isEmpty) {
            return Center(
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_car_outlined,
                              size: 80, color: Colors.grey[600]),
                          const SizedBox(height: 16),
                          const Text('Még nincsenek járművek rögzítve.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 18)),
                          const SizedBox(height: 8),
                          const Text(
                              'Nyomj a "+" gombra egy új jármű hozzáadásához.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 16))
                        ])));
          }
          // A ListView most már szellősebb
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              return _buildVehicleCard(vehicles[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () => _navigateAndReload(const JarmuHozzaadasa()),
          backgroundColor: Colors.orange,
          tooltip: 'Új jármű hozzáadása',
          child: const Icon(Icons.add, color: Colors.black)),
    );
  }


  // ==========================================================
  // ===          ÚJ, MODERNEBB KÁRTYA DIZÁJN             ===
  // ==========================================================
  Widget _buildVehicleCard(Jarmu vehicle) {
    final logoPath = _getLogoPath(vehicle.make);
    final bool hasUserImage = vehicle.imagePath != null &&
        vehicle.imagePath!.isNotEmpty;

    return GestureDetector(
      onTap: () => _navigateToServiceLog(vehicle),
      child: Card(
        elevation: 5,
        margin: const EdgeInsets.only(bottom: 16.0),
        color: const Color(0xFF1E1E1E),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- FELSŐ RÉSZ: KÉP VAGY LOGÓ ---
            SizedBox(
              height: 150, // Magasság a vizuális egyensúlyért
              width: double.infinity,
              child: hasUserImage
                  ? Image.file(
                File(vehicle.imagePath!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildLogoContainer(logoPath),
              )
                  : _buildLogoContainer(logoPath),
            ),

            // --- ALSÓ RÉSZ: INFORMÁCIÓK ÉS GOMBOK ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bal oldali információs blokk
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${vehicle.make} ${vehicle.model}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${vehicle.licensePlate.toUpperCase()} • ${vehicle
                                  .year}',
                              style: TextStyle(
                                color: Colors.orange.shade300,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Jobb oldali "több" gomb
                      _buildPopupMenuButton(vehicle),
                    ],
                  ),
                  const Divider(
                      color: Colors.white24, height: 32, thickness: 0.5),
                  // Km óra állás
                  Row(
                    children: [
                      Icon(Icons.speed_outlined, color: Colors.white70,
                          size: 20),
                      const SizedBox(width: 10),
                      Text(
                        '${NumberFormat.decimalPattern('hu_HU').format(
                            vehicle.mileage)} km',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Új segéd-widget a "több" menü gombhoz (szerkesztés, törlés)
  Widget _buildPopupMenuButton(Jarmu vehicle) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white70),
      color: const Color(0xFF2C2C2C),
      // Sötét háttér a menünek
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (value) {
        if (value == 'edit') {
          _navigateAndReload(JarmuHozzaadasa(vehicleToEdit: vehicle));
        } else if (value == 'delete') {
          _deleteVehicle(vehicle);
        }
      },
      itemBuilder: (BuildContext context) =>
      <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, color: Colors.orange, size: 22),
              SizedBox(width: 12),
              Text('Szerkesztés', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
              SizedBox(width: 12),
              Text('Törlés', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }

  // Módosított logó konténer, gradiens háttérrel
  Widget _buildLogoContainer(String logoPath) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2A2A2A),
            const Color(0xFF1E1E1E),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Image.asset(
            logoPath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                  Icons.directions_car, color: Colors.white30, size: 50);
            },
          ),
        ),
      ),
    );
  }

// Ez a widget már nem szükséges az új dizájnnal
// Widget _buildActionButton(...) {}
}