// lib/kepernyok/beallitasok/beallitasok_kepernyo.dart
import 'package:car_maintenance_app/alap/adatbazis/adatbazis_kezelo.dart';
import 'package:car_maintenance_app/modellek/jarmu.dart';
import 'package:car_maintenance_app/szolgaltatasok/ertesites_szolgaltatas.dart';
import 'package:car_maintenance_app/szolgaltatasok/csv_szolgaltatas.dart';
import 'package:car_maintenance_app/szolgaltatasok/pdf_szolgaltatas.dart';
import 'package:car_maintenance_app/widgetek/kozos_menu_kartya.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BeallitasokKepernyo extends StatefulWidget {
  const BeallitasokKepernyo({super.key});

  @override
  State<BeallitasokKepernyo> createState() => _BeallitasokKepernyoState();
}

class _BeallitasokKepernyoState extends State<BeallitasokKepernyo> {
  final ErtesitesSzolgaltatas _ertesitesSzolgaltatas = ErtesitesSzolgaltatas();
  final PdfSzolgaltatas _pdfSzolgaltatas = PdfSzolgaltatas();
  final CsvSzolgaltatas _csvSzolgaltatas = CsvSzolgaltatas();

  bool _notificationsEnabled = false;
  bool _isProcessing = false; // Egyetlen állapotváltozó az összes művelethez

  @override
  void initState() {
    super.initState();
    _loadNotificationSetting();
  }

  void _loadNotificationSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? false;
    });
  }

  Future<void> _saveNotificationSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', value);
  }

  Future<void> _handlePdfExport() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final db = AdatbazisKezelo.instance;
      final vehiclesMap = await db.getVehicles();
      final vehicles = vehiclesMap.map((map) => Jarmu.fromMap(map)).toList();

      if (!mounted) {
        setState(() => _isProcessing = false);
        return;
      }
      if (vehicles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Nincs jármű a parkban, nincs mit exportálni!'),
            backgroundColor: Colors.redAccent));
        setState(() => _isProcessing = false);
        return;
      }

      final Jarmu? selectedVehicle = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text('Válassz járművet',
                style: TextStyle(color: Colors.white)),
            content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: vehicles.length,
                    itemBuilder: (context, index) => ListTile(
                        title: Text(
                            '${vehicles[index].make} ${vehicles[index].model}',
                            style: const TextStyle(color: Colors.white)),
                        onTap: () =>
                            Navigator.of(context).pop(vehicles[index]))))),
      );

      if (selectedVehicle == null) {
        if (mounted) setState(() => _isProcessing = false);
        return;
      }

      final ExportAction? action = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Válassz műveletet',
              style: TextStyle(color: Colors.white)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
                leading: const Icon(Icons.save_alt, color: Colors.white70),
                title: const Text('Mentés a telefonra',
                    style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(context).pop(ExportAction.save)),
            ListTile(
                leading: const Icon(Icons.share, color: Colors.white70),
                title: const Text('Megosztás...',
                    style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(context).pop(ExportAction.share)),
          ]),
        ),
      );

      if (action == null) {
        if (mounted) setState(() => _isProcessing = false);
        return;
      }

      final bool success = await _pdfSzolgaltatas.createAndExportPdf(
          selectedVehicle, context, action);

      if (mounted && success && action == ExportAction.save) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('PDF sikeresen mentve a "Letöltések" mappába!'),
            backgroundColor: Colors.green));
      } else if (mounted && !success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('A PDF generálás sikertelen. Részletek a konzolon.'),
            backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Hiba az exportálás során: $e'),
            backgroundColor: Colors.red));
      }
    }
    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleCsvExport() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final result = await _csvSzolgaltatas.exportAllDataToCsv();
      if (mounted) {
        if (result == "empty") {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Nincs adat, amit exportálni lehetne.'),
              backgroundColor: Colors.orange));
        } else if (result == "permission_denied") {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Tárhely hozzáférés megtagadva! Engedélyezd a beállításokban.'),
              backgroundColor: Colors.red));
        } else if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Sikeres mentés a "Letöltések" mappába!'),
              backgroundColor: Colors.green));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Ismeretlen hiba történt az exportálás során.'),
              backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Hiba az exportálás közben: $e'),
            backgroundColor: Colors.red));
      }
    }
    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleCsvImport() async {
    if (_isProcessing) return;
    final bool? confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
          title: const Text('Figyelem!'),
          content: const Text(
              'Az importálás felülírja az összes jelenlegi adatodat. Biztosan folytatod?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Mégse')),
            TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Folytatás'))
          ]),
    );
    if (confirmed != true) return;
    setState(() => _isProcessing = true);
    try {
      final result = await _csvSzolgaltatas.importDataFromCsv();
      if (mounted) {
        String message;
        Color color = Colors.green;
        switch (result) {
          case ImportResult.success:
            message = 'Sikeres adat importálás!';
            break;
          case ImportResult.noFileSelected:
            message = 'Nem választottál ki fájlt.';
            color = Colors.orange;
            break;
          case ImportResult.invalidFormat:
            message = 'Érvénytelen fájlformátum!';
            color = Colors.red;
            break;
          case ImportResult.emptyFile:
            message = 'A kiválasztott fájl üres.';
            color = Colors.orange;
            break;
          case ImportResult.error:
            message = 'Hiba történt az importálás során.';
            color = Colors.red;
            break;
        }
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: color));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Hiba az importálás közben: $e'),
            backgroundColor: Colors.red));
      }
    }
    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _updateAndScheduleAllNotifications() async {
    await _ertesitesSzolgaltatas.cancelAllNotifications();
    if (!_notificationsEnabled) {
      print("Értesítések kikapcsolva, nincs mit időzíteni.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Értesítések kikapcsolva.'),
            backgroundColor: Colors.grey));
      }
      return;
    }
    final db = AdatbazisKezelo.instance;
    final vehicles =
        (await db.getVehicles()).map((map) => Jarmu.fromMap(map)).toList();
    int notificationId = 0;
    for (var vehicle in vehicles) {
      if (vehicle.muszakiErvenyesseg != null) {
        final muszakiDate = vehicle.muszakiErvenyesseg!;
        final now = DateTime.now();
        final oneMonthBefore = DateTime(
            muszakiDate.year, muszakiDate.month - 1, muszakiDate.day, 10);
        final oneWeekBefore = muszakiDate.subtract(const Duration(days: 7));
        if (oneMonthBefore.isAfter(now)) {
          await _ertesitesSzolgaltatas.scheduleNotification(
              id: notificationId++,
              title: 'Lejáró műszaki: ${vehicle.make}',
              body:
                  'A(z) ${vehicle.licensePlate} műszaki vizsgája 1 hónap múlva lejár.',
              scheduledDate: oneMonthBefore);
        }
        if (oneWeekBefore.isAfter(now)) {
          await _ertesitesSzolgaltatas.scheduleNotification(
              id: notificationId++,
              title: 'Lejáró műszaki: ${vehicle.make}',
              body:
                  'Figyelem! A(z) ${vehicle.licensePlate} műszaki vizsgája 1 hét múlva lejár!',
              scheduledDate: DateTime(oneWeekBefore.year, oneWeekBefore.month,
                  oneWeekBefore.day, 10));
        }
      }
    }
    if (vehicles.isNotEmpty) {
      await _ertesitesSzolgaltatas.scheduleWeeklyNotification(
          id: 999,
          title: 'Olajfolt Emlékeztető',
          body:
              'Ne felejtsd el frissíteni a km óra állást a pontos emlékeztetőkért!');
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Értesítések frissítve!'),
          backgroundColor: Colors.green));
    }
  }

  void _showInfoDialog() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Row(children: [
                Icon(Icons.info_outline, color: Colors.amber),
                SizedBox(width: 10),
                Text('Beállítások Működése',
                    style: TextStyle(color: Colors.white, fontSize: 18))
              ]),
              content: const SingleChildScrollView(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Adatkezelés',
                      style: TextStyle(
                          color: Colors.amber, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(
                    '• PDF Export: Egyetlen jármű szerviztörténetét menti egy szépen formázott adatlapra.\n'
                    '• CSV Export: Az ÖSSZES jármű és szerviz adatát elmenti egy egyszerű szöveges (.csv) fájlba. Ez a funkció az "app költöztetésére" és biztonsági mentésre szolgál.\n'
                    '• CSV Import: Visszatölti az összes adatot egy korábban mentett .csv fájlból. Figyelem, ez a művelet felülírja a jelenlegi adatokat!',
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 16),
                  Text('Értesítések',
                      style: TextStyle(
                          color: Colors.amber, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(
                      'A kapcsoló bekapcsolásával engedélyezed, hogy az alkalmazás a háttérben is küldjön emlékeztetőket a közelgő műszaki vizsgáról és hetente egyszer a kilométeróra állás frissítéséről.',
                      style: TextStyle(color: Colors.white70)),
                ],
              )),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Értem',
                        style: TextStyle(color: Colors.amber)))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Beállítások'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.amber),
              tooltip: 'Hogyan működik?',
              onPressed: _showInfoDialog)
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        children: [
          _buildSectionHeader(context, 'Adatkezelés'),
          KozosMenuKartya(
            icon: Icons.picture_as_pdf,
            title: 'Adatlap exportálása (PDF)',
            subtitle: 'Generálj egy adatlapot a járművedről',
            color: Colors.red.shade400,
            onTap: _isProcessing ? () {} : () => _handlePdfExport(),
            trailing: _isProcessing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.red))
                : null,
          ),
          KozosMenuKartya(
            icon: Icons.upload_file,
            title: 'Mentés exportálása (CSV)',
            subtitle: 'Minden adat kimentése egyetlen fájlba',
            color: Colors.blue.shade400,
            onTap: _isProcessing ? () {} : () => _handleCsvExport(),
            trailing: _isProcessing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.blue))
                : null,
          ),
          KozosMenuKartya(
            icon: Icons.download,
            title: 'Mentés importálása (CSV)',
            subtitle: 'Adatok visszatöltése mentésből',
            color: Colors.green.shade400,
            onTap: _isProcessing ? () {} : () => _handleCsvImport(),
            trailing: _isProcessing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.green))
                : null,
          ),
          const SizedBox(height: 20),
          _buildSectionHeader(context, 'Értesítések'),
          KozosMenuKartya(
            icon: Icons.notifications_active,
            title: 'Karbantartás értesítések',
            subtitle: 'Emlékeztetők a közelgő eseményekről',
            color: Colors.orange.shade400,
            onTap: () {},
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (bool value) async {
                setState(() {
                  _notificationsEnabled = value;
                });
                await _saveNotificationSetting(value);
                await _updateAndScheduleAllNotifications();
              },
              activeColor: Colors.orange.shade400,
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader(context, 'Információ'),
          KozosMenuKartya(
            icon: Icons.info_outline,
            title: 'Névjegy',
            subtitle: 'Verzió: 1.0.0',
            color: Colors.amber.shade400,
            // Lila helyett narancs
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 16.0, 16.0, 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.orange.shade700,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
