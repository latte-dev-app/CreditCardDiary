import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../application/fixed_cost_provider.dart';
import '../../domain/fixed_cost_model.dart';
import '../../application/card_provider.dart';
import '../widgets/animated_fab.dart';
import '../widgets/glass_modal.dart';

class FixedCostScreen extends StatelessWidget {
  const FixedCostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fixedCostProvider = Provider.of<FixedCostProvider>(context);
    final cardProvider = Provider.of<CardProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // Fixed Header
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0F172A), // Deep Navy
                  Color(0xFF3B82F6), // Vibrant Blue
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
                    // Title
                    Text(
                      '固定費管理',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Total Amount
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

          // List
          Expanded(
            child:
                fixedCostProvider.fixedCosts.isEmpty
                    ? Center(
                      child: Text(
                        '固定費が登録されていません',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                      itemCount: fixedCostProvider.fixedCosts.length,
                      itemBuilder: (context, index) {
                        final item = fixedCostProvider.fixedCosts[index];
                        // Handle case where card might not be found or cardId is null
                        final cardName =
                            item.cardId != null
                                ? cardProvider.cards
                                    .firstWhere(
                                      (c) => c.id == item.cardId,
                                      orElse: () => cardProvider.cards.first,
                                    )
                                    .name // Simplified for now
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
                              child: Icon(
                                Icons.repeat,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            title: Text(
                              item.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '毎月 ${item.paymentDay}日 • $cardName',
                            ),
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
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 20,
                                  ),
                                  onPressed:
                                      () => _showAddEditDialog(context, item),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: theme.colorScheme.error,
                                  ),
                                  onPressed:
                                      () => _showDeleteConfirmation(
                                        context,
                                        item,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: AnimatedFab(
          onPressed: () => _showAddEditDialog(context, null),
          icon: Icons.add,
        ),
      ),
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
                                    TextField(
                                      controller: titleController,
                                      decoration: InputDecoration(
                                        labelText: '例: 家賃',
                                        filled: true,
                                        fillColor: theme
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withValues(alpha: 0.5),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 16,
                                            ),
                                      ),
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
                                    TextField(
                                      controller: amountController,
                                      decoration: InputDecoration(
                                        labelText: '金額を入力',
                                        filled: true,
                                        fillColor: theme
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withValues(alpha: 0.5),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 16,
                                            ),
                                      ),
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
                                    TextField(
                                      controller: paymentDayController,
                                      decoration: InputDecoration(
                                        labelText: '日 (1-31)',
                                        filled: true,
                                        fillColor: theme
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withValues(alpha: 0.5),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 16,
                                            ),
                                      ),
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
                                    DropdownButtonFormField<String>(
                                      value: selectedCardId,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: theme
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withValues(alpha: 0.5),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 16,
                                            ),
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
