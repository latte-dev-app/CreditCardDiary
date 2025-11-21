import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../application/card_provider.dart';
import '../../../../shared/services/notification_service.dart';
import 'card_detail_screen.dart';
import '../dialogs/add_card_dialog.dart';
import '../dialogs/budget_dialog.dart';
import '../widgets/animated_fab.dart';

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
      _loadBudget();
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
                  style: GoogleFonts.plusJakartaSans(
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
                          style: GoogleFonts.plusJakartaSans(
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

  bool _isPaymentDayApproaching(int? paymentDay) {
    if (paymentDay == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check current month's payment day
    DateTime paymentDate = DateTime(now.year, now.month, paymentDay);

    // If passed, check next month
    if (paymentDate.isBefore(today)) {
      paymentDate = DateTime(now.year, now.month + 1, paymentDay);
    }

    final difference = paymentDate.difference(today).inDays;
    return difference >= 0 && difference <= 3;
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
          final budgetProgress =
              budget > 0 ? (totalAmount / budget).clamp(0.0, 1.0) : 0.0;
          final remainingBudget = budget - totalAmount;

          return Column(
            children: [
              // Fixed Header
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0F172A), // Deep Navy
                      Color(0xFF3B82F6), // Vibrant Blue
                    ],
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
                        // Top Bar: Date Only
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap:
                                  () =>
                                      _showYearPicker(context, availableYears),
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
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      size: 24,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Total Amount (Static)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '今月の請求総額',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currencyFormat.format(totalAmount),
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                  height: 1.1,
                                  letterSpacing: -1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Budget Section
                        InkWell(
                          onTap:
                              () => showBudgetDialog(
                                context,
                                provider,
                                year,
                                month,
                              ),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      budget > 0
                                          ? '残り予算: ${currencyFormat.format(remainingBudget)}'
                                          : '予算を設定する',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (budget > 0)
                                      Text(
                                        '${(budgetProgress * 100).toInt()}%',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                                if (budget > 0) ...[
                                  const SizedBox(height: 12),
                                  Stack(
                                    children: [
                                      Container(
                                        height: 12,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                      ),
                                      FractionallySizedBox(
                                        widthFactor: budgetProgress,
                                        child: Container(
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color:
                                                remainingBudget < 0
                                                    ? theme.colorScheme.error
                                                    : const Color(
                                                      0xFF34D399,
                                                    ), // Emerald 400
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: (remainingBudget < 0
                                                        ? theme
                                                            .colorScheme
                                                            .error
                                                        : const Color(
                                                          0xFF34D399,
                                                        ))
                                                    .withValues(alpha: 0.5),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Scrollable Body
              Expanded(
                child: Column(
                  children: [
                    // Month Navigation
                    Padding(
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
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '登録カード',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
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
                                  style: GoogleFonts.plusJakartaSans(
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
                    // Card List
                    Expanded(
                      child:
                          provider.cards.isEmpty
                              ? _buildEmptyState(context)
                              : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  8,
                                  20,
                                  80,
                                ),
                                itemCount: provider.cards.length,
                                itemBuilder: (context, index) {
                                  final card = provider.cards[index];
                                  final cardMonthTotal = monthTransactions
                                      .where((t) => t.cardId == card.id)
                                      .fold(0, (sum, t) => sum + t.amount);
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _buildCardItem(
                                      context,
                                      card,
                                      cardMonthTotal,
                                      currencyFormat,
                                    ),
                                  );
                                },
                              ),
                    ),
                  ],
                ),
              ),
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
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '右下のボタンからカードを追加してください',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardItem(
    BuildContext context,
    dynamic card,
    int amount,
    NumberFormat currencyFormat,
  ) {
    final theme = Theme.of(context);
    final isPaymentApproaching = _isPaymentDayApproaching(card.paymentDay);
    final borderColor =
        isPaymentApproaching
            ? theme.colorScheme.error
            : theme.colorScheme.outline.withValues(alpha: 0.5);
    final borderWidth = isPaymentApproaching ? 2.0 : 1.0;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color:
                isPaymentApproaching
                    ? theme.colorScheme.error.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.03),
            blurRadius: isPaymentApproaching ? 20 : 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CardDetailScreen(card: card)),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Color(
                      int.parse(card.color.replaceFirst('#', '0xFF')),
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(
                          int.parse(card.color.replaceFirst('#', '0xFF')),
                        ).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child:
                      card.imagePath != null
                          ? ClipOval(
                            child: Image.file(
                              File(card.imagePath!),
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => const Icon(
                                    Icons.credit_card,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                            ),
                          )
                          : const Icon(
                            Icons.credit_card,
                            color: Colors.white,
                            size: 28,
                          ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            card.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          if (isPaymentApproaching) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.warning_rounded,
                              size: 18,
                              color: theme.colorScheme.error,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        card.type,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormat.format(amount),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color:
                            isPaymentApproaching
                                ? theme.colorScheme.error
                                : theme.colorScheme.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '今月の利用',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: theme.colorScheme.outline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
