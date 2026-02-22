import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// --- Bloc Events ---
abstract class EstimatorEvent {}

class CalculateEstimation extends EstimatorEvent {
  final String optimistic;
  final String nominal;
  final String pessimistic;
  final double complexity;

  CalculateEstimation({
    required this.optimistic,
    required this.nominal,
    required this.pessimistic,
    required this.complexity,
  });
}

// --- Bloc States ---
abstract class EstimatorState {}

class EstimatorInitial extends EstimatorState {}

class EstimatorSuccess extends EstimatorState {
  final String result;
  EstimatorSuccess(this.result);
}

class EstimatorError extends EstimatorState {
  final String message;
  EstimatorError(this.message);
}

// --- Bloc Logic ---
class EstimatorBloc extends Bloc<EstimatorEvent, EstimatorState> {
  EstimatorBloc() : super(EstimatorInitial()) {
    on<CalculateEstimation>((event, emit) {
      final double? opt = double.tryParse(event.optimistic);
      final double? nom = double.tryParse(event.nominal);
      final double? pes = double.tryParse(event.pessimistic);

      if (opt != null && nom != null && pes != null) {
        double pert = (opt + (4 * nom) + pes) / 6;
        double finalEstimate = pert * event.complexity;
        
        emit(EstimatorSuccess("${finalEstimate.toStringAsFixed(1)} horas"));
      } else {
        emit(EstimatorError("Preencha todos os campos!"));
      }
    });
  }
}

// --- Main App ---
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
      home: BlocProvider(
        create: (context) => EstimatorBloc(),
        child: const EstimatorPage(),
      ),
    );
  }
}

class EstimatorPage extends StatefulWidget {
  const EstimatorPage({super.key});

  @override
  State<EstimatorPage> createState() => _EstimatorPageState();
}

class _EstimatorPageState extends State<EstimatorPage> {
  final _optimisticController = TextEditingController();
  final _nominalController = TextEditingController();
  final _pessimisticController = TextEditingController();
  double _complexityFactor = 1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Calculadora de Estimativa")),
      body: BlocBuilder<EstimatorBloc, EstimatorState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Insira suas estimativas em horas:", 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    
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
                      onChanged: (value) => setState(() => _complexityFactor = value),
                    ),
                    Text("Buffer de segurança: +${((_complexityFactor - 1) * 100).round()}%"),

                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<EstimatorBloc>().add(CalculateEstimation(
                          optimistic: _optimisticController.text,
                          nominal: _nominalController.text,
                          pessimistic: _pessimisticController.text,
                          complexity: _complexityFactor,
                        ));
                      },
                      icon: const Icon(Icons.calculate),
                      label: const Text("Calcular Estimativa Final"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      ),
                    ),

                    const SizedBox(height: 30),
                    
                    if (state is EstimatorSuccess)
                      _buildResultCard(state.result)
                    else if (state is EstimatorError)
                      Text(state.message, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultCard(String result) {
    return Card(
      color: Colors.indigo.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text("Você deve estimar:", style: TextStyle(fontSize: 16)),
            Text(result, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.indigo)),
          ],
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