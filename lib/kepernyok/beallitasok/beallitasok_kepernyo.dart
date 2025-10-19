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
  bool _notificationsEnabled = false;

  final PdfSzolgaltatas _pdfSzolgaltatas = PdfSzolgaltatas();
  final CsvSzolgaltatas _csvSzolgaltatas = CsvSzolgaltatas();
  bool _isExporting = false;
  bool _isImporting = false;

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

  void _saveNotificationSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', value);
  }

  Future<void> _updateAndScheduleAllNotifications() async {
    // ... a te meglévő értesítés-kezelő kódod ...
  }

  Future<void> _handlePdfExport() async {
    // ... a te meglévő PDF export kódod ...
  }

  Future<void> _handleCsvExport() async {
    // ... a te meglévő CSV export kódod ...
  }

  Future<void> _handleCsvImport() async {
    // ... a te meglévő CSV import kódod ...
  }

  // ========================================================
  // ===     ÚJ INFORMÁCIÓS DIALÓGUS A BEÁLLÍTÁSOKHOZ      ===
  // ========================================================
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
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
                  Text('Adatkezelés', style: TextStyle(
                      color: Colors.amber, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(
                    '• PDF Export: Egyetlen jármű szerviztörténetét menti egy szépen formázott adatlapra.\n'
                        '• CSV Export: Az ÖSSZES jármű és szerviz adatát elmenti egy egyszerű szöveges (.csv) fájlba. Ez a funkció az "app költöztetésére" és biztonsági mentésre szolgál.\n'
                        '• CSV Import: Visszatölti az összes adatot egy korábban mentett .csv fájlból. Figyelem, ez a művelet felülírja a jelenlegi adatokat!',
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 16),
                  Text('Értesítések', style: TextStyle(
                      color: Colors.amber, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(
                    'A kapcsoló bekapcsolásával engedélyezed, hogy az alkalmazás a háttérben is küldjön emlékeztetőket a közelgő műszaki vizsgáról és hetente egyszer a kilométeróra állás frissítéséről.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                    'Értem', style: TextStyle(color: Colors.amber)),
              )
            ],
          ),
    );
  }

  // ========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Beállítások'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        // ======================================================
        // ===     ÚJ IKON GOMB AZ APPBAR-BAN A SEGÍTSÉGHEZ    ===
        // ======================================================
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.amber),
            tooltip: 'Hogyan működik?',
            onPressed: _showInfoDialog,
          ),
        ],
        // ======================================================
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
            onTap: _isExporting ? () {} : () => _handlePdfExport(),
            trailing: _isExporting
                ? const SizedBox(width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2))
                : null,
          ),
          KozosMenuKartya(
            icon: Icons.upload_file,
            title: 'Mentés exportálása (CSV)',
            subtitle: 'Minden adat kimentése egyetlen fájlba',
            color: Colors.blue.shade400,
            onTap: _isExporting ? () {} : () => _handleCsvExport(),
            trailing: _isExporting
                ? const SizedBox(width: 24,
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
            onTap: _isImporting ? () {} : () => _handleCsvImport(),
            trailing: _isImporting
                ? const SizedBox(width: 24,
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
                _saveNotificationSetting(value);
                await _updateAndScheduleAllNotifications();
              },
              activeColor: Colors.orange.shade400,
            ),
          ),

          const SizedBox(height: 20),

          // === A NÉVJEGY SZEKCIÓT KIVETTÜK, MERT A FUNKCIÓJA FELKÖLTÖZÖTT AZ APPBAR-BA ===
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