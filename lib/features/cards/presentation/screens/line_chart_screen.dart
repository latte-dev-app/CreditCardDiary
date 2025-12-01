import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../application/card_provider.dart';

import '../../domain/card_model.dart';
import '../widgets/pie_chart_widget.dart';

class LineChartScreen extends StatefulWidget {
  const LineChartScreen({super.key});

  @override
  State<LineChartScreen> createState() => _LineChartScreenState();
}

class _LineChartScreenState extends State<LineChartScreen> {
  int? _selectedYear;
  DateTime _selectedMonth = DateTime.now();
  int _viewMode = 0; // 0: Trend (Line), 1: Analysis (Pie)

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: Text(
          '推移',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
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
                      // Sync month to the selected year
                      _selectedMonth = DateTime(y, _selectedMonth.month);
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
                          CupertinoIcons.chevron_down,
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
      body: Stack(
        children: [
          // Main Content
          Container(
            color: theme.scaffoldBackgroundColor,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sub Level Toggle (Trend vs Analysis)
                    Center(
                      child: SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(
                            value: 0,
                            label: Text('推移'),
                            icon: Icon(CupertinoIcons.graph_square),
                          ),
                          ButtonSegment(
                            value: 1,
                            label: Text('分析'),
                            icon: Icon(CupertinoIcons.chart_pie),
                          ),
                        ],
                        selected: {_viewMode},
                        onSelectionChanged: (Set<int> newSelection) {
                          setState(() {
                            _viewMode = newSelection.first;
                          });
                        },
                        style: ButtonStyle(
                          visualDensity: VisualDensity.comfortable,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          side: WidgetStateProperty.all(
                            BorderSide(
                              color: colorScheme.outline.withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_viewMode == 0) ...[
                      // Trend View (Line Chart)
                      _buildCardTrendView(context),
                    ] else ...[
                      // Analysis View (Pie Chart)
                      _buildMonthlyAnalysis(context),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSummaryCard(
    BuildContext context,
    int totalAmount,
    int averageAmount,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final formatter = NumberFormat('#,###');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.money_dollar_circle,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '年間合計',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${formatter.format(totalAmount)}円',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: colorScheme.onSurface,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: colorScheme.outlineVariant,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.graph_circle,
                            size: 16,
                            color: colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '月平均',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${formatter.format(averageAmount)}円',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardTrendView(BuildContext context) {
    return Consumer<CardProvider>(
      builder: (context, provider, _) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final textTheme = theme.textTheme;
        final years = _getAvailableYears(provider);

        if (years.isEmpty) {
          return _buildEmptyState(context, 'データがありません');
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroSummaryCard(context, totalAmount, averageAmount),
            const SizedBox(height: 32),
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
                _mainLineChartData(
                  colorScheme,
                  monthlyTotals,
                  maxValue,
                  formatter,
                  averageAmount,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  LineChartData _mainLineChartData(
    ColorScheme colorScheme,
    List<int> monthlyTotals,
    double maxValue,
    NumberFormat formatter,
    int averageAmount,
  ) {
    return LineChartData(
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          HorizontalLine(
            y: averageAmount.toDouble(),
            color: colorScheme.secondary,
            strokeWidth: 2,
            dashArray: [5, 5],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topRight,
              padding: const EdgeInsets.only(right: 5, bottom: 5),
              style: TextStyle(
                color: colorScheme.secondary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              labelResolver: (line) => '平均: ${formatter.format(averageAmount)}',
            ),
          ),
        ],
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxValue > 0 ? maxValue / 5 : 1,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
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
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    '$m月',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
            reservedSize: 32,
          ),
        ),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: colorScheme.inverseSurface.withValues(alpha: 0.8),
          tooltipRoundedRadius: 12,
          tooltipPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          tooltipMargin: 16,
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((LineBarSpot touchedSpot) {
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
            return FlSpot(index.toDouble(), monthlyTotals[index].toDouble());
          }),
          isCurved: true,
          curveSmoothness: 0.35,
          color: colorScheme.primary,
          barWidth: 4,
          isStrokeCapRound: true,
          shadow: Shadow(
            color: colorScheme.primary.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 6,
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
      maxY: (maxValue * 1.1).clamp(100, double.infinity),
    );
  }

  Widget _buildMonthlyAnalysis(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month Selector
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(CupertinoIcons.chevron_left, size: 20),
              onPressed: () {
                setState(() {
                  _selectedMonth = DateTime(
                    _selectedMonth.year,
                    _selectedMonth.month - 1,
                  );
                  // Sync year if month change crosses year boundary
                  if (_selectedMonth.year != _selectedYear) {
                    _selectedYear = _selectedMonth.year;
                  }
                });
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                DateFormat('yyyy年M月').format(_selectedMonth),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.chevron_right, size: 20),
              onPressed: () {
                setState(() {
                  _selectedMonth = DateTime(
                    _selectedMonth.year,
                    _selectedMonth.month + 1,
                  );
                  // Sync year if month change crosses year boundary
                  if (_selectedMonth.year != _selectedYear) {
                    _selectedYear = _selectedMonth.year;
                  }
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 24),

        Text(
          '月別内訳分析',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 24),

        // Content
        _buildCardAnalysis(context),
      ],
    );
  }

  Widget _buildCardAnalysis(BuildContext context) {
    return Consumer<CardProvider>(
      builder: (context, provider, _) {
        final totals = provider.getCardTotalsByMonth(
          _selectedMonth.year,
          _selectedMonth.month,
        );

        if (totals.isEmpty || totals.values.every((v) => v == 0)) {
          return _buildEmptyState(context, 'この月のカード支出はありません');
        }

        final pieData =
            totals.entries.map((e) {
              final card = provider.cards.firstWhere(
                (c) => c.id == e.key,
                orElse:
                    () => CreditCard(
                      id: 'unknown',
                      name: '不明なカード',
                      type: '',
                      color: '#808080',
                    ),
              );
              return PieData(
                name: card.name,
                value: e.value.toDouble(),
                color: _parseColor(card.color),
              );
            }).toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            return Column(
              children: [
                PieChartWidget(data: pieData, isWide: isWide),
                if (!isWide) ...[
                  const SizedBox(height: 24),
                  _buildDetailList(context, pieData),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDetailList(BuildContext context, List<PieData> data) {
    final sortedData = List<PieData>.from(data)
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = sortedData.fold(0.0, (sum, item) => sum + item.value);
    final formatter = NumberFormat('#,###');

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedData.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = sortedData[index];
        final percentage = (item.value / total * 100).toStringAsFixed(1);

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: item.color ?? Colors.grey,
            ),
          ),
          title: Text(
            item.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percentage%',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              Text(
                '¥${formatter.format(item.value.toInt())}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.chart_pie,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
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
