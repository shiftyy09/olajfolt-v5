// lib/szolgaltatasok/uzemanyag_ar_szolgaltatas.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class UzemanyagArak {
  final double benzinAr;
  final double gazolajAr;

  UzemanyagArak({required this.benzinAr, required this.gazolajAr});
}

class UzemanyagArSzolgaltatas {
  final String _apiUrl = "https://hu.fuelo.net/api/price.json";

  Future<UzemanyagArak?> fetchFuelPrices() async {
    try {
      // === VISSZAÁLLÍTOTTUK A USER-AGENTET A BIZTONSÁG KEDVÉÉRT ===
      final response = await http.get(
        Uri.parse(_apiUrl),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36',
        },
      );
      // ========================================================

      if (response.statusCode == 200) {
        // A Fuelo.net API JSON struktúrájának feldolgozása
        final Map<String, dynamic> data = json.decode(response.body);

        if (data.containsKey('fuels')) {
          final fuels = data['fuels'];
          final double benzin = (fuels['unleaded95'] as num?)?.toDouble() ?? 0;
          final double gazolaj = (fuels['diesel'] as num?)?.toDouble() ?? 0;

          if (benzin > 0 && gazolaj > 0) {
            print(
                "Üzemanyagárak sikeresen lekérdezve (Fuelo.net): Benzin: $benzin, Gázolaj: $gazolaj");
            return UzemanyagArak(benzinAr: benzin, gazolajAr: gazolaj);
          }
        }
      }

      print("API hiba (Fuelo.net): ${response.statusCode}");
      print("Válasz törzse: ${response.body}"); // Ez segít a hibakeresésben
      return null;
    } catch (e) {
      print("Hiba az üzemanyagárak lekérdezése közben (Fuelo.net): $e");
      return null;
    }
  }
}
