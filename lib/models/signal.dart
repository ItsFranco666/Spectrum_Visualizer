import 'dart:math' as math;

class Signal {
  final int id;
  double power; // en dBm
  double bandwidth; // en MHz
  double frequency; // en MHz
  String powerUnit;
  double originalPower;

  Signal({
    required this.id,
    required this.power,
    required this.bandwidth,
    required this.frequency,
    this.powerUnit = 'dBm',
    required this.originalPower,
  });

  // Conversión de potencia a dBm
  
  static double convertTodBm(double value, String unit) {
    switch (unit) {
      case 'W':
        return 10 * (value.log10()) + 30;
      case 'mW':
        return 10 * (value.log10());
      case 'dBW':
        return value + 30;
      case 'dBm':
      default:
        return value;
    }
  }
  //Rango de frecuencia
  double get startFreq => frequency - (bandwidth / 2);
  double get endFreq => frequency + (bandwidth / 2);
  // Sobreposición de señales
  /// Verifica si esta señal se superpone con otra señal.
  bool overlaps(Signal other) {
    return !(endFreq <= other.startFreq || startFreq >= other.endFreq);
  }
  //Convierte el objeto a JSON cuyo valores vuelven a ser creados en un json
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'power': power,
      'bandwidth': bandwidth,
      'frequency': frequency,
      'powerUnit': powerUnit,
      'originalPower': originalPower,
    };
  }

  static Signal fromJson(Map<String, dynamic> json) {
    return Signal(
      id: json['id'],
      power: json['power'],
      bandwidth: json['bandwidth'],
      frequency: json['frequency'],
      powerUnit: json['powerUnit'],
      originalPower: json['originalPower'],
    );
  }
}

// Extension para logaritmo base 10, permite usar value.log10() directamente en lugar de escribir la formula completa
extension MathExtensions on double {
  double log10() => this > 0 ? (math.log(this) / 2.302585092994046) : double.negativeInfinity;
}