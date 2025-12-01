import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../application/fixed_cost_provider.dart';
import '../../domain/fixed_cost_model.dart';
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

    // Use the order from provider directly (user defined order)
    final fixedCosts = fixedCostProvider.fixedCosts;

    return Scaffold(
      bottomNavigationBar: BottomAppBar(
        color: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              onPressed: () => _showAddEditDialog(context, null),
              icon: Icon(Icons.add_circle, color: theme.colorScheme.primary),
              iconSize: 32,
              tooltip: '固定費を追加',
            ),
          ],
        ),
      ),
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

                  return Dismissible(
                    key: ValueKey(item.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.delete, color: Colors.white),
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
                    onDismissed: (direction) {
                      fixedCostProvider.deleteFixedCost(item.id);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: NativeTouchable(
                        onTap: () => _showAddEditDialog(context, item),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.repeat,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '¥${CurrencyFormatter.format(item.amount)}',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  ReorderableDragStartListener(
                                    index: index,
                                    child: const _AnimatedDragHandle(),
                                  ),
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
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.2,
                                  ),
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
                                        ?.copyWith(fontWeight: FontWeight.bold),
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
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: titleController,
                                    decoration: const InputDecoration(
                                      labelText: '例: 家賃',
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Amount Input
                                  Text(
                                    '金額',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: amountController,
                                    decoration: const InputDecoration(
                                      labelText: '金額を入力',
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                  const SizedBox(height: 24),

                                  // Payment Day Input
                                  Text(
                                    '支払日',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 12),
                                  ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    title: Text(
                                      '$selectedPaymentDay日',
                                      style: theme.textTheme.bodyLarge,
                                    ),
                                    trailing: const Icon(Icons.chevron_right),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: theme.colorScheme.outline,
                                      ),
                                    ),
                                    tileColor: theme.colorScheme.surface,
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

                                  // Card Selection
                                  Text(
                                    '支払いカード',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                    value: selectedCardId,
                                    decoration: const InputDecoration(
                                      labelText: '支払いカード',
                                    ),
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
                                      onPressed: () async {
                                        final title = titleController.text;
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
                                            cardId: selectedCardId,
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
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
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

    return await showModalBottomSheet<int?>(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            height: 300,
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '支払日を選択',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context, selectedIndex + 1);
                      },
                      child: const Text('決定'),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, FixedCost item) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('固定費の削除'),
            content: Text('「${item.title}」を削除してもよろしいですか？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () {
                  Provider.of<FixedCostProvider>(
                    context,
                    listen: false,
                  ).deleteFixedCost(item.id);
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('削除'),
              ),
            ],
          ),
    );
  }
}

class _AnimatedDragHandle extends StatefulWidget {
  const _AnimatedDragHandle();

  @override
  State<_AnimatedDragHandle> createState() => _AnimatedDragHandleState();
}

class _AnimatedDragHandleState extends State<_AnimatedDragHandle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _controller.forward(),
      onPointerUp: (_) => _controller.reverse(),
      onPointerCancel: (_) => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(
            12,
          ), // UIX-001: Increased padding for better touch target
          color: Colors.transparent, // Hit test area expansion
          child: const Icon(Icons.drag_handle, color: Colors.grey),
        ),
      ),
    );
  }
}
