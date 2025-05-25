import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/spectrum_provider.dart';
import '../models/spectrum_data.dart';

class SpectrumChart extends StatelessWidget {
  const SpectrumChart({super.key});

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16),
                    // Dynamic resizing: Use Expanded to fill available space
                    Expanded(
                      child: SpectrumLineChart(data: provider.spectrumData!),
                    ),
                  ],
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

class SpectrumLineChart extends StatefulWidget {
  final SpectrumData data;

  const SpectrumLineChart({super.key, required this.data});

  @override
  State<SpectrumLineChart> createState() => _SpectrumLineChartState();
}

class _SpectrumLineChartState extends State<SpectrumLineChart> {
  double _minX;
  double _maxX;
  double _minY;
  double _maxY;
  
  // Variables para control de gestos
  late double _startMinX;
  late double _startMaxX;
  late double _startMinY;
  late double _startMaxY;
  late Offset _startFocalPoint;
  // Variables para el rango original (para reset)
  double _originalMinX = 0;
  double _originalMaxX = 100;
  double _originalMinY = 0;
  double _originalMaxY = 100;

  _SpectrumLineChartState()
      : _minX = 0,
        _maxX = 100,
        _minY = 0,
        _maxY = 100;

  @override
  void initState() {
    super.initState();
    _initializeAxisBounds();
  }

  @override
  void didUpdateWidget(SpectrumLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data) {
      _initializeAxisBounds();
    }
  }

  // Interactive features: Initialize axis bounds for pan/zoom
  void _initializeAxisBounds() {
    double noiseLevel = widget.data.thermalNoise;
    double maxPower = widget.data.signals.map((s) => s.power).reduce(math.max);
    double minPower = math.min(noiseLevel - 15, widget.data.signals.map((s) => s.power).reduce(math.min) - 10);

    _minX = widget.data.minFrequency - 20;
    _maxX = widget.data.maxFrequency + 20;
    _minY = minPower;
    _maxY = maxPower + 10;
    
    // Guardar valores originales
    _originalMinX = _minX;
    _originalMaxX = _maxX;
    _originalMinY = _minY;
    _originalMaxY = _maxY;
  }

  // Función para resetear el zoom
  void _resetZoom() {
    setState(() {
      _minX = _originalMinX;
      _maxX = _originalMaxX;
      _minY = _originalMinY;
      _maxY = _originalMaxY;
    });
  }

  // Generar valores clave para el eje X
  List<double> _getKeyFrequencies() {
    Set<double> keyFreqs = <double>{};
    
    // Agregar frecuencias extremas del rango visible
    keyFreqs.add(_minX);
    keyFreqs.add(_maxX);
    
    // Agregar frecuencias de las señales y sus límites de ancho de banda
    for (var signal in widget.data.signals) {
      double centerFreq = signal.frequency;
      double bandwidth = signal.bandwidth;
      double lowerLimit = centerFreq - bandwidth / 2;
      double upperLimit = centerFreq + bandwidth / 2;
      
      // Siempre agregar la frecuencia central
      keyFreqs.add(centerFreq);
      
      // Agregar límites de ancho de banda si están dentro del rango visible
      if (lowerLimit >= _minX && lowerLimit <= _maxX) {
        keyFreqs.add(lowerLimit);
      }
      if (upperLimit >= _minX && upperLimit <= _maxX) {
        keyFreqs.add(upperLimit);
      }
    }
    
    // Convertir a lista ordenada y filtrar valores dentro del rango visible
    List<double> sortedFreqs = keyFreqs
        .where((freq) => freq >= _minX && freq <= _maxX)
        .toList()
      ..sort();
    
    // Si hay demasiadas frecuencias (más de 10), priorizar las más importantes
    if (sortedFreqs.length > 10) {
      Set<double> priorityFreqs = <double>{};
      
      // Siempre mantener extremos del rango
      priorityFreqs.add(sortedFreqs.first); // Mínimo
      priorityFreqs.add(sortedFreqs.last);  // Máximo
      
      // Siempre mantener frecuencias centrales y límites de ancho de banda
      for (var signal in widget.data.signals) {
        double centerFreq = signal.frequency;
        double bandwidth = signal.bandwidth;
        double lowerLimit = centerFreq - bandwidth / 2;
        double upperLimit = centerFreq + bandwidth / 2;
        
        if (centerFreq >= _minX && centerFreq <= _maxX) {
          priorityFreqs.add(centerFreq); // Frecuencia central
        }
        if (lowerLimit >= _minX && lowerLimit <= _maxX) {
          priorityFreqs.add(lowerLimit); // Límite inferior
        }
        if (upperLimit >= _minX && upperLimit <= _maxX) {
          priorityFreqs.add(upperLimit); // Límite superior
        }
      }
      
      return priorityFreqs.toList()..sort();
    }
    
    return sortedFreqs;
  }

  @override
  Widget build(BuildContext context) {
    // Crear puntos para el gráfico de línea continua
    List<FlSpot> spots = _generateSpectrumCurve();
    
    double noiseLevel = widget.data.thermalNoise;
    List<double> keyFrequencies = _getKeyFrequencies();

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          // Botón de reset zoom
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: _resetZoom,
                  icon: Icon(Icons.zoom_out_map, size: 16),
                  label: Text('Reset Zoom'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size(0, 0),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: GestureDetector(
                onScaleStart: (details) {
                  _startMinX = _minX;
                  _startMaxX = _maxX;
                  _startMinY = _minY;
                  _startMaxY = _maxY;
                  _startFocalPoint = details.focalPoint;
                },
                onScaleUpdate: (details) {
                  final renderBox = context.findRenderObject() as RenderBox?;
                  if (renderBox == null) return;

                  final size = renderBox.size;
                  
                  // Manejar PAN (desplazamiento)
                  if (details.scale == 1.0) {
                    final deltaX = details.focalPoint.dx - _startFocalPoint.dx;
                    final deltaY = details.focalPoint.dy - _startFocalPoint.dy;

                    final dxPercent = deltaX / size.width;
                    final dyPercent = deltaY / size.height;

                    final dataDeltaX = (_startMaxX - _startMinX) * dxPercent;
                    final dataDeltaY = (_startMaxY - _startMinY) * dyPercent;

                    setState(() {
                      _minX = (_startMinX - dataDeltaX)
                          .clamp(_originalMinX - 1000, _originalMaxX + 1000);
                      _maxX = (_startMaxX - dataDeltaX)
                          .clamp(_originalMinX - 1000, _originalMaxX + 1000);
                      _minY = (_startMinY + dataDeltaY)
                          .clamp(_originalMinY - 100, _originalMaxY + 100);
                      _maxY = (_startMaxY + dataDeltaY)
                          .clamp(_originalMinY - 100, _originalMaxY + 100);
                    });
                  }
                  // Manejar ZOOM
                  else {
                    final focalPoint = details.localFocalPoint;
                    
                    // Convertir posición a coordenadas del gráfico
                    final focalX = _startMinX + 
                        (focalPoint.dx / size.width) * (_startMaxX - _startMinX);
                    final focalY = _startMaxY - 
                        (focalPoint.dy / size.height) * (_startMaxY - _startMinY);

                    // Calcular nuevos rangos
                    final newMinX = focalX - 
                        (focalX - _startMinX) / details.scale;
                    final newMaxX = focalX + 
                        (_startMaxX - focalX) / details.scale;
                    final newMinY = focalY - 
                        (focalY - _startMinY) / details.scale;
                    final newMaxY = focalY + 
                        (_startMaxY - focalY) / details.scale;

                    setState(() {
                      _minX = newMinX.clamp(
                          _originalMinX - 1000, _originalMaxX + 1000);
                      _maxX = newMaxX.clamp(
                          _originalMinX - 1000, _originalMaxX + 1000);
                      _minY = newMinY.clamp(
                          _originalMinY - 100, _originalMaxY + 100);
                      _maxY = newMaxY.clamp(
                          _originalMinY - 100, _originalMaxY + 100);
                    });
                  }
                },
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawHorizontalLine: true,
                      drawVerticalLine: true,
                      horizontalInterval: 10,
                      verticalInterval: (widget.data.maxFrequency - widget.data.minFrequency) / 8,
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
                        // Axis labels: Add x-axis label
                        axisNameWidget: Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Frecuencia (MHz)',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        axisNameSize: 30,
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 35,
                          getTitlesWidget: (value, meta) {
                            // Mostrar solo las frecuencias clave
                            bool isKeyFrequency = keyFrequencies.any((freq) => (freq - value).abs() < 0.5);
                            
                            if (isKeyFrequency) {
                              return Padding(
                                padding: EdgeInsets.only(top: 8.0),
                                child: Text(
                                  value.toStringAsFixed(1),
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }
                            return Container();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        // Axis labels: Add y-axis label
                        axisNameWidget: RotatedBox(
                          quarterTurns: 12,
                          child: Text(
                            'Potencia (dBm)',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        axisNameSize: 50,
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 45,
                          interval: 10,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toStringAsFixed(0),
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
                    // Interactive features: Use dynamic bounds for pan/zoom
                    minX: _minX,
                    maxX: _maxX,
                    minY: _minY,
                    maxY: _maxY,
                    lineBarsData: [
                      // Espectro principal
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
                              Colors.blue.shade400.withAlpha((0.7 * 255).round()),
                              Colors.blue.shade300.withAlpha((0.5 * 255).round()),
                              Colors.blue.shade200.withAlpha((0.3 * 255).round()),
                              Colors.blue.shade100.withAlpha((0.1 * 255).round()),
                            ],
                            stops: [0.0, 0.4, 0.7, 1.0],
                          ),
                        ),
                      ),
                      // Línea de ruido térmico
                      LineChartBarData(
                        spots: [
                          FlSpot(_minX, noiseLevel),
                          FlSpot(_maxX, noiseLevel),
                        ],
                        isCurved: false,
                        color: Colors.red.shade600,
                        barWidth: 2,
                        dashArray: [8, 4],
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                        tooltipPadding: EdgeInsets.all(8),
                        tooltipBorderRadius: BorderRadius.circular(8),
                        maxContentWidth: 200,
                        getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                          if (touchedBarSpots.isEmpty) return [];
                          
                          return touchedBarSpots.map((barSpot) {
                            // Solo procesar el primer punto tocado para evitar duplicaciones
                            if (touchedBarSpots.indexOf(barSpot) > 0) {
                              return null;
                            }
                            
                            // Encontrar la señal más cercana
                            var closestSignal = widget.data.signals.first;
                            double minDistance = double.infinity;
                            
                            for (var signal in widget.data.signals) {
                              double distance = (signal.frequency - barSpot.x).abs();
                              if (distance < minDistance) {
                                minDistance = distance;
                                closestSignal = signal;
                              }
                            }
                            
                            if (minDistance < closestSignal.bandwidth / 2) {
                              final snr = widget.data.snrValues[closestSignal.id] ?? 0;
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
                          }).where((item) => item != null).cast<LineTooltipItem>().toList();
                        },
                      ),
                    ),
                    // Interactive features: Enable pan and zoom gestures
                    clipData: FlClipData.all(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _generateSpectrumCurve() {
    List<FlSpot> spots = [];
    double freqStart = widget.data.minFrequency - 20;
    double freqEnd = widget.data.maxFrequency + 20;
    double step = (freqEnd - freqStart) / 300; // Más puntos para mejor resolución
    
    for (double freq = freqStart; freq <= freqEnd; freq += step) {
      double maxPower = widget.data.thermalNoise; // Empezar con el nivel de ruido
      
      // Encontrar la señal más fuerte en esta frecuencia
      for (var signal in widget.data.signals) {
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
    return widget.data.thermalNoise;
  }
}

class SpectrumInfo extends StatelessWidget {
  final SpectrumData data;

  const SpectrumInfo({super.key, required this.data});

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