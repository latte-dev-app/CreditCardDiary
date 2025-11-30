import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../application/card_provider.dart';
import '../../../../shared/services/notification_service.dart';

import '../dialogs/add_card_dialog.dart';
import '../dialogs/budget_dialog.dart';

import '../widgets/animated_fab.dart';
import '../widgets/home_card_item.dart';
import '../widgets/home_budget_card.dart';
import '../../domain/logic/payment_logic.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedMonth = DateTime.now();
  int? _selectedYear;
  bool _isPrivacyMode = false;
  bool _isAmountAscending = false;
  final ScrollController _scrollController = ScrollController();
  bool _isSliverCollapsed = false;
  static const double _expandedHeight = 340.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<CardProvider>();
      await provider.init();
      _loadBudget();
      await NotificationService.checkPaymentReminders(provider);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final isCollapsed =
        _scrollController.offset > (_expandedHeight - kToolbarHeight);
    if (isCollapsed != _isSliverCollapsed) {
      setState(() {
        _isSliverCollapsed = isCollapsed;
      });
    }
  }

  void _previousMonth() {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
    _loadBudget();
  }

  void _nextMonth() {
    HapticFeedback.lightImpact();
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

  void _showYearPicker(BuildContext context, List<int> availableYears) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '年を選択',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: availableYears.length,
                    itemBuilder: (context, index) {
                      final year = availableYears[index];
                      final isSelected =
                          year == (_selectedYear ?? _selectedMonth.year);
                      return ListTile(
                        title: Text(
                          '$year年',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontSize: 16,
                            fontWeight:
                                isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                            color:
                                isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedYear = year;
                            _selectedMonth = DateTime(
                              year,
                              _selectedMonth.month,
                            );
                          });
                          _loadBudget();
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final year = _selectedYear ?? _selectedMonth.year;
    final month = _selectedMonth.month;
    final availableYears = _getAvailableYears();
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'ja_JP', symbol: '¥');

    final prevMonthDate = DateTime(year, month - 1);
    final nextMonthDate = DateTime(year, month + 1);

    return Scaffold(
      body: Consumer<CardProvider>(
        builder: (context, provider, _) {
          final totalAmount = provider.getTotalByMonth(year, month);
          final monthTransactions = provider.getTransactionsByMonth(
            year,
            month,
          );
          final budget = provider.getCachedTotalBudget(year, month) ?? 0;

          // Sorting Logic
          final sortedCards = List.of(provider.cards);
          sortedCards.sort((a, b) {
            final aApproaching = PaymentLogic.isPaymentDayApproaching(
              a.paymentDay,
            );
            final bApproaching = PaymentLogic.isPaymentDayApproaching(
              b.paymentDay,
            );

            // 1. Approaching payment (High priority)
            if (aApproaching && !bApproaching) return -1;
            if (!aApproaching && bApproaching) return 1;

            // 2. Amount (Secondary sort)
            final aAmount = monthTransactions
                .where((t) => t.cardId == a.id)
                .fold(0, (sum, t) => sum + t.amount);
            final bAmount = monthTransactions
                .where((t) => t.cardId == b.id)
                .fold(0, (sum, t) => sum + t.amount);

            if (_isAmountAscending) {
              return aAmount.compareTo(bAmount);
            } else {
              return bAmount.compareTo(aAmount);
            }
          });

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: _expandedHeight,
                backgroundColor: theme.colorScheme.primary,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(32),
                  ),
                ),
                title: Row(
                  children: [
                    InkWell(
                      onTap: () => _showYearPicker(context, availableYears),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            Text(
                              '$year年$month月',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.white.withValues(alpha: 0.9),
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    AnimatedOpacity(
                      opacity: _isSliverCollapsed ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _isPrivacyMode
                              ? '****'
                              : '¥${NumberFormat('#,###').format(totalAmount)}',
                          key: ValueKey(
                            '${_isPrivacyMode}_${totalAmount}_collapsed',
                          ),
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isPrivacyMode = !_isPrivacyMode;
                      });
                    },
                    icon: Icon(
                      _isPrivacyMode ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primaryContainer,
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(32),
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Total Amount
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '今月の請求総額',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: Text(
                                      _isPrivacyMode
                                          ? '****'
                                          : '¥${NumberFormat('#,###').format(totalAmount)}',
                                      key: ValueKey(
                                        '${_isPrivacyMode}_${totalAmount}_expanded',
                                      ),
                                      style: theme.textTheme.displaySmall
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Budget Section
                            HomeBudgetCard(
                              totalAmount: totalAmount,
                              budget: budget,
                              isPrivacyMode: _isPrivacyMode,
                              onTap:
                                  () => showBudgetDialog(
                                    context,
                                    provider,
                                    year,
                                    month,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _previousMonth,
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurface,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.chevron_left, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              '${prevMonthDate.month}月',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Sort Button
                      if (sortedCards.isNotEmpty)
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isAmountAscending = !_isAmountAscending;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '登録カード',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  _isAmountAscending
                                      ? Icons.arrow_upward_rounded
                                      : Icons.arrow_downward_rounded,
                                  size: 18,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      TextButton(
                        onPressed: _nextMonth,
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurface,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '${nextMonthDate.month}月',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right, size: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (sortedCards.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(context),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final card = sortedCards[index];
                    final cardMonthTotal = monthTransactions
                        .where((t) => t.cardId == card.id)
                        .fold(0, (sum, t) => sum + t.amount);
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: HomeCardItem(
                          key: ValueKey('${card.id}_$month'),
                          card: card,
                          amount: cardMonthTotal,
                          currencyFormat: currencyFormat,
                          viewingMonth: month,
                          isPrivacyMode: _isPrivacyMode,
                        ),
                      ),
                    );
                  }, childCount: sortedCards.length),
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
            ],
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: AnimatedFab(
          onPressed: () => showAddCardDialog(context, onCardAdded: (_) {}),
          icon: Icons.add_card,
          label: 'カード追加',
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.credit_card_off_rounded,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'カードが登録されていません',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '右下のボタンからカードを追加してください',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
