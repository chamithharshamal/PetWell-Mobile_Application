import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'analytics/models/weight_record.dart';

class WeightGraph extends StatelessWidget {
  final List<WeightRecord> weightRecords;

  const WeightGraph({super.key, required this.weightRecords});

  @override
  Widget build(BuildContext context) {
    if (weightRecords.isEmpty) {
      return const Center(
        child: Text(
          'No weight data available',
          style: TextStyle(fontSize: 16, color: Color(0xFF333333)),
        ),
      );
    }

    // Sort records by date
    weightRecords.sort((a, b) => a.date.compareTo(b.date));

    // Group weights by month
    final Map<String, double> monthlyWeights = {};
    for (var record in weightRecords) {
      final monthYear = '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}';
      monthlyWeights[monthYear] = record.weight; // Keep the latest weight for each month
    }

    // Convert to FlSpot for the graph
    final List<FlSpot> spots = [];
    final List<String> months = monthlyWeights.keys.toList();
    for (int i = 0; i < months.length; i++) {
      spots.add(FlSpot(i.toDouble(), monthlyWeights[months[i]]!));
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 2,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            ),
            getDrawingVerticalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()} kg',
                    style: const TextStyle(color: Color(0xFF333333), fontSize: 12),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < months.length) {
                    final month = months[index].split('-')[1];
                    final year = months[index].split('-')[0].substring(2);
                    return Text(
                      '$month/$year',
                      style: const TextStyle(color: Color(0xFF333333), fontSize: 12),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          minY: 0,
          maxY: (monthlyWeights.values.reduce((a, b) => a > b ? a : b) + 2).toDouble(),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFFe74d3d),
              barWidth: 3,
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFFe74d3d).withOpacity(0.1),
              ),
              dotData: const FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }
}