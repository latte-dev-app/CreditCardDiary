import 'dart:ui';
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
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          '支出推移',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: colorScheme.surface.withValues(alpha: 0.5)),
          ),
        ),
        actions: [
          Consumer<CardProvider>(
            builder: (context, provider, _) {
              final years = _getAvailableYears(provider);
              if (years.isEmpty) return const SizedBox.shrink();
              final currentYear = _selectedYear ?? years.last;
              return Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.1),
                  ),
                ),
                child: PopupMenuButton<int>(
                  onSelected: (y) {
                    setState(() {
                      _selectedYear = y;
                    });
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  itemBuilder:
                      (context) =>
                          years
                              .map(
                                (y) =>
                                    PopupMenuItem(value: y, child: Text('$y年')),
                              )
                              .toList(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        Text(
                          '$currentYear年',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 20,
                          color: colorScheme.onSurface,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colorScheme.surface, colorScheme.surfaceContainerLowest],
          ),
        ),
        child: Consumer<CardProvider>(
          builder: (context, provider, _) {
            final years = _getAvailableYears(provider);
            if (years.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart, size: 64, color: colorScheme.outline),
                    const SizedBox(height: 16),
                    Text(
                      'データがありません',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }

            final year = _selectedYear ?? years.last;
            final monthlyTotals = _getMonthlyTotalsByYear(provider, year);
            final maxValue =
                (monthlyTotals.isNotEmpty
                        ? monthlyTotals.reduce((a, b) => a > b ? a : b)
                        : 0)
                    .toDouble();
            final formatter = NumberFormat('#,###');
            final totalAmount = monthlyTotals.fold<int>(0, (s, v) => s + v);
            final averageAmount = (totalAmount / 12).round();

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$year年の支出推移',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 320,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: maxValue > 0 ? maxValue / 5 : 1,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: colorScheme.outlineVariant.withValues(
                                  alpha: 0.5,
                                ),
                                strokeWidth: 1,
                                dashArray: [5, 5],
                              );
                            },
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
                                    // 奇数月だけ表示してスッキリさせる、あるいは全部表示
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Text(
                                        '$m月',
                                        style: textTheme.labelSmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                                reservedSize: 32,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles:
                                    false, // Y軸の数値は非表示にしてスッキリさせる（ツールチップで確認）
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              tooltipBgColor: colorScheme.inverseSurface
                                  .withValues(alpha: 0.8),
                              tooltipRoundedRadius: 12,
                              tooltipPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              tooltipMargin: 16,
                              getTooltipItems: (
                                List<LineBarSpot> touchedSpots,
                              ) {
                                return touchedSpots.map((
                                  LineBarSpot touchedSpot,
                                ) {
                                  final month = touchedSpot.x.toInt() + 1;
                                  final amount = touchedSpot.y.toInt();
                                  return LineTooltipItem(
                                    '$month月\n',
                                    TextStyle(
                                      color: colorScheme.onInverseSurface,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: '${formatter.format(amount)}円',
                                        style: TextStyle(
                                          color: colorScheme.onInverseSurface,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList();
                              },
                            ),
                            handleBuiltInTouches: true,
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
                              curveSmoothness: 0.35,
                              color: colorScheme.primary,
                              barWidth: 4,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 4,
                                    color: colorScheme.surface,
                                    strokeWidth: 3,
                                    strokeColor: colorScheme.primary,
                                  );
                                },
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    colorScheme.primary.withValues(alpha: 0.3),
                                    colorScheme.primary.withValues(alpha: 0.0),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],
                          minX: 0,
                          maxX: 11,
                          minY: 0,
                          maxY: (maxValue * 1.1).clamp(
                            100,
                            double.infinity,
                          ), // 最低でも少し高さを確保
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            '年間合計',
                            '${formatter.format(totalAmount)}円',
                            Icons.account_balance_wallet,
                            colorScheme.primaryContainer,
                            colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            '月平均',
                            '${formatter.format(averageAmount)}円',
                            Icons.analytics,
                            colorScheme.secondaryContainer,
                            colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color bgColor,
    Color fgColor,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: fgColor.withValues(alpha: 0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: fgColor),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: fgColor,
              ),
            ),
          ),
        ],
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
