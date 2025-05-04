import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class PetWeightChart extends StatelessWidget {
  final List<Map<String, dynamic>> weightData; // { weight: double, timestamp: DateTime }

  const PetWeightChart({super.key, required this.weightData});

  @override
  Widget build(BuildContext context) {
    if (weightData.isEmpty) return const Text("No weight data available.");

    final spots = weightData.asMap().entries.map((entry) {
      int i = entry.key;
      final weight = (entry.value['weight'] as double).roundToDouble();
      return FlSpot(i.toDouble(), weight);
    }).toList();

    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          borderData: FlBorderData(
            show: true,
            border: const Border(
              left: BorderSide(),
              bottom: BorderSide(),
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
                axisNameWidget: const Text("Weight (kg)", style: TextStyle(fontWeight: FontWeight.bold)),
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    // Check if value matches one of the entered weights
                    final enteredWeights = weightData.map((e) => e['weight'] as double).toSet();
                    if (enteredWeights.contains(value)) {
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        ),

                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
            ),

            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              axisNameWidget: const Text("Month", style: TextStyle(fontWeight: FontWeight.bold)),
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= weightData.length) return const SizedBox.shrink();

                  final date = weightData[index]['timestamp'] as DateTime;
                  final formattedMonth = DateFormat.MMM().format(date); // E.g., Jan, Feb

                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      formattedMonth,
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
                reservedSize: 30,
                interval: 1,
              ),
            ),

          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFFE74D3D),
              barWidth: 4,
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFFFF9F91).withOpacity(0.4),
              ),
              dotData: FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }
}
