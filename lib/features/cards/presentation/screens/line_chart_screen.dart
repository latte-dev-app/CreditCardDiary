import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../application/card_provider.dart';

class LineChartScreen extends StatefulWidget {
  const LineChartScreen({super.key});

  @override
  State<LineChartScreen> createState() => _LineChartScreenState();
}

class _LineChartScreenState extends State<LineChartScreen> {
  int? _selectedYear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('支出推移', style: textTheme.titleLarge),
        elevation: 0,
        surfaceTintColor: colorScheme.surfaceTint,
        actions: [
          Consumer<CardProvider>(
            builder: (context, provider, _) {
              final years = _getAvailableYears(provider);
              if (years.isEmpty) return const SizedBox.shrink();
              final currentYear = _selectedYear ?? years.last;
              return PopupMenuButton<int>(
                onSelected: (y) {
                  setState(() {
                    _selectedYear = y;
                  });
                },
                itemBuilder: (context) => years
                    .map((y) => PopupMenuItem(value: y, child: Text('$y年')))
                    .toList(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    '$currentYear年',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          )
        ],
      ),
      body: Consumer<CardProvider>(
        builder: (context, provider, _) {
          final years = _getAvailableYears(provider);
          if (years.isEmpty) {
            return Center(
              child: Text(
                'データがありません',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }

          final year = _selectedYear ?? years.last;
          final monthlyTotals = _getMonthlyTotalsByYear(provider, year);
          final maxValue = (monthlyTotals.isNotEmpty
                  ? monthlyTotals.reduce((a, b) => a > b ? a : b)
                  : 0)
              .toDouble();
          final formatter = NumberFormat('#,###');

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$year年の支出推移',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              if (value >= 0 && value <= 11) {
                                final m = value.toInt() + 1;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    '$m月',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                            reservedSize: 40,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final label = '${formatter.format(value)}円';
                              return Text(label, style: const TextStyle(fontSize: 10));
                            },
                            reservedSize: 56,
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (List<LineBarSpot> touchedSpots) {
                            return touchedSpots.map((LineBarSpot touchedSpot) {
                              final month = touchedSpot.x.toInt() + 1;
                              final amount = touchedSpot.y.toInt();
                              return LineTooltipItem(
                                '$month月: ${formatter.format(amount)}円',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(12, (index) {
                            return FlSpot(
                              index.toDouble(),
                              monthlyTotals[index].toDouble(),
                            );
                          }),
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.blue.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                      minX: 0,
                      maxX: 11,
                      minY: 0,
                      maxY: (maxValue * 1.1).clamp(0, double.infinity),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '合計: ${formatter.format(monthlyTotals.fold<int>(0, (s, v) => s + v))}円',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '平均: ${formatter.format((monthlyTotals.fold<int>(0, (s, v) => s + v) / 12).round())}円',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<int> _getMonthlyTotalsByYear(CardProvider provider, int year) {
    final List<int> totals = List<int>.filled(12, 0);
    for (final t in provider.transactions) {
      if (t.year == year) {
        final idx = (t.month - 1).clamp(0, 11);
        totals[idx] += t.amount;
      }
    }
    return totals;
  }


  List<int> _getAvailableYears(CardProvider provider) {
    final years = provider.transactions.map((t) => t.year).toSet().toList();
    years.sort();
    return years;
  }
}

