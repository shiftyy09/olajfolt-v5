import 'package:car_maintenance_app/szolgaltatasok/csv_szolgaltatas.dart';
import 'package:car_maintenance_app/szolgaltatasok/pdf_szolgaltatas.dart';
import 'package:car_maintenance_app/widgetek/kozos_menu_kartya.dart';
import 'package:flutter/material.dart';

class BeallitasokKepernyo extends StatefulWidget {
  const BeallitasokKepernyo({super.key});

  @override
  State<BeallitasokKepernyo> createState() => _BeallitasokKepernyoState();
}

class _BeallitasokKepernyoState extends State<BeallitasokKepernyo> {
  final PdfSzolgaltatas _pdfSzolgaltatas = PdfSzolgaltatas();
  final CsvSzolgaltatas _csvSzolgaltatas = CsvSzolgaltatas();
  bool _isExporting = false;
  bool _isImporting = false;

  Future<void> _handleCsvExport() async {
    setState(() => _isExporting = true);
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
    setState(() => _isExporting = false);
  }

  Future<void> _handleCsvImport() async {
    final bool? confirmed = await showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Figyelem!'),
            content: const Text(
                'Az importálás felülírja az összes jelenlegi adatodat. Biztosan folytatod?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Mégse')),
              TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Folytatás')),
            ],
          ),
    );
    if (confirmed != true) return;
    setState(() => _isImporting = true);
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
    setState(() => _isImporting = false);
  }

  Future<void> _handlePdfExport() async {
    // A te meglévő PDF export logikád
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Beállítások'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                ? const SizedBox(
                width: 24,
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
            onTap: _isImporting ? () {} : () => _handleCsvImport(),
            trailing: _isImporting
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
            subtitle: 'Értesítés a közelgő eseményekről',
            color: Colors.orange.shade400,
            onTap: () {},
            trailing: Switch(
              value: false,
              onChanged: (bool value) {},
              activeColor: Colors.orange.shade400,
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader(context, 'Információ'),
          KozosMenuKartya(
            icon: Icons.info_outline,
            title: 'Névjegy',
            subtitle: 'Verzió: 1.0.0',
            color: Colors.purple.shade300,
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