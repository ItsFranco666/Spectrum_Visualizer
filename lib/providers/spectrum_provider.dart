import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/signal.dart';
import '../models/spectrum_data.dart';

class SpectrumProvider extends ChangeNotifier {
  static const double BOLTZMANN_CONSTANT = 1.38064852e-23; // J/K
  static const int MAX_SIGNALS = 10; // Maximum number of signals allowed
  
  int _numberOfSignals = 3;
  List<Signal> _signals = [];
  double _temperature = 290.0; // Kelvin
  double _systemBandwidth = 100.0; // MHz
  SpectrumData? _spectrumData;
  bool _isLoading = false;

  int get numberOfSignals => _numberOfSignals;
  List<Signal> get signals => _signals;
  double get temperature => _temperature;
  double get systemBandwidth => _systemBandwidth;
  SpectrumData? get spectrumData => _spectrumData;
  bool get isLoading => _isLoading;

  void setNumberOfSignals(int count) {
    // Network limit validation: Ensure maximum of 10 networks
    if (count < 3 || count > MAX_SIGNALS) return;
    _numberOfSignals = count;
    _initializeSignals();
    notifyListeners();
  }

  void _initializeSignals() {
    _signals = List.generate(_numberOfSignals, (index) => Signal(
      id: index + 1,
      power: -20.0,
      bandwidth: 10.0,
      frequency: 50.0 + (index * 30.0),
      powerUnit: 'dBm',
      originalPower: -20.0,
    ));
  }

  void updateSignal(int index, {
    double? power,
    double? bandwidth,
    double? frequency,
    String? powerUnit,
  }) {
    if (index >= _signals.length) return;
    
    Signal signal = _signals[index];
    
    if (power != null && powerUnit != null) {
      signal.originalPower = power;
      signal.powerUnit = powerUnit;
      signal.power = Signal.convertTodBm(power, powerUnit);
    }
    if (bandwidth != null) signal.bandwidth = bandwidth;
    if (frequency != null) signal.frequency = frequency;
    
    notifyListeners();
  }

  void setTemperature(double temp) {
    _temperature = temp;
    notifyListeners();
  }

  void setSystemBandwidth(double bw) {
    _systemBandwidth = bw;
    notifyListeners();
  }

  Future<void> calculateSpectrum() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(Duration(milliseconds: 500)); // Simular cálculo

    // Calcular ruido térmico
    double thermalNoise = _calculateThermalNoise();
    
    // Calcular SNR para cada señal
    Map<int, double> snrValues = {};
    for (Signal signal in _signals) {
      snrValues[signal.id] = signal.power - thermalNoise;
    }

    // Calcular interferencias entre señales adyacentes
    Map<String, double> interferenceValues = {};
    for (int i = 0; i < _signals.length; i++) {
      for (int j = i + 1; j < _signals.length; j++) {
        Signal signal1 = _signals[i];
        Signal signal2 = _signals[j];
        
        if (signal1.overlaps(signal2)) {
          double interference = _calculateInterference(signal1, signal2);
          interferenceValues['${signal1.id}-${signal2.id}'] = interference;
        }
      }
    }

    _spectrumData = SpectrumData(
      signals: List.from(_signals),
      temperature: _temperature,
      systemBandwidth: _systemBandwidth,
      thermalNoise: thermalNoise,
      snrValues: snrValues,
      interferenceValues: interferenceValues,
    );

    _isLoading = false;
    notifyListeners();
    await _saveConfiguration();
  }

  double _calculateThermalNoise() {
    // N = 10*log10(k * T * Bw * 10^6) + 30 [dBm]
    double noise = 10 * (BOLTZMANN_CONSTANT * _temperature * _systemBandwidth * 1e6).log10() + 30;
    return noise;
  }

  double _calculateInterference(Signal signal1, Signal signal2) {
    // Calcular interferencia basada en superposición espectral
    double overlapStart = math.max(signal1.startFreq, signal2.startFreq);
    double overlapEnd = math.min(signal1.endFreq, signal2.endFreq);
    double overlapBandwidth = overlapEnd - overlapStart;
    
    if (overlapBandwidth <= 0) return 0;
    
    // Interferencia proporcional a la superposición y diferencia de potencia
    double powerDiff = (signal1.power - signal2.power).abs();
    double interferenceRatio = overlapBandwidth / math.min(signal1.bandwidth, signal2.bandwidth);
    
    return powerDiff * interferenceRatio;
  }

  Future<void> _saveConfiguration() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      Map<String, dynamic> config = {
        'numberOfSignals': _numberOfSignals,
        'temperature': _temperature,
        'systemBandwidth': _systemBandwidth,
        'signals': _signals.map((s) => s.toJson()).toList(),
      };
      await prefs.setString('spectrum_config', jsonEncode(config));
    } catch (e) {
      print('Error saving configuration: $e');
    }
  }

  Future<void> loadConfiguration() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? configString = prefs.getString('spectrum_config');
      
      if (configString != null) {
        Map<String, dynamic> config = jsonDecode(configString);
        int loadedSignals = config['numberOfSignals'] ?? 3;
        // Apply network limit validation when loading
        _numberOfSignals = loadedSignals > MAX_SIGNALS ? MAX_SIGNALS : loadedSignals;
        _temperature = config['temperature'] ?? 290.0;
        _systemBandwidth = config['systemBandwidth'] ?? 100.0;
        
        if (config['signals'] != null) {
          _signals = (config['signals'] as List)
              .map((s) => Signal.fromJson(s))
              .toList();
        } else {
          _initializeSignals();
        }
        
        notifyListeners();
      } else {
        _initializeSignals();
      }
    } catch (e) {
      print('Error loading configuration: $e');
      _initializeSignals();
    }
  }
}