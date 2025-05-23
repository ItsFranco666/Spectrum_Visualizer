import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/spectrum_provider.dart';
import '../models/spectrum_data.dart';

class SpectrumChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SpectrumProvider>(
      builder: (context, provider, child) {
        if (provider.spectrumData == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.show_chart,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                SizedBox(height: 16),
                Text(
                  'No hay datos calculados',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Configure las señales y presione "Calcular"',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Espectro Radioeléctrico',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 16),
                        Expanded(
                          child: SpectrumLineChart(data: provider.spectrumData!),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              SpectrumInfo(data: provider.spectrumData!),
            ],
          ),
        );
      },
    );
  }
}

class SpectrumLineChart extends StatelessWidget {
  final SpectrumData data;

  SpectrumLineChart({required this.data});

  @override
  Widget build(BuildContext context) {
    // Crear puntos para el gráfico de línea continua
    List<FlSpot> spots = _generateSpectrumCurve();
    
    double noiseLevel = data.thermalNoise;
    double maxPower = data.signals.map((s) => s.power).reduce(math.max);
    double minPower = math.min(noiseLevel - 15, data.signals.map((s) => s.power).reduce(math.min) - 10);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawHorizontalLine: true,
              drawVerticalLine: true,
              horizontalInterval: 10,
              verticalInterval: (data.maxFrequency - data.minFrequency) / 8,
              getDrawingHorizontalLine: (value) {
                if ((value - noiseLevel).abs() < 2) {
                  return FlLine(
                    color: Colors.red.shade600,
                    strokeWidth: 2,
                    dashArray: [8, 4],
                  );
                }
                return FlLine(
                  color: Colors.grey.shade400,
                  strokeWidth: 0.8,
                );
              },
              getDrawingVerticalLine: (value) {
                return FlLine(
                  color: Colors.grey.shade400,
                  strokeWidth: 0.8,
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 35,
                  interval: (data.maxFrequency - data.minFrequency) / 6,
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        '${value.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 45,
                  interval: 10,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '${value.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(
                color: Colors.grey.shade600,
                width: 1.5,
              ),
            ),
            minX: data.minFrequency - 20,
            maxX: data.maxFrequency + 20,
            minY: minPower,
            maxY: maxPower + 10,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.2,
                color: Colors.blue.shade600,
                barWidth: 2.5,
                isStrokeCapRound: true,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.blue.shade400.withOpacity(0.7),
                      Colors.blue.shade300.withOpacity(0.5),
                      Colors.blue.shade200.withOpacity(0.3),
                      Colors.blue.shade100.withOpacity(0.1),
                    ],
                    stops: [0.0, 0.4, 0.7, 1.0],
                  ),
                ),
              ),
              // Línea de ruido térmico
              LineChartBarData(
                spots: [
                  FlSpot(data.minFrequency - 20, noiseLevel),
                  FlSpot(data.maxFrequency + 20, noiseLevel),
                ],
                isCurved: false,
                color: Colors.red.shade600,
                barWidth: 2,
                dashArray: [8, 4],
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
              // Marcadores de señales individuales
              ...data.signals.asMap().entries.map((entry) {
                int index = entry.key;
                var signal = entry.value;
                List<Color> signalColors = [
                  Colors.red.shade600,
                  Colors.blue.shade600,
                  Colors.green.shade600,
                  Colors.orange.shade600,
                  Colors.purple.shade600,
                  Colors.teal.shade600,
                ];
                Color signalColor = signalColors[index % signalColors.length];
                
                return LineChartBarData(
                  spots: [
                    FlSpot(signal.frequency - signal.bandwidth/2, signal.power),
                    FlSpot(signal.frequency, signal.power),
                    FlSpot(signal.frequency + signal.bandwidth/2, signal.power),
                  ],
                  isCurved: false,
                  color: signalColor,
                  barWidth: 3,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      if (index == 1) { // Solo mostrar punto en el centro
                        return FlDotCirclePainter(
                          radius: 4,
                          color: signalColor,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      }
                      return FlDotCirclePainter(radius: 0, color: Colors.transparent);
                    },
                  ),
                  belowBarData: BarAreaData(show: false),
                );
              }).toList(),
            ],
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                tooltipPadding: EdgeInsets.all(8),
                tooltipBorderRadius: BorderRadius.circular(8),
                getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                  return touchedBarSpots.map((barSpot) {
                    // Encontrar la señal más cercana
                    var closestSignal = data.signals.first;
                    double minDistance = double.infinity;
                    
                    for (var signal in data.signals) {
                      double distance = (signal.frequency - barSpot.x).abs();
                      if (distance < minDistance) {
                        minDistance = distance;
                        closestSignal = signal;
                      }
                    }
                    
                    if (minDistance < closestSignal.bandwidth) {
                      final snr = data.snrValues[closestSignal.id] ?? 0;
                      return LineTooltipItem(
                        'Señal ${closestSignal.id}\n'
                        'Freq: ${closestSignal.frequency.toStringAsFixed(1)} MHz\n'
                        'BW: ${closestSignal.bandwidth.toStringAsFixed(1)} MHz\n'
                        'Potencia: ${closestSignal.power.toStringAsFixed(2)} dBm\n'
                        'SNR: ${snr.toStringAsFixed(2)} dB',
                        TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }
                    
                    return LineTooltipItem(
                      'Freq: ${barSpot.x.toStringAsFixed(1)} MHz\n'
                      'Nivel: ${barSpot.y.toStringAsFixed(2)} dBm',
                      TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 11,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<FlSpot> _generateSpectrumCurve() {
    List<FlSpot> spots = [];
    double freqStart = data.minFrequency - 20;
    double freqEnd = data.maxFrequency + 20;
    double step = (freqEnd - freqStart) / 300; // Más puntos para mejor resolución
    
    for (double freq = freqStart; freq <= freqEnd; freq += step) {
      double maxPower = data.thermalNoise; // Empezar con el nivel de ruido
      
      // Encontrar la señal más fuerte en esta frecuencia
      for (var signal in data.signals) {
        double signalPower = _getSignalPower(freq, signal);
        if (signalPower > maxPower) {
          maxPower = signalPower;
        }
      }
      
      spots.add(FlSpot(freq, maxPower));
    }
    
    return spots;
  }

  double _getSignalPower(double frequency, dynamic signal) {
    double centerFreq = signal.frequency;
    double bandwidth = signal.bandwidth;
    double power = signal.power;
    
    // Calcular los límites de la señal
    double startFreq = centerFreq - (bandwidth / 2);
    double endFreq = centerFreq + (bandwidth / 2);
    
    if (frequency >= startFreq && frequency <= endFreq) {
      // Dentro del ancho de banda - forma rectangular con bordes suavizados
      double distanceFromCenter = (frequency - centerFreq).abs();
      double normalizedDistance = distanceFromCenter / (bandwidth / 2);
      
      if (normalizedDistance < 0.8) {
        // Parte plana de la señal
        return power;
      } else {
        // Transición suave en los bordes (roll-off)
        double rolloff = math.cos((normalizedDistance - 0.8) * math.pi / (2 * 0.2));
        return power + 20 * math.log(rolloff) / math.ln10;
      }
    }
    
    // Fuera del ancho de banda - retornar nivel de ruido
    return data.thermalNoise;
  }
}

class SpectrumInfo extends StatelessWidget {
  final SpectrumData data;

  SpectrumInfo({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics_outlined, color: Colors.blue.shade700),
                SizedBox(width: 8),
                Text(
                  'Análisis del Espectro',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildInfoColumn(
                    'SNR por Señal',
                    data.snrValues.entries.map((entry) {
                      Color snrColor = entry.value > 10 ? Colors.green : 
                                      entry.value > 0 ? Colors.orange : Colors.red;
                      return _buildColoredInfoItem(
                        'S${entry.key}: ${entry.value.toStringAsFixed(2)} dB',
                        snrColor,
                      );
                    }).toList(),
                  ),
                  SizedBox(width: 24),
                  _buildInfoColumn(
                    'Interferencias',
                    data.interferenceValues.isEmpty 
                      ? [_buildColoredInfoItem('No hay superposiciones', Colors.green)]
                      : data.interferenceValues.entries.map((entry) {
                          return _buildColoredInfoItem(
                            'S${entry.key}: ${entry.value.toStringAsFixed(2)} dB',
                            Colors.orange,
                          );
                        }).toList(),
                  ),
                  SizedBox(width: 24),
                  _buildInfoColumn(
                    'Parámetros del Sistema',
                    [
                      _buildInfoItem('Temperatura: ${data.temperature.toStringAsFixed(1)}°K'),
                      _buildInfoItem('BW Sistema: ${data.systemBandwidth.toStringAsFixed(1)} MHz'),
                      _buildInfoItem('Nivel de Ruido: ${data.thermalNoise.toStringAsFixed(2)} dBm'),
                      _buildInfoItem('Rango Freq: ${data.frequencyRange.toStringAsFixed(1)} MHz'),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Divider(),
            SizedBox(height: 8),
            Row(
              children: [
                _buildLegendItem(Colors.blue.shade600, 'Espectro de Potencia'),
                SizedBox(width: 20),
                _buildLegendItem(Colors.red.shade600, 'Ruido Térmico'),
                SizedBox(width: 20),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: Colors.grey.shade600),
                    SizedBox(width: 4),
                    Text(
                      'Señales Individuales',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.blue.shade700,
          ),
        ),
        SizedBox(height: 8),
        ...items,
      ],
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildColoredInfoItem(String text, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}