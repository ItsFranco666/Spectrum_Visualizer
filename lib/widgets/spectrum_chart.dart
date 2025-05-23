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
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
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
              verticalInterval: (data.maxFrequency - data.minFrequency) / 6,
              getDrawingHorizontalLine: (value) {
                if ((value - noiseLevel).abs() < 2) {
                  return FlLine(
                    color: Colors.red.shade400,
                    strokeWidth: 1.5,
                    dashArray: [8, 4],
                  );
                }
                return FlLine(
                  color: Colors.grey.shade700,
                  strokeWidth: 0.5,
                );
              },
              getDrawingVerticalLine: (value) {
                return FlLine(
                  color: Colors.grey.shade700,
                  strokeWidth: 0.5,
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 35,
                  interval: (data.maxFrequency - data.minFrequency) / 5,
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        '${value.toStringAsFixed(0)} MHz',
                        style: TextStyle(
                          color: Colors.grey.shade300,
                          fontSize: 10,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50,
                  interval: 10,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '${value.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 10,
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
                width: 1,
              ),
            ),
            minX: data.minFrequency - 10,
            maxX: data.maxFrequency + 10,
            minY: minPower,
            maxY: maxPower + 10,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.3,
                color: Colors.cyan.shade400,
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.cyan.shade400.withOpacity(0.6),
                      Colors.cyan.shade400.withOpacity(0.3),
                      Colors.cyan.shade400.withOpacity(0.1),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
              ),
              // Línea de ruido térmico
              LineChartBarData(
                spots: [
                  FlSpot(data.minFrequency - 10, noiseLevel),
                  FlSpot(data.maxFrequency + 10, noiseLevel),
                ],
                isCurved: false,
                color: Colors.red.shade400,
                barWidth: 1.5,
                dashArray: [8, 4],
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
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
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }
                    
                    return LineTooltipItem(
                      'Freq: ${barSpot.x.toStringAsFixed(1)} MHz\n'
                      'Nivel: ${barSpot.y.toStringAsFixed(2)} dBm',
                      TextStyle(
                        color: Colors.white,
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
    double freqStart = data.minFrequency - 10;
    double freqEnd = data.maxFrequency + 10;
    double step = (freqEnd - freqStart) / 200; // 200 puntos para suavidad
    
    for (double freq = freqStart; freq <= freqEnd; freq += step) {
      double totalPower = data.thermalNoise; // Empezar con el nivel de ruido
      
      // Sumar contribuciones de todas las señales
      for (var signal in data.signals) {
        double signalContribution = _getSignalContribution(freq, signal);
        if (signalContribution > 0) {
          // Conversión de dBm a potencia lineal, suma y vuelta a dBm
          double linearNoise = math.pow(10, totalPower / 10).toDouble();
          double linearSignal = math.pow(10, signalContribution / 10).toDouble();
          totalPower = 10 * math.log(linearNoise + linearSignal) / math.ln10;
        }
      }
      
      spots.add(FlSpot(freq, totalPower));
    }
    
    return spots;
  }

  double _getSignalContribution(double frequency, dynamic signal) {
    // Calcular la contribución de una señal en una frecuencia específica
    double centerFreq = signal.frequency;
    double bandwidth = signal.bandwidth;
    double power = signal.power;
    
    // Distancia desde el centro de la señal
    double distance = (frequency - centerFreq).abs();
    
    if (distance <= bandwidth / 2) {
      // Dentro del ancho de banda principal - usar forma gaussiana
      double normalizedDistance = distance / (bandwidth / 4);
      double attenuation = math.exp(-0.5 * normalizedDistance * normalizedDistance);
      return power + 10 * math.log(attenuation) / math.ln10;
    } else if (distance <= bandwidth) {
      // En los lóbulos laterales - atenuación mayor
      double sidelobeAttenuation = -20; // -20 dB de atenuación
      return power + sidelobeAttenuation;
    }
    
    return 0; // Fuera del rango de la señal
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
                _buildLegendItem(Colors.cyan.shade400, 'Espectro de Potencia'),
                SizedBox(width: 20),
                _buildLegendItem(Colors.red.shade400, 'Nivel de Ruido Térmico'),
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