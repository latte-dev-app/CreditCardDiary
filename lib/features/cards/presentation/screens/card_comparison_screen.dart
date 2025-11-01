import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../application/card_provider.dart';

class CardComparisonScreen extends StatefulWidget {
  const CardComparisonScreen({super.key});

  @override
  State<CardComparisonScreen> createState() => _CardComparisonScreenState();
}

class _CardComparisonScreenState extends State<CardComparisonScreen> {
  DateTime _selectedMonth = DateTime.now();
  bool _compareWithCurrentMonth = true;

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final currentMonth = DateTime.now().month;
    final selectedYear = _selectedMonth.year;
    final selectedMonth = _selectedMonth.month;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('カード比較', style: textTheme.titleLarge),
        elevation: 0,
        surfaceTintColor: colorScheme.surfaceTint,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 24.0),
            constraints: const BoxConstraints(
              minWidth: 48.0,
              minHeight: 48.0,
            ),
            onPressed: _previousMonth,
            tooltip: '前の月',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '$selectedYear年$selectedMonth月',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 24.0),
            constraints: const BoxConstraints(
              minWidth: 48.0,
              minHeight: 48.0,
            ),
            onPressed: _nextMonth,
            tooltip: '次の月',
          ),
        ],
      ),
      body: Consumer<CardProvider>(
        builder: (context, provider, _) {
          if (provider.cards.isEmpty) {
            return Center(
              child: Text(
                'カードが登録されていません',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }

          // 選択月のカード別合計
          final selectedMonthTotals = provider.getCardTotalsByMonth(
            selectedYear,
            selectedMonth,
          );

          // 当月のカード別合計（比較用）
          Map<String, int> currentMonthTotals = {};
          if (_compareWithCurrentMonth && 
              !(currentYear == selectedYear && currentMonth == selectedMonth)) {
            currentMonthTotals = provider.getCardTotalsByMonth(
              currentYear,
              currentMonth,
            );
          }

          // 全カードを取得してソート
          final allCards = provider.cards.toList();
          
          // グラフ用データを準備
          final barGroups = <BarChartGroupData>[];
          final cardNames = <String>[];
          
          for (int i = 0; i < allCards.length; i++) {
            final card = allCards[i];
            cardNames.add(card.name);
            
            final selectedAmount = selectedMonthTotals[card.id]?.toDouble() ?? 0.0;
            final currentAmount = _compareWithCurrentMonth && 
                !(currentYear == selectedYear && currentMonth == selectedMonth)
                ? (currentMonthTotals[card.id]?.toDouble() ?? 0.0)
                : 0.0;

            barGroups.add(
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: selectedAmount,
                    color: _parseColor(card.color),
                    width: _compareWithCurrentMonth &&
                        !(currentYear == selectedYear && currentMonth == selectedMonth)
                        ? 20
                        : 30,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                  if (_compareWithCurrentMonth &&
                      !(currentYear == selectedYear && currentMonth == selectedMonth))
                    BarChartRodData(
                      toY: currentAmount,
                      color: _parseColor(card.color).withValues(alpha: 0.5),
                      width: 20,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                ],
              ),
            );
          }

          final maxValue = barGroups.isEmpty
              ? 1.0
              : barGroups
                  .map((g) => g.barRods.map((r) => r.toY).reduce((a, b) => a > b ? a : b))
                  .reduce((a, b) => a > b ? a : b);

          final formatter = NumberFormat('#,###');

          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Column(
            children: [
              // 比較モード切替
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      '当月と比較',
                      style: textTheme.bodyLarge,
                    ),
                    Switch(
                      value: _compareWithCurrentMonth,
                      onChanged: (value) {
                        setState(() {
                          _compareWithCurrentMonth = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              // 凡例
              if (_compareWithCurrentMonth &&
                  !(currentYear == selectedYear && currentMonth == selectedMonth))
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegend(
                        '$selectedYear年$selectedMonth月',
                        Colors.blue,
                        textTheme.bodySmall,
                      ),
                      const SizedBox(width: 16),
                      _buildLegend(
                        '$currentYear年$currentMonth月（当月）',
                        Colors.blue.withValues(alpha: 0.5),
                        textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              // グラフ
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Card(
                        elevation: 2,
                        color: colorScheme.surface.withValues(alpha: 0.8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side: BorderSide(
                            color: colorScheme.outline.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: barGroups.isEmpty
                              ? Center(
                                  child: Text(
                                    'データがありません',
                                    style: textTheme.bodyLarge?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                )
                              : BarChart(
                                  BarChartData(
                                    alignment: BarChartAlignment.spaceAround,
                                    maxY: (maxValue * 1.1).clamp(0, double.infinity),
                                    barTouchData: BarTouchData(
                                      touchTooltipData: BarTouchTooltipData(
                                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                          final cardName = cardNames[group.x.toInt()];
                                          final amount = rod.toY.toInt();
                                          final label = rodIndex == 0
                                              ? '$selectedYear年$selectedMonth月'
                                              : '$currentYear年$currentMonth月';
                                          return BarTooltipItem(
                                            '$cardName\n$label: ${formatter.format(amount)}円',
                                            const TextStyle(color: Colors.white),
                                          );
                                        },
                                      ),
                                    ),
                                    titlesData: FlTitlesData(
                                      show: true,
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            if (value.toInt() >= 0 &&
                                                value.toInt() < cardNames.length) {
                                              return Padding(
                                                padding: const EdgeInsets.only(top: 8),
                                                child: Text(
                                                  cardNames[value.toInt()],
                                                  style: const TextStyle(fontSize: 10),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              );
                                            }
                                            return const SizedBox.shrink();
                                          },
                                          reservedSize: 50,
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            return Text(
                                              '${formatter.format(value)}円',
                                              style: const TextStyle(fontSize: 10),
                                            );
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
                                    barGroups: barGroups,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
        },
      ),
    );
  }

  Widget _buildLegend(String label, Color color, TextStyle? textStyle) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: textStyle,
        ),
      ],
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }
}

