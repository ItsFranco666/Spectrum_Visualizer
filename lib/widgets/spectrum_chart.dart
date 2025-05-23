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
                          child: SpectrumBarChart(data: provider.spectrumData!),
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

class SpectrumBarChart extends StatelessWidget {
  final SpectrumData data;

  SpectrumBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    List<BarChartGroupData> barGroups = [];
    List<Color> colors = [
      Colors.blue.shade400,
      Colors.green.shade400,
      Colors.orange.shade400,
      Colors.purple.shade400,
      Colors.red.shade400,
      Colors.teal.shade400,
      Colors.indigo.shade400,
      Colors.pink.shade400,
    ];

    // Crear barras para cada señal
    for (int i = 0; i < data.signals.length; i++) {
      final signal = data.signals[i];
      final color = colors[i % colors.length];
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: signal.power,
              color: color,
              width: signal.bandwidth * 2, // Ancho proporcional al BW
              borderRadius: BorderRadius.circular(2),
            ),
          ],
        ),
      );
    }

    // Agregar línea de ruido como barra horizontal
    double noiseLevel = data.thermalNoise;
    
    return Column(
      children: [
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceEvenly,
              maxY: data.signals.map((s) => s.power).reduce(math.max) + 10,
              minY: math.min(noiseLevel - 10, data.signals.map((s) => s.power).reduce(math.min) - 10),
              barGroups: barGroups,
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() < data.signals.length) {
                        final signal = data.signals[value.toInt()];
                        return Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'S${signal.id}',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${signal.frequency.toStringAsFixed(1)} MHz',
                                style: TextStyle(fontSize: 8),
                              ),
                              Text(
                                'BW: ${signal.bandwidth.toStringAsFixed(1)}',
                                style: TextStyle(fontSize: 8),
                              ),
                            ],
                          ),
                        );
                      }
                      return Text('');
                    },
                    reservedSize: 60,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toStringAsFixed(0)} dBm',
                        style: TextStyle(fontSize: 10),
                      );
                    },
                    reservedSize: 50,
                  ),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                horizontalInterval: 10,
                getDrawingHorizontalLine: (value) {
                  if ((value - noiseLevel).abs() < 1) {
                    return FlLine(
                      color: Colors.red,
                      strokeWidth: 2,
                      dashArray: [5, 5],
                    );
                  }
                  return FlLine(
                    color: Colors.grey.shade300,
                    strokeWidth: 0.5,
                  );
                },
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.grey.shade400),
              ),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipBorderRadius: BorderRadius.circular(8),
                  tooltipMargin: 8,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    if (groupIndex < data.signals.length) {
                      final signal = data.signals[groupIndex];
                      final snr = data.snrValues[signal.id] ?? 0;
                      return BarTooltipItem(
                        'Señal ${signal.id}\n'
                        'Freq: ${signal.frequency.toStringAsFixed(1)} MHz\n'
                        'BW: ${signal.bandwidth.toStringAsFixed(1)} MHz\n'
                        'Potencia: ${signal.power.toStringAsFixed(2)} dBm\n'
                        'SNR: ${snr.toStringAsFixed(2)} dB',
                        TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      );
                    }
                    return null;
                  },
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.horizontal_rule, color: Colors.red, size: 16),
            Text(
              ' Nivel de Ruido Térmico (${noiseLevel.toStringAsFixed(2)} dBm)',
              style: TextStyle(fontSize: 12, color: Colors.red),
            ),
          ],
        ),
      ],
    );
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
            Text(
              'Análisis del Espectro',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildInfoColumn(
                    'SNR por Señal',
                    data.snrValues.entries.map((entry) {
                      return 'S${entry.key}: ${entry.value.toStringAsFixed(2)} dB';
                    }).toList(),
                  ),
                  SizedBox(width: 20),
                  _buildInfoColumn(
                    'Interferencias',
                    data.interferenceValues.isEmpty 
                      ? ['No hay superposiciones']
                      : data.interferenceValues.entries.map((entry) {
                          return 'S${entry.key}: ${entry.value.toStringAsFixed(2)} dB';
                        }).toList(),
                  ),
                  SizedBox(width: 20),
                  _buildInfoColumn(
                    'Parámetros',
                    [
                      'Temp: ${data.temperature.toStringAsFixed(1)}°K',
                      'BW Sistema: ${data.systemBandwidth.toStringAsFixed(1)} MHz',
                      'Ruido: ${data.thermalNoise.toStringAsFixed(2)} dBm',
                      'Rango: ${data.frequencyRange.toStringAsFixed(1)} MHz',
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: Text(
            item,
            style: TextStyle(fontSize: 12),
          ),
        )),
      ],
    );
  }
}