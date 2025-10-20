// lib/szolgaltatasok/uzemanyag_ar_szolgaltatas.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

// Egy egyszerű osztály, ami a két árat tárolja
class UzemanyagArak {
  final double benzinAr;
  final double gazolajAr;

  UzemanyagArak({required this.benzinAr, required this.gazolajAr});
}

class UzemanyagArSzolgaltatas {
  // A Holtankoljak.hu API végpontja
  final String _apiUrl = "https://holtankoljak.hu/api/holtankoljak.json";

  Future<UzemanyagArak?> fetchFuelPrices() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl));

      if (response.statusCode == 200) {
        // Ha a kérés sikeres (200 OK)
        final List<dynamic> data = json.decode(response.body);

        // Keressük meg a benzin és gázolaj árakat a listában
        double benzin = 0;
        double gazolaj = 0;

        for (var item in data) {
          if (item['fuel_type'] == '95') {
            benzin = (item['price'] as num).toDouble();
          } else if (item['fuel_type'] == 'gasoil') {
            gazolaj = (item['price'] as num).toDouble();
          }
        }

        if (benzin > 0 && gazolaj > 0) {
          print(
              "Üzemanyagárak sikeresen lekérdezve: Benzin: $benzin, Gázolaj: $gazolaj");
          return UzemanyagArak(benzinAr: benzin, gazolajAr: gazolaj);
        }
      }
      // Ha a kérés sikertelen, vagy nem találtuk az árakat
      print("API hiba: ${response.statusCode}");
      return null;
    } catch (e) {
      // Ha bármilyen hiba történik (pl. nincs internet)
      print("Hiba az üzemanyagárak lekérdezése közben: $e");
      return null;
    }
  }
}