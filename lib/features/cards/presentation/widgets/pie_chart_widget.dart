import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PieData {
  final String name;
  final double value;
  final Color? color;

  PieData({required this.name, required this.value, this.color});
}

class PieChartWidget extends StatefulWidget {
  final List<PieData> data;
  final double? totalAmount; // Optional override, otherwise sum of data

  const PieChartWidget({super.key, required this.data, this.totalAmount});

  @override
  State<PieChartWidget> createState() => _PieChartWidgetState();
}

class _PieChartWidgetState extends State<PieChartWidget> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const SizedBox.shrink();
    }

    final double totalAmount =
        widget.totalAmount ??
        widget.data.fold<double>(0.0, (sum, item) => sum + item.value);

    // Sort by value descending
    final sortedData = List<PieData>.from(widget.data)
      ..sort((a, b) => b.value.compareTo(a.value));

    // Limit to top 5 and group others if needed
    final topEntries = <PieData>[];
    double otherAmount = 0;

    if (sortedData.length > 5) {
      topEntries.addAll(sortedData.take(5));
      otherAmount = sortedData.skip(5).fold(0, (sum, item) => sum + item.value);
      topEntries.add(
        PieData(
          name: 'その他',
          value: otherAmount,
          color: const Color(0xFFdcdcdc),
        ),
      );
    } else {
      topEntries.addAll(sortedData);
    }

    return SizedBox(
      height: 220,
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
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                topEntries.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  final isTouched = index == touchedIndex;
                  final color = data.color ?? _getColor(index);

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
                          data.name.length > 10
                              ? '${data.name.substring(0, 10)}...'
                              : data.name,
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
    List<PieData> entries,
    double total,
  ) {
    return List.generate(entries.length, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 25.0 : 16.0;
      final radius = isTouched ? 60.0 : 50.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];
      final entry = entries[i];
      final value = entry.value;

      return PieChartSectionData(
        color: entry.color ?? _getColor(i),
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
