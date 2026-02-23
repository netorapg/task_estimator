import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// --- Bloc Events ---
abstract class EstimatorEvent {}

class CalculateEstimation extends EstimatorEvent {
  final String optimistic;
  final String nominal;
  final String pessimistic;
  final double complexity;
  final String hourlyRate;

  CalculateEstimation({
    required this.optimistic,
    required this.nominal,
    required this.pessimistic,
    required this.complexity,
    required this.hourlyRate,
  });
}

// --- Bloc States ---
abstract class EstimatorState {}

class EstimatorInitial extends EstimatorState {}

class EstimatorSuccess extends EstimatorState {
  final double totalHours;
  final double totalCost;
  final double days;
  final double weeks;
  final double months;

  EstimatorSuccess({
    required this.totalHours,
    required this.totalCost,
    required this.days,
    required this.weeks,
    required this.months,
  });
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
      final double? rate = double.tryParse(event.hourlyRate) ?? 0.0;

      if (opt != null && nom != null && pes != null) {
        double pert = (opt + (4 * nom) + pes) / 6;
        double finalHours = pert * event.complexity;

        double days = finalHours / 8;
        double weeks = days / 5;
        double months = days / 22;
        double totalCost = finalHours * rate!;
        
        emit(EstimatorSuccess(
          totalHours: finalHours,
          totalCost: totalCost,
          days: days,
          weeks: weeks,
          months: months,
        ));
      } else {
        emit(EstimatorError("Preencha todos os campos obrigatórios!"));
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
  final _rateController = TextEditingController(); // Novo Controller
  double _complexityFactor = 1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Calculadora de Estimativa Profissional")),
      body: BlocBuilder<EstimatorBloc, EstimatorState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    _buildInput(_optimisticController, "Otimista (h)"),
                    const SizedBox(height: 10),
                    _buildInput(_nominalController, "Provável (h)"),
                    const SizedBox(height: 10),
                    _buildInput(_pessimisticController, "Pessimista (h)"),
                    const SizedBox(height: 10),
                    _buildInput(_rateController, "Valor por Hora (R\$)", isMoney: true),
                    
                    const SizedBox(height: 20),
                    Slider(
                      value: _complexityFactor,
                      min: 1.0, max: 2.0, divisions: 10,
                      onChanged: (value) => setState(() => _complexityFactor = value),
                    ),
                    Text("Complexidade/Buffer: +${((_complexityFactor - 1) * 100).round()}%"),

                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<EstimatorBloc>().add(CalculateEstimation(
                          optimistic: _optimisticController.text,
                          nominal: _nominalController.text,
                          pessimistic: _pessimisticController.text,
                          complexity: _complexityFactor,
                          hourlyRate: _rateController.text,
                        ));
                      },
                      icon: const Icon(Icons.calculate),
                      label: const Text("Gerar Estimativa Completa"),
                    ),

                    const SizedBox(height: 30),
                    if (state is EstimatorSuccess) _buildDetailedResult(state),
                    if (state is EstimatorError) Text(state.message, style: const TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailedResult(EstimatorSuccess state) {
    return Card(
      elevation: 4,
      color: Colors.indigo.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text("Resumo da Estimativa", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Divider(),
            _resultRow("Total de Horas", "${state.totalHours.toStringAsFixed(1)} h"),
            _resultRow("Dias Úteis (8h/dia)", "${state.days.toStringAsFixed(1)} d"),
            _resultRow("Semanas", "${state.weeks.toStringAsFixed(1)} sem"),
            _resultRow("Meses", "${state.months.toStringAsFixed(1)} mes"),
            const Divider(),
            Text("Valor Total Sugerido:", style: TextStyle(fontSize: 16)),
            Text("R\$ ${state.totalCost.toStringAsFixed(2)}", 
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
          ],
        ),
      ),
    );
  }

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))],
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String label, {bool isMoney = false}) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixText: isMoney ? 'R\$ ' : null,
      ),
    );
  }
}