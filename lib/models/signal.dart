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

  double get startFreq => frequency - (bandwidth / 2);
  double get endFreq => frequency + (bandwidth / 2);

  bool overlaps(Signal other) {
    return !(endFreq <= other.startFreq || startFreq >= other.endFreq);
  }

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

// Extension para logaritmo base 10
extension MathExtensions on double {
  double log10() => this > 0 ? (math.log(this) / 2.302585092994046) : double.negativeInfinity;
}