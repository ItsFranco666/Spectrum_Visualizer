import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/spectrum_provider.dart';

class SystemParametersForm extends StatefulWidget {
  const SystemParametersForm({super.key});

  @override
  _SystemParametersFormState createState() => _SystemParametersFormState();
}

class _SystemParametersFormState extends State<SystemParametersForm> {
  late TextEditingController _temperatureController;
  late TextEditingController _systemBandwidthController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<SpectrumProvider>();
    _temperatureController = TextEditingController(
      text: provider.temperature.toString()
    );
    _systemBandwidthController = TextEditingController(
      text: provider.systemBandwidth.toString()
    );
  }

  @override
  void dispose() {
    _temperatureController.dispose();
    _systemBandwidthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Parámetros del Sistema',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 24),
                  TextFormField(
                    controller: _temperatureController,
                    decoration: InputDecoration(
                      labelText: 'Temperatura (°K)',
                      border: OutlineInputBorder(),
                      helperText: 'Temperatura ambiente típica: 290°K',
                      prefixIcon: Icon(Icons.thermostat),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      double? temp = double.tryParse(value);
                      if (temp != null && temp > 0) {
                        context.read<SpectrumProvider>().setTemperature(temp);
                      }
                    },
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: _systemBandwidthController,
                    decoration: InputDecoration(
                      labelText: 'Ancho de banda del sistema (MHz)',
                      border: OutlineInputBorder(),
                      helperText: 'Ancho de banda total disponible',
                      prefixIcon: Icon(Icons.settings_input_antenna),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      double? bw = double.tryParse(value);
                      if (bw != null && bw > 0) {
                        context.read<SpectrumProvider>().setSystemBandwidth(bw);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          Consumer<SpectrumProvider>(
            builder: (context, provider, child) {
              if (provider.spectrumData != null) {
                return Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Información Calculada',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        ListTile(
                          leading: Icon(Icons.noise_aware, color: Colors.red),
                          title: Text('Ruido Térmico'),
                          subtitle: Text('${provider.spectrumData!.thermalNoise.toStringAsFixed(2)} dBm'),
                        ),
                        ListTile(
                          leading: Icon(Icons.straighten, color: Colors.blue),
                          title: Text('Rango de Frecuencias'),
                          subtitle: Text('${provider.spectrumData!.minFrequency.toStringAsFixed(1)} - ${provider.spectrumData!.maxFrequency.toStringAsFixed(1)} MHz'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Container();
            },
          ),
        ],
      ),
    );
  }
}