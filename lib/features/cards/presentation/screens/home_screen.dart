import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/card_provider.dart';
import '../../../../shared/notification_service.dart';
import 'card_comparison_screen.dart';
import 'card_detail_screen.dart';
import '../dialogs/add_card_dialog.dart';
import '../dialogs/budget_dialog.dart';

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
    // データを読み込む
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<CardProvider>();
      await provider.init();
      // 支払日リマインド通知をチェック
      await NotificationService.checkPaymentReminders(provider);
    });
  }

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
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        elevation: 0,
        surfaceTintColor: colorScheme.surfaceTint,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart, size: 24.0),
            constraints: const BoxConstraints(
              minWidth: 48.0,
              minHeight: 48.0,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CardComparisonScreen(),
                ),
              );
            },
            tooltip: 'カード比較',
          ),
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 24.0),
            constraints: const BoxConstraints(
              minWidth: 48.0,
              minHeight: 48.0,
            ),
            onPressed: _previousMonth,
            tooltip: '前の月',
          ),
          PopupMenuButton<int>(
            onSelected: (selectedYear) {
              setState(() {
                _selectedYear = selectedYear;
                _selectedMonth = DateTime(selectedYear, month);
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$year年$month月',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 20.0),
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
          final monthTransactions = provider.getTransactionsByMonth(year, month);
          final totalAmount = monthTransactions.fold(0, (sum, t) => sum + t.amount);
          
          // 予算を取得
          final budgetFuture = provider.getTotalBudget(year, month);
          
          return FutureBuilder<int?>(
            future: budgetFuture,
            builder: (context, snapshot) {
              final budget = snapshot.data;
              final budgetRatio = budget != null && budget > 0 
                  ? (totalAmount / budget).clamp(0.0, 1.0)
                  : 0.0;
              
              return Column(
                children: [
                  // 予算バー
                  if (budget != null && budget > 0)
                    Container(
                      margin: const EdgeInsets.all(16.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '予算進捗',
                                style: textTheme.titleSmall,
                              ),
                              TextButton(
                                onPressed: () => showBudgetDialog(context, provider, year, month),
                                child: const Text('設定'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: budgetRatio,
                            backgroundColor: colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              budgetRatio >= 1.0
                                  ? Colors.red
                                  : budgetRatio >= 0.8
                                      ? Colors.orange
                                      : Colors.green,
                            ),
                            minHeight: 8,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${totalAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} / ${budget.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}円',
                                style: textTheme.bodySmall,
                              ),
                              Text(
                                '${(budgetRatio * 100).toStringAsFixed(1)}%',
                                style: textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: budgetRatio >= 1.0
                                      ? Colors.red
                                      : budgetRatio >= 0.8
                                          ? Colors.orange
                                          : Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      margin: const EdgeInsets.all(16.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '予算が設定されていません',
                            style: textTheme.titleSmall,
                          ),
                          TextButton(
                            onPressed: () => showBudgetDialog(context, provider, year, month),
                            child: const Text('設定'),
                          ),
                        ],
                      ),
                    ),
                  
                  // 合計金額表示
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary.withValues(alpha: 0.1),
                          colorScheme.secondary.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$year年$month月の合計',
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${totalAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}円',
                          style: textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // カード一覧
                  Expanded(
                    child: provider.cards.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.credit_card,
                              size: 48.0,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'カードが登録されていません',
                              style: textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: provider.cards.length,
                        itemBuilder: (context, index) {
                          final card = provider.cards[index];
                          // その月のカード別合計を計算
                          final cardMonthTotal = monthTransactions
                              .where((t) => t.cardId == card.id)
                              .fold(0, (sum, t) => sum + t.amount);
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: Duration(milliseconds: 300 + (index * 50)),
                            curve: Curves.easeInOutCubic,
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(20 * (1 - value), 0),
                                  child: Card(
                                    elevation: 2.0,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                      vertical: 8.0,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.0),
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
                                      borderRadius: BorderRadius.circular(12.0),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Row(
                                          children: [
                                            // カード色の円
                                            Container(
                                              width: 48.0,
                                              height: 48.0,
                                              decoration: BoxDecoration(
                                                color: Color(int.parse(card.color.replaceFirst('#', '0xFF'))),
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Color(int.parse(card.color.replaceFirst('#', '0xFF'))).withValues(alpha: 0.3),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: card.imagePath != null
                                                  ? ClipOval(
                                                      child: Image.file(
                                                        File(card.imagePath!),
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context, error, stackTrace) {
                                                          return Icon(
                                                            Icons.credit_card,
                                                            color: Colors.white,
                                                            size: 24.0,
                                                          );
                                                        },
                                                      ),
                                                    )
                                                  : Icon(
                                                      Icons.credit_card,
                                                      color: Colors.white,
                                                      size: 24.0,
                                                    ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    card.name,
                                                    style: textTheme.titleMedium?.copyWith(
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${cardMonthTotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}円',
                                                    style: textTheme.bodyLarge?.copyWith(
                                                      color: colorScheme.primary,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Icon(
                                              Icons.arrow_forward_ios,
                                              size: 16.0,
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: Material(
        elevation: 6,
        shape: const CircleBorder(),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue[400]!.withValues(alpha: 0.9),
                Colors.purple[400]!.withValues(alpha: 0.9),
                Colors.pink[400]!.withValues(alpha: 0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => showAddCardDialog(
                    context,
                    onCardAdded: (_) {},
                  ),
              borderRadius: BorderRadius.circular(28),
              child: const Center(
                child: Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
