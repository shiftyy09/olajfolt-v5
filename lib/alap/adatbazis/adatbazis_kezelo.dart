// lib/alap/adatbazis/adatbazis_kezelo.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AdatbazisKezelo {
  static final AdatbazisKezelo instance = AdatbazisKezelo._privateConstructor();
  static Database? _database;

  AdatbazisKezelo._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('car_maintenance.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path,
        version: 6, // <<<--- NÖVELD MEG A VERZIÓSZÁMOT!
        onCreate: _createAllTables,
        onUpgrade: _onUpgrade);
  }

  Future<void> _createAllTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        make TEXT NOT NULL,
        model TEXT NOT NULL,
        year INTEGER NOT NULL,
        licensePlate TEXT NOT NULL UNIQUE,
        vin TEXT,
        mileage INTEGER NOT NULL,
        vezerlesTipusa TEXT,
        imagePath TEXT,
        muszakiErvenyesseg TEXT -- <<<--- ÚJ OSZLOP HOZZÁADVA
      )
    ''');

    await db.execute('''
      CREATE TABLE services (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicleId INTEGER NOT NULL,
        description TEXT NOT NULL,
        date TEXT NOT NULL,
        mileage INTEGER NOT NULL,
        cost REAL NOT NULL,
        FOREIGN KEY (vehicleId) REFERENCES vehicles(id) ON DELETE CASCADE
      )
    ''');
  }

  // Ez a metódus lefut, ha a verziószám magasabb, mint az előző
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Egyszerűsített megoldás: Eldobjuk a régi táblákat és újra létrehozzuk őket.
    // Ez fejlesztés alatt a legegyszerűbb. Később lehet finomítani, hogy ne törölje az adatokat.
    await db.execute('DROP TABLE IF EXISTS services');
    await db.execute('DROP TABLE IF EXISTS vehicles');
    await _createAllTables(db, newVersion);
    print(
        "Adatbázis séma frissítve $oldVersion verzióról $newVersion verzióra.");
  }

  // ... (A többi függvényed, mint pl. getVehicles, insert, stb. itt változatlan marad)
  Future<int> insert(String table, Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert(table, row);
  }

  Future<List<Map<String, dynamic>>> queryAllRows(String table) async {
    final db = await database;
    return await db.query(table);
  }

  Future<int> update(String table, Map<String, dynamic> row) async {
    final db = await database;
    int id = row['id'];
    return await db.update(table, row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(String table, int id) async {
    final db = await database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getVehicles() async {
    final db = await database;
    return await db.query('vehicles', orderBy: 'make, model');
  }

  Future<List<Map<String, dynamic>>> getServices() async {
    final db = await database;
    return await db.query('services');
  }

  Future<List<Map<String, dynamic>>> getServicesForVehicle(
      int vehicleId) async {
    final db = await database;
    return await db.query('services',
        where: 'vehicleId = ?',
        whereArgs: [vehicleId],
        orderBy: 'date DESC, mileage DESC');
  }

  Future<int> deleteServicesForVehicle(int vehicleId) async {
    final db = await database;
    return await db
        .delete('services', where: 'vehicleId = ?', whereArgs: [vehicleId]);
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('services');
    await db.delete('vehicles');
  }
}
