import 'dart:io';
import 'package:car_maintenance_app/alap/adatbazis/adatbazis_kezelo.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

// Enum az importálás eredményének jelzésére a felhasználói felület felé.
enum ImportResult { success, error, noFileSelected, invalidFormat, emptyFile }

class CsvSzolgaltatas {
  /// Az összes jármű- és szervizadatot egyetlen CSV fájlba exportálja.
  Future<String?> exportAllDataToCsv() async {
    if (Platform.isAndroid) {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      if (deviceInfo.version.sdkInt <= 28) {
        final status = await Permission.storage.request();
        if (status.isDenied || status.isPermanentlyDenied) {
          print("Tárhely hozzáférés elutasítva.");
          openAppSettings();
          return "permission_denied";
        }
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
      List<List<dynamic>> vehicleRows = [];
      vehicleRows.add(vehicles.first.keys.toList());
      for (var vehicle in vehicles) {
        vehicleRows.add(vehicle.values.toList());
      }
      vehicleCsv = const ListToCsvConverter().convert(vehicleRows);
    }

    String serviceCsv = "";
    if (services.isNotEmpty) {
      List<List<dynamic>> serviceRows = [];
      serviceRows.add(services.first.keys.toList());
      for (var service in services) {
        serviceRows.add(service.values.toList());
      }
      serviceCsv = const ListToCsvConverter().convert(serviceRows);
    }

    String combinedCsv = "---VEHICLES---\n$vehicleCsv\n---SERVICES---\n$serviceCsv";

    try {
      final directory = await getDownloadsDirectory();
      if (directory == null) return null;

      final String formattedDate = DateFormat('yyyy-MM-dd_HH-mm').format(
          DateTime.now());
      final path = "${directory.path}/olajfolt_mentes_$formattedDate.csv";
      final file = File(path);
      await file.writeAsString(combinedCsv);
      print("Sikeres exportálás ide: $path");
      return path;
    } catch (e) {
      print("Hiba a CSV exportálás során: $e");
      return null;
    }
  }

  /// Elindítja az adatimportálási folyamatot.
  Future<ImportResult> importDataFromCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result == null || result.files.single.path == null) {
      print("Nincs fájl kiválasztva.");
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
        print("Érvénytelen CSV formátum: hiányoznak a szeparátorok.");
        return ImportResult.invalidFormat;
      }

      final parts = content.split('---SERVICES---');
      final vehiclePart = parts[0].replaceFirst('---VEHICLES---', '').trim();
      final servicePart = parts.length > 1 ? parts[1].trim() : '';

      final db = AdatbazisKezelo.instance;

      await db.clearAllData();
      print("Adatbázis törölve importálás előtt.");

      // Járművek importálása
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

            rowMap['id'] = int.tryParse(rowMap['id'].toString());
            rowMap['year'] = int.tryParse(rowMap['year'].toString());

            await db.insert('vehicles', rowMap);
          }
          print("${vehicleRows.length - 1} jármű importálva.");
        }
      }

      // Szervizek importálása
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
            rowMap['cost'] =
                num.tryParse(rowMap['cost'].toString()); // .toInt() eltávolítva

            await db.insert('services', rowMap);
          }
          print("${serviceRows.length - 1} szervizbejegyzés importálva.");
        }
      }

      return ImportResult.success;
    } catch (e) {
      print("Hiba a CSV importálás során: $e");
      return ImportResult.error;
    }
  }
}