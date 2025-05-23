import 'dart:math' as math;
import 'signal.dart';

class SpectrumData {
  final List<Signal> signals;
  final double temperature; // en Kelvin
  final double systemBandwidth; // en MHz
  final double thermalNoise; // en dBm
  final Map<int, double> snrValues;
  final Map<String, double> interferenceValues;

  SpectrumData({
    required this.signals,
    required this.temperature,
    required this.systemBandwidth,
    required this.thermalNoise,
    required this.snrValues,
    required this.interferenceValues,
  });

  double get minFrequency {
    if (signals.isEmpty) return 0;
    return signals.map((s) => s.startFreq).reduce(math.min);
  }

  double get maxFrequency {
    if (signals.isEmpty) return 100;
    return signals.map((s) => s.endFreq).reduce(math.max);
  }

  double get frequencyRange => maxFrequency - minFrequency;
}