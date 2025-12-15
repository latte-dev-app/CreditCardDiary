import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../application/card_provider.dart';
import '../../../../shared/services/notification_service.dart';

import '../dialogs/add_card_dialog.dart';
import '../dialogs/budget_dialog.dart';

import '../widgets/home_card_item.dart';
import '../widgets/home_budget_card.dart';
import '../../domain/logic/payment_logic.dart';
import '../../../../shared/widgets/native_touchable.dart';

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
  int _direction = 0; // -1 for previous, 1 for next
  
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
      _direction = -1;
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
    _loadBudget();
  }
  
  void _nextMonth() {
    HapticFeedback.lightImpact();
    setState(() {
      _direction = 1;
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
    final initialIndex = availableYears.indexOf(
      _selectedYear ?? _selectedMonth.year,
    );

    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => Container(
            height: 250,
            color: theme.scaffoldBackgroundColor,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('キャンセル'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CupertinoButton(
                      child: const Text('完了'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Expanded(
                  child: CupertinoPicker(
                    itemExtent: 32,
                    scrollController: FixedExtentScrollController(
                      initialItem: initialIndex >= 0 ? initialIndex : 0,
                    ),
                    onSelectedItemChanged: (index) {
                      HapticFeedback.selectionClick();
                      final year = availableYears[index];
              setState(() {
                        _selectedYear = year;
                        _direction = 0;
                        _selectedMonth = DateTime(year, _selectedMonth.month);
                      });
                      _loadBudget();
                    },
                    children:
                        availableYears
                            .map(
                              (year) => Center(
              child: Text(
                                  '$year年',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontSize: 20,
                                    color: theme.colorScheme.onSurface,
                ),
              ),
            ),
                            )
                            .toList(),
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

          // 残りの請求総額を計算（支払い済みでないカードの請求額の合計）
          int remainingAmount = 0;
          for (final card in provider.cards) {
            final isPaid = PaymentLogic.isPaid(card.paymentDay, year, month);
            if (!isPaid) {
              final cardAmount = monthTransactions
                  .where((t) => t.cardId == card.id)
                  .fold(0, (sum, t) => sum + t.amount);
              remainingAmount += cardAmount;
            }
          }

          // Sorting Logic
          final sortedCards = List.of(provider.cards);
          sortedCards.sort((a, b) {
            final aPaid = PaymentLogic.isPaid(a.paymentDay, year, month);
            final bPaid = PaymentLogic.isPaid(b.paymentDay, year, month);

            // 1. Paid status (Paid goes to bottom)
            if (!aPaid && bPaid) return -1;
            if (aPaid && !bPaid) return 1;

            final aApproaching = PaymentLogic.isPaymentDayApproaching(
              a.paymentDay,
            );
            final bApproaching = PaymentLogic.isPaymentDayApproaching(
              b.paymentDay,
            );

            // 2. Approaching payment (High priority for unpaid cards)
            // Note: Since we already separated Paid vs Unpaid, this effectively sorts the "Unpaid" group
            // If both are paid, this check still runs but approaching paid cards (rare/impossible?) would sort higher among paid
            if (aApproaching && !bApproaching) return -1;
            if (!aApproaching && bApproaching) return 1;

            // 3. Amount (Secondary sort)
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
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
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
                    NativeTouchable(
                      onTap: () => _showYearPicker(context, availableYears),
                      child: Container(
                                      constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
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
                              CupertinoIcons.chevron_down,
                              color: Colors.white.withValues(alpha: 0.9),
                              size: 20,
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
                  CupertinoButton(
                    padding: const EdgeInsets.all(8),
                    minimumSize: const Size(44, 44),
                    child: Icon(
                      CupertinoIcons.add,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    onPressed:
                        () => showAddCardDialog(context, onCardAdded: (_) {}),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.all(8),
                    minimumSize: const Size(44, 44),
                    onPressed: () {
                      setState(() {
                        _isPrivacyMode = !_isPrivacyMode;
                      });
                    },
                    child: Icon(
                      _isPrivacyMode
                          ? CupertinoIcons.eye_slash_fill
                          : CupertinoIcons.eye_fill,
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
                            // Total Amount and Remaining Amount in Row
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 今月の請求総額
                  Expanded(
                        child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                          '今月の請求総額',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: Colors.white.withValues(
                                              alpha: 0.7,
                                            ),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        AnimatedSwitcher(
                                          duration: const Duration(milliseconds: 300),
                                          transitionBuilder: (
                                            Widget child,
                                            Animation<double> animation,
                                          ) {
                                            // iOS標準のイージング曲線を使用
                                            final curvedAnimation = CurvedAnimation(
                                              parent: animation,
                                              curve: Curves.easeOutCubic,
                                            );
                                            if (_direction == 0) {
                                              return FadeTransition(
                                                opacity: curvedAnimation,
                                                child: child,
                                              );
                                            }
                                            final offset =
                                                _direction > 0
                                                    ? const Offset(1.0, 0.0)
                                                    : const Offset(-1.0, 0.0);
                                            return SlideTransition(
                                              position: Tween<Offset>(
                                                begin: offset,
                                                end: Offset.zero,
                                              ).animate(curvedAnimation),
                                              child: child,
                                            );
                                          },
                                          child: Text(
                                            _isPrivacyMode
                                                ? '****'
                                                : '¥${NumberFormat('#,###').format(totalAmount)}',
                                            key: ValueKey(
                                              '${_isPrivacyMode}_${totalAmount}_expanded',
                                            ),
                                            style: theme.textTheme.headlineMedium?.copyWith(
                                        color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // 残りの請求総額
                                  Expanded(
                                    child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                          '残りの請求総額',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: Colors.white.withValues(
                                              alpha: 0.7,
                                            ),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        AnimatedSwitcher(
                                          duration: const Duration(milliseconds: 300),
                                          transitionBuilder: (
                                            Widget child,
                                            Animation<double> animation,
                                          ) {
                                            // iOS標準のイージング曲線を使用
                                            final curvedAnimation = CurvedAnimation(
                                              parent: animation,
                                              curve: Curves.easeOutCubic,
                                            );
                                            if (_direction == 0) {
                                              return FadeTransition(
                                                opacity: curvedAnimation,
                                                child: child,
                                              );
                                            }
                                            final offset =
                                                _direction > 0
                                                    ? const Offset(1.0, 0.0)
                                                    : const Offset(-1.0, 0.0);
                                            return SlideTransition(
                                              position: Tween<Offset>(
                                                begin: offset,
                                                end: Offset.zero,
                                              ).animate(curvedAnimation),
                                              child: child,
                                            );
                                          },
                                          child: Text(
                                            _isPrivacyMode
                                                ? '****'
                                                : '¥${NumberFormat('#,###').format(remainingAmount)}',
                                            key: ValueKey(
                                              '${_isPrivacyMode}_${remainingAmount}_expanded',
                                            ),
                                            style: theme.textTheme.headlineMedium?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                      ),
                  ),
                ],
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
                            horizontal: 16,
                            vertical: 12,
                          ),
                          minimumSize: const Size(44, 44),
                        ),
                        child: Row(
                          children: [
                            const Icon(CupertinoIcons.chevron_left, size: 20),
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
                        NativeTouchable(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _isAmountAscending = !_isAmountAscending;
                            });
                          },
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: 44,
                              minHeight: 44,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
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
                                      ? CupertinoIcons.arrow_up
                                      : CupertinoIcons.arrow_down,
                                  size: 16,
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
                            horizontal: 16,
                            vertical: 12,
                          ),
                          minimumSize: const Size(44, 44),
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
                            const Icon(CupertinoIcons.chevron_right, size: 20),
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
                      child:                       AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (
                          Widget child,
                          Animation<double> animation,
                        ) {
                          // iOS標準のイージング曲線を使用
                          final curvedAnimation = CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          );
                          if (_direction == 0) {
                            return FadeTransition(
                              opacity: curvedAnimation,
                              child: child,
                            );
                          }
                          final offset =
                              _direction > 0
                                  ? const Offset(1.0, 0.0)
                                  : const Offset(-1.0, 0.0);
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: offset,
                              end: Offset.zero,
                            ).animate(curvedAnimation),
                            child: child,
                          );
                        },
                        child: HomeCardItem(
                          key: ValueKey('${card.id}_$month'),
                          card: card,
                          amount: cardMonthTotal,
                          currencyFormat: currencyFormat,
                          viewingYear: year,
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
              CupertinoIcons.creditcard,
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
