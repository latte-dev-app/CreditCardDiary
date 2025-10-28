import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/card_provider.dart';

class MonthlyChart extends StatelessWidget {
  const MonthlyChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Consumer<CardProvider>(
        builder: (context, provider, _) {
          final monthlyData = _getMonthlyData(provider);
          
          if (monthlyData.isEmpty) {
            return const Center(
              child: Text(
                'データがありません',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '月別支出',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    barGroups: monthlyData.entries.map((entry) {
                      return BarChartGroupData(
                        x: monthlyData.keys.toList().indexOf(entry.key),
                        barRods: [
                          BarChartRodData(
                            toY: entry.value.toDouble(),
                            color: Colors.blue,
                            width: 20,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    }).toList(),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value >= 0 && value < monthlyData.length) {
                              final month =
                                  monthlyData.keys.elementAt(value.toInt());
                              return Text(
                                month.substring(5),
                                style: const TextStyle(fontSize: 10),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value >= 1000
                                  ? '${(value / 1000).toStringAsFixed(0)}k'
                                  : value.toStringAsFixed(0),
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Map<String, int> _getMonthlyData(CardProvider provider) {
    final Map<String, int> monthlyData = {};
    
    for (final transaction in provider.transactions) {
      final month = transaction.monthString; // YYYY-MM形式
      monthlyData[month] = (monthlyData[month] ?? 0) + transaction.amount;
    }
    
    // 月順にソート
    final sortedKeys = monthlyData.keys.toList()
      ..sort((a, b) => a.compareTo(b));
    
    final Map<String, int> sortedData = {};
    for (final key in sortedKeys) {
      sortedData[key] = monthlyData[key]!;
    }
    
    return sortedData;
  }
}

