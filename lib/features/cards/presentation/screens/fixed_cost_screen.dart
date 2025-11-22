import 'dart:ui';

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

enum SortOption { amountDesc, amountAsc, dateAsc, dateDesc }

class FixedCostScreen extends StatefulWidget {
  const FixedCostScreen({super.key});

  @override
  State<FixedCostScreen> createState() => _FixedCostScreenState();
}

class _FixedCostScreenState extends State<FixedCostScreen> {
  int _viewMode = 0; // 0: List, 1: Trend/Analysis
  SortOption _sortOption = SortOption.amountDesc;

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
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _viewMode = _viewMode == 0 ? 1 : 0;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _viewMode == 0
                                          ? Icons.pie_chart
                                          : Icons.list,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _viewMode == 0 ? '分析' : '一覧',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_viewMode == 0) ...[
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: _showSortMenu,
                                icon: const Icon(
                                  Icons.sort,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                label: Text(
                                  _getSortLabel(_sortOption),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.1,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
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

    final sortedList = List<FixedCost>.from(provider.fixedCosts);
    switch (_sortOption) {
      case SortOption.amountDesc:
        sortedList.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case SortOption.amountAsc:
        sortedList.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      case SortOption.dateAsc:
        sortedList.sort((a, b) => a.paymentDay.compareTo(b.paymentDay));
        break;
      case SortOption.dateDesc:
        sortedList.sort((a, b) => b.paymentDay.compareTo(a.paymentDay));
        break;
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 80),
      itemCount: sortedList.length,
      itemBuilder: (context, index) {
        final item = sortedList[index];
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      child: Column(
        children: [
          _buildYearlyTotalCard(context, provider),
          const SizedBox(height: 24),
          _buildPieChart(context, provider),
        ],
      ),
    );
  }

  Widget _buildYearlyTotalCard(
    BuildContext context,
    FixedCostProvider provider,
  ) {
    final theme = Theme.of(context);
    final yearlyTotal = provider.totalMonthlyFixedCost * 12;
    final formatter = NumberFormat('#,###');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.calendar_month_rounded,
              color: theme.colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '年間固定費（見込み）',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '¥${formatter.format(yearlyTotal)}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSortMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => GlassModal(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '並び替え',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildSortOptionItem(SortOption.amountDesc, '金額が高い順'),
                _buildSortOptionItem(SortOption.amountAsc, '金額が低い順'),
                _buildSortOptionItem(SortOption.dateAsc, '支払日が早い順'),
                _buildSortOptionItem(SortOption.dateDesc, '支払日が遅い順'),
                const SizedBox(height: 24),
              ],
            ),
          ),
    );
  }

  Widget _buildSortOptionItem(SortOption option, String label) {
    final isSelected = _sortOption == option;
    final theme = Theme.of(context);

    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color:
              isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
        ),
      ),
      trailing:
          isSelected
              ? Icon(Icons.check, color: theme.colorScheme.primary)
              : null,
      onTap: () {
        setState(() {
          _sortOption = option;
        });
        Navigator.pop(context);
      },
    );
  }

  String _getSortLabel(SortOption option) {
    switch (option) {
      case SortOption.amountDesc:
        return '金額順 (降順)';
      case SortOption.amountAsc:
        return '金額順 (昇順)';
      case SortOption.dateAsc:
        return '日付順 (昇順)';
      case SortOption.dateDesc:
        return '日付順 (降順)';
    }
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
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
            PieChartWidget(data: pieData, isWide: isWide),
            if (!isWide) ...[
              const SizedBox(height: 24),
              _buildDetailList(context, pieData),
            ],
          ],
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
