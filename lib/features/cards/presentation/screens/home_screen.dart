import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../application/card_provider.dart';
import '../../../../shared/notification_service.dart';
import 'card_comparison_screen.dart';
import 'card_detail_screen.dart';
import '../dialogs/add_card_dialog.dart';
import '../dialogs/budget_dialog.dart';
import '../widgets/summary_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedMonth = DateTime.now();
  int? _selectedYear;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<CardProvider>();
      await provider.init();
      // Load budget for current month
      final year = _selectedYear ?? _selectedMonth.year;
      final month = _selectedMonth.month;
      await provider.loadTotalBudget(year, month);
      await NotificationService.checkPaymentReminders(provider);
    });
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
    _loadBudget();
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
    _loadBudget();
  }

  void _loadBudget() {
    final provider = context.read<CardProvider>();
    final year = _selectedYear ?? _selectedMonth.year;
    final month = _selectedMonth.month;
    provider.loadTotalBudget(year, month);
  }

  List<int> _getAvailableYears() {
    final provider = context.read<CardProvider>();
    final years = provider.transactions.map((t) => t.year).toSet().toList();
    years.sort();
    return years.isNotEmpty ? years : [DateTime.now().year];
  }

  @override
  Widget build(BuildContext context) {
    final year = _selectedYear ?? _selectedMonth.year;
    final month = _selectedMonth.month;
    final availableYears = _getAvailableYears();
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'ja_JP', symbol: '¥');

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _previousMonth,
              tooltip: '前の月',
            ),
            PopupMenuButton<int>(
              onSelected: (selectedYear) {
                setState(() {
                  _selectedYear = selectedYear;
                  _selectedMonth = DateTime(selectedYear, month);
                });
                _loadBudget();
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: Row(
                  children: [
                    Text(
                      '$year年$month月',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
              itemBuilder: (context) => [
                ...availableYears.map((y) => PopupMenuItem(
                      value: y,
                      child: Text('$y年'),
                    )),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _nextMonth,
              tooltip: '次の月',
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CardComparisonScreen(),
                ),
              );
            },
            tooltip: '分析',
          ),
        ],
      ),
      body: Consumer<CardProvider>(
        builder: (context, provider, _) {
          final totalAmount = provider.getTotalByMonth(year, month);
          final monthTransactions =
              provider.getTransactionsByMonth(year, month);
          final budget = provider.getCachedTotalBudget(year, month);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SummaryCard(
                        title: '今月の請求',
                        amount: totalAmount.toDouble(),
                        icon: Icons.receipt_long_rounded,
                        subtitle: '${monthTransactions.length} 件の取引',
                      ),
                    ),
                    if (budget != null && budget > 0) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: SummaryCard(
                          title: '残り予算',
                          amount: (budget - totalAmount).toDouble(),
                          icon: Icons.account_balance_wallet_rounded,
                          color: (budget - totalAmount) < 0
                              ? theme.colorScheme.error
                              : theme.colorScheme.secondary,
                          subtitle: '予算: ${currencyFormat.format(budget)}',
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                if (budget == null || budget == 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: InkWell(
                      onTap: () =>
                          showBudgetDialog(context, provider, year, month),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline,
                                color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              '予算を設定する',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Text(
                  '登録カード',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                if (provider.cards.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.credit_card_off_rounded,
                            size: 48,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'カードが登録されていません',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.cards.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final card = provider.cards[index];
                      final cardMonthTotal = monthTransactions
                          .where((t) => t.cardId == card.id)
                          .fold(0, (sum, t) => sum + t.amount);

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.5)),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CardDetailScreen(card: card),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Color(int.parse(
                                        card.color.replaceFirst('#', '0xFF'))),
                                    shape: BoxShape.circle,
                                  ),
                                  child: card.imagePath != null
                                      ? ClipOval(
                                          child: Image.file(
                                            File(card.imagePath!),
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(Icons.credit_card,
                                                    color: Colors.white,
                                                    size: 20),
                                          ),
                                        )
                                      : const Icon(Icons.credit_card,
                                          color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        card.name,
                                        style:
                                            theme.textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${monthTransactions.where((t) => t.cardId == card.id).length} 件の利用',
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  currencyFormat.format(cardMonthTotal),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.chevron_right,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  size: 20,
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddCardDialog(
          context,
          onCardAdded: (_) {},
        ),
        icon: const Icon(Icons.add),
        label: const Text('カード追加'),
      ),
    );
  }
}
