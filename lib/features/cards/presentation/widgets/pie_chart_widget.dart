import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../domain/card_model.dart';

class PieChartWidget extends StatefulWidget {
  final List<Transaction> transactions;

  const PieChartWidget({super.key, required this.transactions});

  @override
  State<PieChartWidget> createState() => _PieChartWidgetState();
}

class _PieChartWidgetState extends State<PieChartWidget> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.transactions.isEmpty) {
      return const SizedBox.shrink();
    }

    final groupedTransactions = <String, int>{};
    for (var t in widget.transactions) {
      // Use title as category for now, since we don't have a dedicated category field yet
      // Ideally we should add a category field to Transaction model later
      final key = t.title;
      groupedTransactions[key] = (groupedTransactions[key] ?? 0) + t.amount;
    }

    final totalAmount = widget.transactions.fold(0, (sum, t) => sum + t.amount);
    final sortedEntries =
        groupedTransactions.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    // Limit to top 5 and group others
    final topEntries = sortedEntries.take(5).toList();
    if (sortedEntries.length > 5) {
      final otherAmount = sortedEntries
          .skip(5)
          .fold(0, (sum, e) => sum + e.value);
      topEntries.add(MapEntry('その他', otherAmount));
    }

    return AspectRatio(
      aspectRatio: 1.3,
      child: Row(
        children: [
          const SizedBox(height: 18),
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          touchedIndex = -1;
                          return;
                        }
                        touchedIndex =
                            pieTouchResponse
                                .touchedSection!
                                .touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 0,
                  centerSpaceRadius: 40,
                  sections: showingSections(topEntries, totalAmount),
                ),
              ),
            ),
          ),
          const SizedBox(width: 28),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                topEntries.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  final isTouched = index == touchedIndex;
                  final color = _getColor(index);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          data.key.length > 10
                              ? '${data.key.substring(0, 10)}...'
                              : data.key,
                          style: TextStyle(
                            fontSize: isTouched ? 16 : 14,
                            fontWeight:
                                isTouched ? FontWeight.bold : FontWeight.normal,
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(data.value / totalAmount * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(width: 28),
        ],
      ),
    );
  }

  List<PieChartSectionData> showingSections(
    List<MapEntry<String, int>> entries,
    int total,
  ) {
    return List.generate(entries.length, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 25.0 : 16.0;
      final radius = isTouched ? 60.0 : 50.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];
      final entry = entries[i];
      final value = entry.value.toDouble();

      return PieChartSectionData(
        color: _getColor(i),
        value: value,
        title: '${(value / total * 100).toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: shadows,
        ),
      );
    });
  }

  Color _getColor(int index) {
    const colors = [
      Color(0xFF0293ee),
      Color(0xFFf8b250),
      Color(0xFF845bef),
      Color(0xFF13d38e),
      Color(0xFFff5959),
      Color(0xFFdcdcdc),
    ];
    return colors[index % colors.length];
  }
}
