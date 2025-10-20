import 'dart:io';
import 'package:car_maintenance_app/alap/adatbazis/adatbazis_kezelo.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

enum ImportResult { success, error, noFileSelected, invalidFormat, emptyFile }

class CsvSzolgaltatas {
  // Új, megbízhatóbb mentési logika
  Future<String?> getDownloadPath() async {
    Directory? directory;
    try {
      if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else { // Android és egyéb platformok
        // A getExternalStorageDirectory a legtöbb Android verzión a felhasználó által
        // látható belső tárhely gyökerére mutat.
        directory = await getExternalStorageDirectory();
        if (directory == null) {
          print("Hiba: A külső tárhely nem elérhető.");
          return null;
        }

        // Manuálisan hozzuk létre a "Download" mappát a gyökérben, ha még nem létezik.
        String downloadPath = '${directory.path}/Download';
        final downloadDir = Directory(downloadPath);
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }
        directory = downloadDir;
      }
    } catch (err) {
      print("Hiba a mentési mappa elérésekor: $err");
    }
    return directory?.path;
  }

  Future<String?> exportAllDataToCsv() async {
    if (Platform.isAndroid) {
      var status = await Permission.storage.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        return "permission_denied";
      }
    }

    final db = AdatbazisKezelo.instance;
    final List<Map<String, dynamic>> vehicles = await db.getVehicles();
    final List<Map<String, dynamic>> services = await db.getServices();

    if (vehicles.isEmpty && services.isEmpty) {
      return "empty";
    }

    String vehicleCsv = "";
    if (vehicles.isNotEmpty) {
      List<List<dynamic>> vehicleRows = [
        vehicles.first.keys.toList(),
        ...vehicles.map((v) => v.values.toList())
      ];
      vehicleCsv = const ListToCsvConverter().convert(vehicleRows);
    }
    String serviceCsv = "";
    if (services.isNotEmpty) {
      List<List<dynamic>> serviceRows = [
        services.first.keys.toList(),
        ...services.map((s) => s.values.toList())
      ];
      serviceCsv = const ListToCsvConverter().convert(serviceRows);
    }

    String combinedCsv = "---VEHICLES---\n$vehicleCsv\n---SERVICES---\n$serviceCsv";

    try {
      final path = await getDownloadPath();
      if (path == null) return null;

      final String formattedDate = DateFormat('yyyy-MM-dd_HH-mm').format(
          DateTime.now());
      final String fileName = "olajfolt_mentes_$formattedDate.csv";
      final File file = File("$path/$fileName");

      await file.writeAsString(combinedCsv);
      print("Sikeres exportálás ide: ${file.path}");
      return file.path;
    } catch (e) {
      print("Hiba a CSV exportálás során: $e");
      return null;
    }
  }

  // Javított, "bolondbiztos" import logika
  Future<ImportResult> importDataFromCsv() async {
    final result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['csv']);
    if (result == null || result.files.single.path == null) {
      return ImportResult.noFileSelected;
    }

    File file = File(result.files.single.path!);

    try {
      final String content = await file.readAsString();
      if (content
          .trim()
          .isEmpty) {
        return ImportResult.emptyFile;
      }
      if (!content.contains('---VEHICLES---') ||
          !content.contains('---SERVICES---')) {
        return ImportResult.invalidFormat;
      }

      final parts = content.split('---SERVICES---');
      final vehiclePart = parts[0].replaceFirst('---VEHICLES---', '').trim();
      final servicePart = parts.length > 1 ? parts[1].trim() : '';

      final db = AdatbazisKezelo.instance;
      await db.clearAllData();

      if (vehiclePart.isNotEmpty) {
        List<List<dynamic>> vehicleRows = const CsvToListConverter(
            shouldParseNumbers: false).convert(vehiclePart);
        if (vehicleRows.length > 1) {
          List<String> headers = vehicleRows[0]
              .map((h) => h.toString())
              .toList();
          for (int i = 1; i < vehicleRows.length; i++) {
            Map<String, dynamic> rowMap = Map.fromIterables(
                headers, vehicleRows[i]);

            // Biztonságos konverziók
            rowMap['id'] = int.tryParse(rowMap['id'].toString());
            rowMap['year'] = int.tryParse(rowMap['year'].toString());
            rowMap['mileage'] = int.tryParse(rowMap['mileage'].toString());

            // === DÁTUM ELLENŐRZÉS: EZ OLDJA MEG AZ IOS HIBÁT ===
            if (rowMap['muszakiErvenyesseg'] == null ||
                rowMap['muszakiErvenyesseg']
                    .toString()
                    .isEmpty) {
              rowMap['muszakiErvenyesseg'] = null;
            } else {
              // Itt nem kell újra formázni, az adatbázis a Stringet várja
            }

            await db.insert('vehicles', rowMap);
          }
        }
      }

      if (servicePart.isNotEmpty) {
        List<List<dynamic>> serviceRows = const CsvToListConverter(
            shouldParseNumbers: false).convert(servicePart);
        if (serviceRows.length > 1) {
          List<String> headers = serviceRows[0]
              .map((h) => h.toString())
              .toList();
          for (int i = 1; i < serviceRows.length; i++) {
            Map<String, dynamic> rowMap = Map.fromIterables(
                headers, serviceRows[i]);

            rowMap['id'] = int.tryParse(rowMap['id'].toString());
            rowMap['vehicleId'] = int.tryParse(rowMap['vehicleId'].toString());
            rowMap['mileage'] = int.tryParse(rowMap['mileage'].toString());
            rowMap['cost'] = num.tryParse(rowMap['cost'].toString());

            if (rowMap['date'] == null || rowMap['date']
                .toString()
                .isEmpty) {
              rowMap['date'] = DateTime.now().toIso8601String();
            }

            await db.insert('services', rowMap);
          }
        }
      }
      return ImportResult.success;
    } catch (e) {
      print("Hiba a CSV importálás során: $e");
      return ImportResult.error;
    }
  }
}