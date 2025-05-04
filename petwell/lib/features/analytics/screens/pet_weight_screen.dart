import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../charts/pet_weight_chart.dart';
import '../widgets/weight_input.dart';

class PetWeightScreen extends StatefulWidget {
  const PetWeightScreen({super.key});

  @override
  State<PetWeightScreen> createState() => _PetWeightScreenState();
}

class _PetWeightScreenState extends State<PetWeightScreen> {
  final TextEditingController _controller = TextEditingController();
  final CollectionReference _weights = FirebaseFirestore.instance.collection('pet_weights');

  List<Map<String, dynamic>> _weightsList = []; // Now storing weight and timestamp
  bool _showChart = false;

  void _submitWeight() async {
    final input = _controller.text.trim();
    if (input.isEmpty) return;
    final weight = double.tryParse(input);
    if (weight == null) return;

    await _weights.add({
      'weight': weight,
      'timestamp': Timestamp.now(),
    });

    _controller.clear();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Weight submitted')));
  }

  void _fetchWeights() async {
    final snapshot = await _weights.orderBy('timestamp').get();

    setState(() {
      _weightsList = snapshot.docs.map((doc) {
        return {
          'weight': (doc['weight'] as num).toDouble(),
          'timestamp': (doc['timestamp'] as Timestamp).toDate(),
        };
      }).toList();
      _showChart = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pet Weight Tracker')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            WeightInput(controller: _controller, onSubmit: _submitWeight),
            const SizedBox(height: 17),
            ElevatedButton(
              onPressed: _fetchWeights,
              child: const Text('See My Progress 📈'),
            ),
            const SizedBox(height: 55),
            if (_showChart) PetWeightChart(weightData: _weightsList),
          ],
        ),
      ),
    );
  }
}
