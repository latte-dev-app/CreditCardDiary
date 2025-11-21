import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../application/fixed_cost_provider.dart';
import '../../domain/fixed_cost_model.dart';
import '../../application/card_provider.dart';
import '../widgets/animated_fab.dart';
import '../widgets/glass_modal.dart';
import '../widgets/glass_text_field.dart';
import '../widgets/pie_chart_widget.dart';

class FixedCostScreen extends StatefulWidget {
  const FixedCostScreen({super.key});

  @override
  State<FixedCostScreen> createState() => _FixedCostScreenState();
}

class _FixedCostScreenState extends State<FixedCostScreen> {
  int _viewMode = 0; // 0: List, 1: Trend/Analysis
  int _analysisMode = 0; // 0: Trend (Line), 1: Analysis (Pie)
  int? _selectedYear;
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final fixedCostProvider = Provider.of<FixedCostProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // Background (Only visible in Trend/Analysis mode for consistency)
          if (_viewMode == 1) ...[
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              right: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colorScheme.secondary.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(color: Colors.transparent),
              ),
            ),
          ],

          Column(
            children: [
              // Fixed Header
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0F172A), // Deep Navy
                      const Color(0xFF3B82F6), // Vibrant Blue
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title & Toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '固定費管理',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SegmentedButton<int>(
                              segments: const [
                                ButtonSegment(
                                  value: 0,
                                  label: Text('一覧'),
                                  icon: Icon(Icons.list),
                                ),
                                ButtonSegment(
                                  value: 1,
                                  label: Text('分析'),
                                  icon: Icon(Icons.analytics),
                                ),
                              ],
                              selected: {_viewMode},
                              onSelectionChanged: (Set<int> newSelection) {
                                setState(() {
                                  _viewMode = newSelection.first;
                                });
                              },
                              style: ButtonStyle(
                                visualDensity: VisualDensity.compact,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor:
                                    WidgetStateProperty.resolveWith<Color?>((
                                      states,
                                    ) {
                                      if (states.contains(
                                        WidgetState.selected,
                                      )) {
                                        return Colors.white;
                                      }
                                      return Colors.white.withValues(
                                        alpha: 0.1,
                                      );
                                    }),
                                foregroundColor:
                                    WidgetStateProperty.resolveWith<Color?>((
                                      states,
                                    ) {
                                      if (states.contains(
                                        WidgetState.selected,
                                      )) {
                                        return colorScheme.primary;
                                      }
                                      return Colors.white;
                                    }),
                                side: WidgetStateProperty.all(BorderSide.none),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Total Amount (Always visible)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '毎月の固定費合計',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '¥${fixedCostProvider.totalMonthlyFixedCost.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                              style: theme.textTheme.displaySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 42,
                                height: 1.1,
                                letterSpacing: -1.0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              Expanded(
                child:
                    _viewMode == 0
                        ? _buildListView(context, fixedCostProvider)
                        : _buildTrendAnalysisView(context, fixedCostProvider),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton:
          _viewMode == 0
              ? Padding(
                padding: const EdgeInsets.only(bottom: 80),
                child: AnimatedFab(
                  onPressed: () => _showAddEditDialog(context, null),
                  icon: Icons.add,
                ),
              )
              : null,
    );
  }

  Widget _buildListView(BuildContext context, FixedCostProvider provider) {
    final theme = Theme.of(context);
    final cardProvider = Provider.of<CardProvider>(context);

    if (provider.fixedCosts.isEmpty) {
      return Center(
        child: Text(
          '固定費が登録されていません',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 80),
      itemCount: provider.fixedCosts.length,
      itemBuilder: (context, index) {
        final item = provider.fixedCosts[index];
        final cardName =
            item.cardId != null
                ? cardProvider.cards
                    .firstWhere(
                      (c) => c.id == item.cardId,
                      orElse: () => cardProvider.cards.first,
                    )
                    .name
                : '未設定';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.repeat, color: theme.colorScheme.primary),
            ),
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('毎月 ${item.paymentDay}日 • $cardName'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '¥${item.amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => _showAddEditDialog(context, item),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: theme.colorScheme.error,
                  ),
                  onPressed: () => _showDeleteConfirmation(context, item),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrendAnalysisView(
    BuildContext context,
    FixedCostProvider provider,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle Trend vs Analysis
          Center(
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  label: Text('推移'),
                  icon: Icon(Icons.show_chart),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text('分析'),
                  icon: Icon(Icons.pie_chart),
                ),
              ],
              selected: {_analysisMode},
              onSelectionChanged: (Set<int> newSelection) {
                setState(() {
                  _analysisMode = newSelection.first;
                });
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.comfortable,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                side: WidgetStateProperty.all(
                  BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (_analysisMode == 0)
            _buildLineChart(context, provider)
          else
            _buildPieChart(context, provider),
        ],
      ),
    );
  }

  Widget _buildLineChart(BuildContext context, FixedCostProvider provider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final totalMonthly = provider.totalMonthlyFixedCost;
    final monthlyTotals = List.filled(12, totalMonthly);
    final maxValue = totalMonthly.toDouble();
    final formatter = NumberFormat('#,###');
    final year = _selectedYear ?? DateTime.now().year;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Year Selector (Simplified for Fixed Cost as it's static for now)
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
              child: DropdownButton<int>(
                value: year,
                underline: const SizedBox.shrink(),
                icon: const Icon(Icons.arrow_drop_down),
                items:
                    [year, year - 1, year + 1].map((y) {
                      return DropdownMenuItem(value: y, child: Text('$y年'));
                    }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedYear = val;
                    });
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          '$year年の固定費推移',
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
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
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
                  tooltipBgColor: colorScheme.inverseSurface.withValues(
                    alpha: 0.8,
                  ),
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
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPieChart(BuildContext context, FixedCostProvider provider) {
    final theme = Theme.of(context);
    final fixedCosts = provider.fixedCosts;

    if (fixedCosts.isEmpty) {
      return Center(
        child: Text(
          '固定費が登録されていません',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    final pieData =
        fixedCosts.map((fc) {
          return PieData(name: fc.title, value: fc.amount.toDouble());
        }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '内訳分析',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 24),
        PieChartWidget(data: pieData),
        const SizedBox(height: 24),
        _buildDetailList(context, pieData),
      ],
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

  void _showAddEditDialog(BuildContext context, FixedCost? item) {
    final titleController = TextEditingController(text: item?.title ?? '');
    final amountController = TextEditingController(
      text: item?.amount.toString() ?? '',
    );
    final paymentDayController = TextEditingController(
      text: item?.paymentDay.toString() ?? '',
    );
    String? selectedCardId = item?.cardId;

    final cardProvider = Provider.of<CardProvider>(context, listen: false);
    if (selectedCardId == null && cardProvider.cards.isNotEmpty) {
      selectedCardId = cardProvider.cards.first.id;
    }

    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (context, setState) => GlassModal(
                  blur: 15,
                  opacity: 0.6,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(dialogContext).viewInsets.bottom,
                    ),
                    child: DraggableScrollableSheet(
                      initialChildSize: 0.85,
                      minChildSize: 0.5,
                      maxChildSize: 0.95,
                      expand: false,
                      builder:
                          (context, scrollController) => Column(
                            children: [
                              // Handle Bar
                              Center(
                                child: Container(
                                  margin: const EdgeInsets.only(
                                    top: 12,
                                    bottom: 8,
                                  ),
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              // Title
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      item == null ? '固定費を追加' : '固定費を編集',
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed:
                                          () => Navigator.pop(dialogContext),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),
                              // Content
                              Expanded(
                                child: ListView(
                                  controller: scrollController,
                                  padding: const EdgeInsets.all(24),
                                  children: [
                                    // Title Input
                                    Text(
                                      'タイトル',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 12),
                                    GlassTextField(
                                      controller: titleController,
                                      labelText: '例: 家賃',
                                    ),
                                    const SizedBox(height: 24),

                                    // Amount Input
                                    Text(
                                      '金額',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 12),
                                    GlassTextField(
                                      controller: amountController,
                                      labelText: '金額を入力',
                                      keyboardType: TextInputType.number,
                                    ),
                                    const SizedBox(height: 24),

                                    // Payment Day Input
                                    Text(
                                      '支払日',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 12),
                                    GlassTextField(
                                      controller: paymentDayController,
                                      labelText: '日 (1-31)',
                                      keyboardType: TextInputType.number,
                                    ),
                                    const SizedBox(height: 24),

                                    // Card Selection
                                    Text(
                                      '支払いカード',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 12),
                                    GlassDropdown<String>(
                                      value: selectedCardId,
                                      items:
                                          cardProvider.cards.map((card) {
                                            return DropdownMenuItem(
                                              value: card.id,
                                              child: Text(card.name),
                                            );
                                          }).toList(),
                                      onChanged:
                                          (value) => setState(
                                            () => selectedCardId = value,
                                          ),
                                    ),
                                    const SizedBox(height: 40),
                                  ],
                                ),
                              ),
                              // Bottom Buttons
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      height: 56,
                                      child: FilledButton(
                                        onPressed: () {
                                          final title = titleController.text;
                                          final amount =
                                              int.tryParse(
                                                amountController.text,
                                              ) ??
                                              0;
                                          final paymentDay =
                                              int.tryParse(
                                                paymentDayController.text,
                                              ) ??
                                              1;

                                          if (title.isEmpty || amount <= 0) {
                                            return;
                                          }

                                          final newItem = FixedCost(
                                            id: item?.id ?? const Uuid().v4(),
                                            title: title,
                                            amount: amount,
                                            paymentDay: paymentDay,
                                            cardId: selectedCardId,
                                          );

                                          final provider =
                                              Provider.of<FixedCostProvider>(
                                                context,
                                                listen: false,
                                              );
                                          if (item == null) {
                                            provider.addFixedCost(newItem);
                                          } else {
                                            provider.updateFixedCost(newItem);
                                          }
                                          Navigator.pop(context);
                                        },
                                        style: FilledButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          '保存',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (item != null) ...[
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 56,
                                        child: TextButton(
                                          onPressed: () {
                                            Navigator.pop(
                                              context,
                                            ); // Close bottom sheet first
                                            _showDeleteConfirmation(
                                              context,
                                              item,
                                            );
                                          },
                                          style: TextButton.styleFrom(
                                            foregroundColor:
                                                theme.colorScheme.error,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                          ),
                                          child: const Text(
                                            'この固定費を削除',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                    ),
                  ),
                ),
          ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, FixedCost item) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('固定費を削除'),
            content: Text('${item.title}を削除しますか？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () {
                  Provider.of<FixedCostProvider>(
                    context,
                    listen: false,
                  ).deleteFixedCost(item.id);
                  Navigator.pop(context);
                },
                child: const Text('削除'),
              ),
            ],
          ),
    );
  }
}
