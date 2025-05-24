import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/spectrum_provider.dart';
import '../widgets/signal_input_form.dart';
import '../widgets/spectrum_chart.dart';
import '../widgets/system_parameters_form.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpectrumProvider>().loadConfiguration();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Espectro Radioeléctrico'),
        backgroundColor: const Color.fromARGB(255, 13, 42, 65),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(icon: Icon(Icons.settings_input_antenna), text: 'Señales'),
            Tab(icon: Icon(Icons.settings), text: 'Sistema'),
            Tab(icon: Icon(Icons.show_chart), text: 'Espectro'),
          ],
        ),
        actions: [
          Consumer<SpectrumProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: Icon(Icons.file_download),
                onPressed: provider.spectrumData != null 
                  ? () => provider.exportToCSV()
                  : null,
                tooltip: 'Exportar CSV',
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SignalInputForm(),
          SystemParametersForm(),
          SpectrumChart(),
        ],
      ),
      // MODIFICATION: Interface adjustment - Hide calculate button in spectrum tab (requirement 2)
      floatingActionButton: Consumer<SpectrumProvider>(
        builder: (context, provider, child) {
          // Only show calculate button in signals and system tabs, not in spectrum tab
          if (_tabController.index == 2) {
            return SizedBox.shrink(); // Completely hide button in spectrum tab
          }
          
          return FloatingActionButton.extended(
            onPressed: provider.isLoading ? null : () async {
              await provider.calculateSpectrum();
              _tabController.animateTo(2);
            },
            icon: provider.isLoading 
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(Icons.calculate, color: Colors.white),
            label: Text(provider.isLoading ? 'Calculando...' : 'Calcular', style: TextStyle(color: Colors.white)),
            backgroundColor: provider.isLoading ? Colors.grey : const Color.fromARGB(255, 13, 42, 65),
          );
        },
      ),
    );
  }
}