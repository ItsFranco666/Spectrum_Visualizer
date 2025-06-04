import 'dart:math' as math;
import 'signal.dart';
//Clase general de los datos del espectro
class SpectrumData {
  final List<Signal> signals; //Una lista de señales
  final double temperature; // en Kelvin
  final double systemBandwidth; // en MHz
  final double thermalNoise; // en dBm
  final Map<int, double> snrValues; //Valores de SNR
  final Map<String, double> interferenceValues;

  SpectrumData({
    required this.signals,
    required this.temperature,
    required this.systemBandwidth,
    required this.thermalNoise,
    required this.snrValues,
    required this.interferenceValues,
  });

  //Devuelve la frecuencia más baja ocupada por alguna señal del espectro.
  double get minFrequency {
    if (signals.isEmpty) return 0;
    return signals.map((s) => s.startFreq).reduce(math.min);
  }
  
  //Devuelve la frecuencia más baja ocupada por alguna señal del espectro.
  double get maxFrequency {
    if (signals.isEmpty) return 100;
    return signals.map((s) => s.endFreq).reduce(math.max);
  }
  //Calcula el rango total de frecuencias cubierto por las señales presentes en el espectro.
  double get frequencyRange => maxFrequency - minFrequency;
}