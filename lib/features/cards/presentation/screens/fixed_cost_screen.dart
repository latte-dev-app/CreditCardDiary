import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../application/fixed_cost_provider.dart';
import '../../domain/fixed_cost_model.dart';
import '../../domain/card_model.dart';
import '../../domain/logic/payment_logic.dart';
import '../../application/card_provider.dart';
import '../../../../shared/widgets/native_dialog.dart';
import '../../../../shared/widgets/native_touchable.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/utils/currency_formatter.dart';

class FixedCostScreen extends StatefulWidget {
  const FixedCostScreen({super.key});

  @override
  State<FixedCostScreen> createState() => _FixedCostScreenState();
}

class _FixedCostScreenState extends State<FixedCostScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isSliverCollapsed = false;
  static const double _expandedHeight = 200.0;
  bool _isReorderMode = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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

  @override
  Widget build(BuildContext context) {
    final fixedCostProvider = Provider.of<FixedCostProvider>(context);
    final theme = Theme.of(context);
    final cardProvider = Provider.of<CardProvider>(context);

    // Create a sorted view of the fixed costs
    final originalList = fixedCostProvider.fixedCosts;
    final fixedCosts = List.of(originalList);
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;

    if (!_isReorderMode) {
      fixedCosts.sort((a, b) {
        // 1. Paid Status
        final aPaid = PaymentLogic.isPaid(a.paymentDay, year, month);
        final bPaid = PaymentLogic.isPaid(b.paymentDay, year, month);

        if (aPaid && !bPaid) return 1; // Paid goes to bottom
        if (!aPaid && bPaid) return -1;

        // 2. Approaching Status
        final aApproaching = PaymentLogic.isPaymentDayApproaching(a.paymentDay);
        final bApproaching = PaymentLogic.isPaymentDayApproaching(b.paymentDay);

        if (aApproaching && !bApproaching) return -1; // Approaching goes to top
        if (!aApproaching && bApproaching) return 1;

        // 3. User Defined Order (Manual)
        final indexA = originalList.indexOf(a);
        final indexB = originalList.indexOf(b);
        return indexA.compareTo(indexB);
      });
    }

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: _expandedHeight,
            backgroundColor: theme.colorScheme.primary,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            title: Row(
              children: [
                Text(
                  '固定費管理',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                AnimatedOpacity(
                  opacity: _isSliverCollapsed ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    '¥${CurrencyFormatter.format(fixedCostProvider.totalMonthlyFixedCost)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _isReorderMode = !_isReorderMode;
                  });
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  minimumSize: const Size(44, 44),
                ),
                child: Text(
                  _isReorderMode ? '完了' : '並び替え',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (!_isReorderMode)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Icon(CupertinoIcons.add, color: Colors.white),
                  onPressed: () => _showAddEditDialog(context, null),
                ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
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
                          Text(
                            '毎月の固定費合計',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '¥${CurrencyFormatter.format(fixedCostProvider.totalMonthlyFixedCost)}',
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
                    ),
                ),
              ),
            ),
          ),
          if (fixedCosts.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  '固定費が登録されていません',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 80),
              sliver: SliverReorderableList(
                onReorder: (oldIndex, newIndex) {
                  fixedCostProvider.reorderFixedCosts(oldIndex, newIndex);
                },
                itemBuilder: (context, index) {
                  final item = fixedCosts[index];
                  final cardName =
                      item.cardId != null
                          ? cardProvider.cards
                              .firstWhere(
                                (c) => c.id == item.cardId,
                                orElse: () => cardProvider.cards.first,
                              )
                              .name
                          : '未設定';

                  // Payment Logic checks
                  final now = DateTime.now();
                  final isPaymentApproaching =
                      PaymentLogic.isPaymentDayApproaching(item.paymentDay);
                  final isPaid = PaymentLogic.isPaid(
                    item.paymentDay,
                    now.year,
                    now.month,
                  );

                  String paymentInfo = '';
                  if (isPaid) {
                    paymentInfo = '支払い済み';
                  } else {
                    final today = DateTime(now.year, now.month, now.day);
                    DateTime paymentDate = DateTime(
                      now.year,
                      now.month,
                      item.paymentDay,
                    );

                    // Weekend Adjustment for display consistency
                    if (paymentDate.weekday == DateTime.saturday) {
                      paymentDate = paymentDate.add(const Duration(days: 2));
                    } else if (paymentDate.weekday == DateTime.sunday) {
                      paymentDate = paymentDate.add(const Duration(days: 1));
                    }

                    if (paymentDate.isBefore(today)) {
                      paymentDate = DateTime(
                        now.year,
                        now.month + 1,
                        item.paymentDay,
                      );
                      if (paymentDate.weekday == DateTime.saturday) {
                        paymentDate = paymentDate.add(const Duration(days: 2));
                      } else if (paymentDate.weekday == DateTime.sunday) {
                        paymentDate = paymentDate.add(const Duration(days: 1));
                      }
                    }
                    final difference = paymentDate.difference(today).inDays;

                    if (isPaymentApproaching) {
                      paymentInfo = 'あと$difference日';
                    }
                  }

                  return Dismissible(
                    key: ValueKey(item.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        CupertinoIcons.delete,
                        color: Colors.white,
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      return await showCupertinoDialog<bool>(
                        context: context,
                        builder:
                            (context) => CupertinoAlertDialog(
                              title: const Text('固定費の削除'),
                              content: Text('「${item.title}」を削除しますか？'),
                              actions: [
                                CupertinoDialogAction(
                                  isDefaultAction: true,
                                  onPressed:
                                      () => Navigator.pop(context, false),
                                  child: const Text('キャンセル'),
                                ),
                                CupertinoDialogAction(
                                  isDestructiveAction: true,
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('削除'),
                                ),
                              ],
                            ),
                      );
                    },
                    onDismissed: (_) {
                      fixedCostProvider.deleteFixedCost(item.id);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            isPaymentApproaching
                                ? Border.all(
                                  color: theme.colorScheme.error,
                                  width: 2,
                                )
                                : null,
                        boxShadow: [
                          BoxShadow(
                            color:
                                isPaymentApproaching
                                    ? theme.colorScheme.error.withValues(
                                      alpha: 0.15,
                                    )
                                    : Colors.black.withValues(alpha: 0.05),
                            blurRadius: isPaymentApproaching ? 16 : 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child:                       NativeTouchable(
                        onTap: () => _showAddEditDialog(context, item),
                        child: Container(
                          constraints: const BoxConstraints(
                            minHeight: 44,
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  CupertinoIcons.repeat,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            item.title,
                                            style: theme.textTheme.bodyLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isPaymentApproaching) ...[
                                          const SizedBox(width: 6),
                                          Icon(
                                            CupertinoIcons
                                                .exclamationmark_circle_fill,
                                            size: 16,
                                            color: theme.colorScheme.error,
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '毎月 ${item.paymentDay}日 • $cardName',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color:
                                                theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (paymentInfo.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          if (isPaid) ...[
                                            const Icon(
                                              CupertinoIcons
                                                  .check_mark_circled_solid,
                                              size: 12,
                                              color:
                                                  CupertinoColors.activeGreen,
                                            ),
                                            const SizedBox(width: 4),
                                          ],
                                          Text(
                                            paymentInfo,
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color:
                                                      isPaid
                                                          ? CupertinoColors
                                                              .activeGreen
                                                          : (isPaymentApproaching
                                                              ? theme
                                                                  .colorScheme
                                                                  .error
                                                              : theme
                                                                  .colorScheme
                                                                  .outline),
                                                  fontWeight:
                                                      (isPaymentApproaching ||
                                                              isPaid)
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '¥${CurrencyFormatter.format(item.amount)}',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isPaymentApproaching
                                              ? theme.colorScheme.error
                                              : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  if (_isReorderMode) ...[
                                    const SizedBox(width: 16),
                                    ReorderableDragStartListener(
                                      index: index,
                                      child: Container(
                                        constraints: const BoxConstraints(
                                          minWidth: 44,
                                          minHeight: 44,
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        color: Colors.transparent,
                                        child: Icon(
                                          Icons.drag_handle_rounded,
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                itemCount: fixedCosts.length,
              ),
            ),
        ],
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, FixedCost? item) {
    final titleController = TextEditingController(text: item?.title ?? '');
    final amountController = TextEditingController(
      text: item?.amount.toString() ?? '',
    );
    int selectedPaymentDay = item?.paymentDay ?? 1;
    String? selectedCardId = item?.cardId;

    final cardProvider = Provider.of<CardProvider>(context, listen: false);

    if (cardProvider.cards.isEmpty) {
      showNativeErrorDialog(context, '先にカードを登録してください');
      return;
    }

    if (selectedCardId == null && cardProvider.cards.isNotEmpty) {
      selectedCardId = cardProvider.cards.first.id;
    }

    final theme = Theme.of(context);
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (dialogContext) => StatefulBuilder(
            builder: (context, setState) {
              return LoadingOverlay(
                isLoading: isLoading,
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
                            Center(
                              child: Container(
                                margin: const EdgeInsets.only(
                                  top: 12,
                                  bottom: 8,
                                ),
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
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
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(CupertinoIcons.xmark),
                                    onPressed:
                                        () => Navigator.pop(dialogContext),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            Expanded(
                              child: ListView(
                                controller: scrollController,
                                padding: const EdgeInsets.all(24),
                                children: [
                                  Text(
                                    'タイトル',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: titleController,
                                    decoration: const InputDecoration(
                                      hintText: '例: 家賃',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                    ),
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                  const SizedBox(height: 24),

                                  Text(
                                    '金額',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: amountController,
                                    decoration: const InputDecoration(
                                      hintText: '金額を入力',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                    ),
                                    style: theme.textTheme.bodyLarge,
                                    keyboardType: TextInputType.number,
                                  ),
                                  const SizedBox(height: 24),

                                  Text(
                                    '支払日',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 12),
                                  CupertinoListTile(
                                    title: Text(
                                      '$selectedPaymentDay日',
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface,
                                          ),
                                    ),
                                    trailing: const Icon(
                                      CupertinoIcons.chevron_right,
                                      size: 20,
                                    ),
                                    backgroundColor: theme.colorScheme.surface,
                                    onTap: () async {
                                      final day = await _showDayPicker(
                                        context,
                                        initialDay: selectedPaymentDay,
                                      );
                                      if (day != null) {
                                        setState(() {
                                          selectedPaymentDay = day;
                                        });
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 24),

                                  Text(
                                    '支払いカード',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 12),
                                  CupertinoListTile(
                                    title: Text(
                                      cardProvider.cards
                                          .firstWhere(
                                            (c) => c.id == selectedCardId,
                                            orElse:
                                                () => cardProvider.cards.first,
                                          )
                                          .name,
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface,
                                          ),
                                    ),
                                    trailing: const Icon(
                                      CupertinoIcons.chevron_right,
                                      size: 20,
                                    ),
                                    backgroundColor: theme.colorScheme.surface,
                                    onTap: () {
                                      _showCardPicker(
                                        context,
                                        cardProvider.cards,
                                        selectedCardId!,
                                        (newId) {
                                          setState(() {
                                            selectedCardId = newId;
                                          });
                                        },
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 40),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: CupertinoButton.filled(
                                      onPressed: () async {
                                        final title =
                                            titleController.text.trim();
                                        final amount =
                                            int.tryParse(
                                              amountController.text,
                                            ) ??
                                            0;
                                        final paymentDay = selectedPaymentDay;

                                        if (title.isEmpty || amount <= 0) {
                                          showNativeErrorDialog(
                                            context,
                                            'タイトルと金額を入力してください',
                                          );
                                          return;
                                        }

                                        setState(() => isLoading = true);
                                        try {
                                          final newItem = FixedCost(
                                            id: item?.id ?? const Uuid().v4(),
                                            title: title,
                                            amount: amount,
                                            paymentDay: paymentDay,
                                            cardId: selectedCardId!,
                                          );

                                          final provider =
                                              context.read<FixedCostProvider>();
                                          if (item == null) {
                                            await provider.addFixedCost(
                                              newItem,
                                            );
                                          } else {
                                            await provider.updateFixedCost(
                                              newItem,
                                            );
                                          }

                                          if (context.mounted) {
                                            Navigator.pop(context);
                                          }
                                        } finally {
                                          if (context.mounted) {
                                            setState(() => isLoading = false);
                                          }
                                        }
                                      },
                                      child: Text(
                                        item == null ? '追加' : '保存',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (item != null) ...[
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: CupertinoButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _showDeleteConfirmation(
                                            context,
                                            item,
                                          );
                                        },
                                        child: Text(
                                          'この固定費を削除',
                                          style: TextStyle(
                                            color: theme.colorScheme.error,
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
              );
            },
          ),
    );
  }

  Future<int?> _showDayPicker(
    BuildContext context, {
    required int initialDay,
  }) async {
    final theme = Theme.of(context);
    int selectedIndex = initialDay - 1;

    return await showCupertinoModalPopup<int?>(
      context: context,
      builder:
          (context) => Container(
            height: 300,
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
                      onPressed: () {
                        Navigator.pop(context, selectedIndex + 1);
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: CupertinoPicker(
                    itemExtent: 32,
                    scrollController: FixedExtentScrollController(
                      initialItem: selectedIndex,
                    ),
                    onSelectedItemChanged: (index) {
                      HapticFeedback.selectionClick();
                      selectedIndex = index;
                    },
                    children: List.generate(31, (index) {
                      final day = index + 1;
                      return Center(
                        child: Text(
                          '$day日',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _showCardPicker(
    BuildContext context,
    List<CreditCard> cards,
    String currentCardId,
    Function(String) onSelected,
  ) async {
    final theme = Theme.of(context);
    final initialIndex = cards.indexWhere((c) => c.id == currentCardId);

    await showCupertinoModalPopup(
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
                      onSelected(cards[index].id);
                    },
                    children:
                        cards
                            .map(
                              (card) => Center(
                                child: Text(
                                  card.name,
                                  style: theme.textTheme.bodyLarge?.copyWith(
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

  void _showDeleteConfirmation(BuildContext context, FixedCost item) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('固定費の削除'),
            content: Text('「${item.title}」を削除してもよろしいですか？'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
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
