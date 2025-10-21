class Jarmu {
  final int? id;
  final String make;
  final String model;
  final int year;
  final String licensePlate;
  final String? vin;
  final int mileage;
  final String? vezerlesTipusa;
  final String? imagePath;
  final DateTime? muszakiErvenyesseg; // <<<--- ÚJ MEZŐ

  Jarmu({
    this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.licensePlate,
    this.vin,
    required this.mileage,
    this.vezerlesTipusa,
    this.imagePath,
    this.muszakiErvenyesseg, // <<<--- ÚJ PARAMÉTER
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'make': make,
      'model': model,
      'year': year,
      'licensePlate': licensePlate,
      'vin': vin,
      'mileage': mileage,
      'vezerlesTipusa': vezerlesTipusa,
      'imagePath': imagePath,
      'muszakiErvenyesseg': muszakiErvenyesseg?.toIso8601String(), // <<<--- ÚJ
    };
  }

  factory Jarmu.fromMap(Map<String, dynamic> map) {
    return Jarmu(
      id: map['id'] as int?,
      make: map['make'] as String,
      model: map['model'] as String,
      year: map['year'] as int,
      licensePlate: map['licensePlate'] as String,
      vin: map['vin'] as String?,
      mileage: map['mileage'] as int,
      vezerlesTipusa: map['vezerlesTipusa'] as String?,
      imagePath: map['imagePath'] as String?,
      muszakiErvenyesseg: map['muszakiErvenyesseg'] == null
          ? null
          : DateTime.parse(map['muszakiErvenyesseg'] as String), // <<<--- ÚJ
    );
  }

  Jarmu copyWith({
    int? id,
    String? make,
    String? model,
    int? year,
    String? licensePlate,
    String? vin,
    int? mileage,
    String? vezerlesTipusa,
    String? imagePath,
    DateTime? muszakiErvenyesseg, // <<<--- ÚJ
  }) {
    return Jarmu(
      id: id ?? this.id,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      licensePlate: licensePlate ?? this.licensePlate,
      vin: vin ?? this.vin,
      mileage: mileage ?? this.mileage,
      vezerlesTipusa: vezerlesTipusa ?? this.vezerlesTipusa,
      imagePath: imagePath ?? this.imagePath,
      muszakiErvenyesseg:
          muszakiErvenyesseg ?? this.muszakiErvenyesseg, // <<<--- ÚJ
    );
  }
}
