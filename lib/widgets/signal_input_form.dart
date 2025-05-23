import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/spectrum_provider.dart';

class SignalInputForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SpectrumProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Configuración de Señales',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: provider.numberOfSignals.toString(),
                              decoration: InputDecoration(
                                labelText: 'Número de señales',
                                border: OutlineInputBorder(),
                                helperText: 'Mínimo 3 señales',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              onChanged: (value) {
                                int? count = int.tryParse(value);
                                if (count != null && count >= 3) {
                                  provider.setNumberOfSignals(count);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: provider.signals.length,
                  itemBuilder: (context, index) {
                    return SignalCard(
                      index: index,
                      signal: provider.signals[index],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SignalCard extends StatefulWidget {
  final int index;
  final dynamic signal;

  SignalCard({required this.index, required this.signal});

  @override
  _SignalCardState createState() => _SignalCardState();
}

class _SignalCardState extends State<SignalCard> {
  late TextEditingController _powerController;
  late TextEditingController _bandwidthController;
  late TextEditingController _frequencyController;
  String _selectedPowerUnit = 'dBm';

  @override
  void initState() {
    super.initState();
    _powerController = TextEditingController(
      text: widget.signal.originalPower.toString()
    );
    _bandwidthController = TextEditingController(
      text: widget.signal.bandwidth.toString()
    );
    _frequencyController = TextEditingController(
      text: widget.signal.frequency.toString()
    );
    _selectedPowerUnit = widget.signal.powerUnit;
  }

  @override
  void dispose() {
    _powerController.dispose();
    _bandwidthController.dispose();
    _frequencyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Señal ${widget.signal.id}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _powerController,
                    decoration: InputDecoration(
                      labelText: 'Potencia',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) => _updateSignal(),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: _selectedPowerUnit,
                    decoration: InputDecoration(
                      labelText: 'Unidad',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: ['W', 'mW', 'dBm', 'dBW'].map((unit) {
                      return DropdownMenuItem(value: unit, child: Text(unit));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPowerUnit = value!;
                      });
                      _updateSignal();
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _bandwidthController,
                    decoration: InputDecoration(
                      labelText: 'Ancho de banda (MHz)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _updateSignal(),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _frequencyController,
                    decoration: InputDecoration(
                      labelText: 'Frecuencia central (MHz)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _updateSignal(),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Potencia en dBm: ${widget.signal.power.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateSignal() {
    double? power = double.tryParse(_powerController.text);
    double? bandwidth = double.tryParse(_bandwidthController.text);
    double? frequency = double.tryParse(_frequencyController.text);

    if (power != null && bandwidth != null && frequency != null) {
      context.read<SpectrumProvider>().updateSignal(
        widget.index,
        power: power,
        bandwidth: bandwidth,
        frequency: frequency,
        powerUnit: _selectedPowerUnit,
      );
    }
  }
}