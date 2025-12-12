import 'package:flutter/material.dart';

void main() {
  runApp(const TaskEstimatorApp());
}

class TaskEstimatorApp extends StatelessWidget {
  const TaskEstimatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Estimador de Tasks',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const EstimatorPage(),
    );
  }
}

class EstimatorPage extends StatefulWidget {
  const EstimatorPage({super.key});

  @override
  State<EstimatorPage> createState() => _EstimatorPageState();
}

class _EstimatorPageState extends State<EstimatorPage> {
  // Variáveis de Estado
  final _optimisticController = TextEditingController();
  final _nominalController = TextEditingController();
  final _pessimisticController = TextEditingController();
  
  double _complexityFactor = 1.0; // 1.0 = Normal, 1.5 = Muito Complexo
  String _result = "";

  void _calculateTime() {
    final double? opt = double.tryParse(_optimisticController.text);
    final double? nom = double.tryParse(_nominalController.text);
    final double? pes = double.tryParse(_pessimisticController.text);

    if (opt != null && nom != null && pes != null) {
      // Fórmula PERT
      double pert = (opt + (4 * nom) + pes) / 6;
      
      // Aplicando fator de complexidade (Incerteza)
      double finalEstimate = pert * _complexityFactor;

      setState(() {
        _result = "${finalEstimate.toStringAsFixed(1)} horas";
      });
    } else {
      setState(() {
        _result = "Preencha todos os campos!";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Calculadora de Estimativa")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600), // Bom para Web
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Insira suas estimativas em horas:", 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                
                // Inputs
                _buildInput(_optimisticController, "Otimista (Tudo dá certo)"),
                const SizedBox(height: 10),
                _buildInput(_nominalController, "Provável (Realista)"),
                const SizedBox(height: 10),
                _buildInput(_pessimisticController, "Pessimista (Tudo dá errado)"),
                
                const SizedBox(height: 20),
                const Text("Fator de Incerteza/Complexidade"),
                Slider(
                  value: _complexityFactor,
                  min: 1.0,
                  max: 2.0,
                  divisions: 10,
                  label: "+${((_complexityFactor - 1) * 100).round()}%",
                  onChanged: (value) {
                    setState(() {
                      _complexityFactor = value;
                    });
                  },
                ),
                Text("Buffer de segurança: +${((_complexityFactor - 1) * 100).round()}%"),

                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: _calculateTime,
                  icon: const Icon(Icons.calculate),
                  label: const Text("Calcular Estimativa Final"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                ),

                const SizedBox(height: 30),
                if (_result.isNotEmpty)
                  Card(
                    color: Colors.indigo.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          const Text("Você deve estimar:", style: TextStyle(fontSize: 16)),
                          Text(_result, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.indigo)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixText: 'h',
      ),
    );
  }
}