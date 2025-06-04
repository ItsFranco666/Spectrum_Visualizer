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
                    //Cambio de tamaño dinámico: utilice Expandido para llenar el espacio disponible
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
  // Añade el zoom y control de rango dinámico
  // Variables para los límites del eje X e Y
  double _minX;
  double _maxX;
  double _minY;
  double _maxY;

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

  // Generar colores únicos para cada señal
  Color _getSignalColor(int signalIndex) {
    List<Color> colors = [
      Colors.blue.shade600,
      Colors.red.shade600,
      Colors.green.shade600,
      Colors.purple.shade600,
      Colors.orange.shade600,
      Colors.teal.shade600,
      Colors.pink.shade600,
      Colors.indigo.shade600,
      Colors.amber.shade600,
      Colors.cyan.shade600,
    ];
    return colors[signalIndex % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    double noiseLevel = widget.data.thermalNoise;
    List<double> keyFrequencies = _getKeyFrequencies();

    // Crear líneas para cada señal individual
    List<LineChartBarData> signalLines = [];
    
    // Agregar líneas para cada señal individual
    for (int i = 0; i < widget.data.signals.length; i++) {
      var signal = widget.data.signals[i];
      List<FlSpot> signalSpots = _generateSignalCurve(signal);
      Color signalColor = _getSignalColor(i);
      
      signalLines.add(
        LineChartBarData(
          spots: signalSpots,
          isCurved: true,
          curveSmoothness: 0.3,
          color: signalColor,
          barWidth: 2.0,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                signalColor.withAlpha((0.4 * 255).round()),
                signalColor.withAlpha((0.2 * 255).round()),
                signalColor.withAlpha((0.1 * 255).round()),
                signalColor.withAlpha((0.05 * 255).round()),
              ],
              stops: [0.0, 0.4, 0.7, 1.0],
            ),
          ),
        ),
      );
    }

    // Crear puntos para el gráfico de espectro envolvente (máximo en cada frecuencia)
    List<FlSpot> envelopeSpots = _generateSpectrumEnvelope();
    
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
                // Añadir label de eje X
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
                // Añadir label de eje Y
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
            // Funciones interactivas: utilice límites dinámicos para desplazarse y hacer zoom
            minX: _minX,
            maxX: _maxX,
            minY: _minY,
            maxY: _maxY,
            lineBarsData: [
              // Líneas individuales de cada señal
              ...signalLines,
              
              // Espectro envolvente (línea punteada que muestra el máximo)
              LineChartBarData(
                spots: envelopeSpots,
                isCurved: true,
                curveSmoothness: 0.2,
                color: Colors.black.withAlpha((0.6 * 255).round()),
                barWidth: 1.5,
                isStrokeCapRound: true,
                dashArray: [3, 3],
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
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
                maxContentWidth: 250,
                getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                  if (touchedBarSpots.isEmpty) return [];
                  
                  // Obtener información de todas las señales en el punto tocado
                  double frequency = touchedBarSpots.first.x;
                  List<String> signalInfos = [];
                  
                  for (int i = 0; i < widget.data.signals.length; i++) {
                    var signal = widget.data.signals[i];
                    double signalPower = _getSignalPower(frequency, signal);
                    
                    if (signalPower > widget.data.thermalNoise) {
                      final snr = widget.data.snrValues[signal.id] ?? 0;
                      signalInfos.add(
                        'S${signal.id}: ${signal.frequency.toStringAsFixed(1)}MHz '
                        '(${signalPower.toStringAsFixed(2)}dBm, SNR:${snr.toStringAsFixed(1)}dB)'
                      );
                    }
                  }
                  
                  String tooltipText = 'Freq: ${frequency.toStringAsFixed(1)} MHz\n';
                  if (signalInfos.isNotEmpty) {
                    tooltipText += signalInfos.join('\n');
                  } else {
                    tooltipText += 'Solo ruido térmico';
                  }
                  
                  return [
                    LineTooltipItem(
                      tooltipText,
                      TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ];
                },
              ),
            ),
            // Funciones interactivas: Habilite gestos de panorámica y zoom
            clipData: FlClipData.all(),
          ),
        ),
      ),
    );
  }

  // Generar curva para una señal individual
  List<FlSpot> _generateSignalCurve(dynamic signal) {
    List<FlSpot> spots = [];
    double freqStart = widget.data.minFrequency - 20;
    double freqEnd = widget.data.maxFrequency + 20;
    double step = (freqEnd - freqStart) / 300;
    
    for (double freq = freqStart; freq <= freqEnd; freq += step) {
      double signalPower = _getSignalPower(freq, signal);
      spots.add(FlSpot(freq, signalPower));
    }
    
    return spots;
  }

  // Generar espectro envolvente (máximo en cada frecuencia)
  List<FlSpot> _generateSpectrumEnvelope() {
    List<FlSpot> spots = [];
    double freqStart = widget.data.minFrequency - 20;
    double freqEnd = widget.data.maxFrequency + 20;
    double step = (freqEnd - freqStart) / 300;
    
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

  // Generar colores únicos para cada señal (mismo método que en el chart)
  Color _getSignalColor(int signalIndex) {
    List<Color> colors = [
      Colors.blue.shade600,
      Colors.red.shade600,
      Colors.green.shade600,
      Colors.purple.shade600,
      Colors.orange.shade600,
      Colors.teal.shade600,
      Colors.pink.shade600,
      Colors.indigo.shade600,
      Colors.amber.shade600,
      Colors.cyan.shade600,
    ];
    return colors[signalIndex % colors.length];
  }

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
            // Leyenda mejorada con colores de cada señal
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                // Señales individuales
                ...data.signals.asMap().entries.map((entry) {
                  int index = entry.key;
                  var signal = entry.value;
                  Color signalColor = _getSignalColor(index);
                  return _buildLegendItem(signalColor, 'Señal ${signal.id}');
                }).toList(),
                // Espectro envolvente
                _buildLegendItem(Colors.black.withAlpha((0.6 * 255).round()), 'Envolvente (máximo)', isDashed: true),
                // Ruido térmico
                _buildLegendItem(Colors.red.shade600, 'Ruido Térmico', isDashed: true),
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

  Widget _buildLegendItem(Color color, String label, {bool isDashed = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: isDashed ? Colors.transparent : color,
            borderRadius: BorderRadius.circular(2),
            border: isDashed ? Border.all(color: color, width: 1) : null,
          ),
          child: isDashed 
            ? CustomPaint(
                painter: DashedLinePainter(color: color),
              )
            : null,
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

// Pintor personalizado para líneas discontinuas en la leyenda
class DashedLinePainter extends CustomPainter {
  final Color color;
  
  DashedLinePainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    
    double dashWidth = 3;
    double dashSpace = 2;
    double startX = 0;
    
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(math.min(startX + dashWidth, size.width), size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}