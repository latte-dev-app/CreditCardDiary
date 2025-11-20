import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../domain/card_model.dart';
import '../../application/card_provider.dart';
import '../../infrastructure/image_storage.dart';
import '../widgets/number_input_formatter.dart';

class CardDetailScreen extends StatefulWidget {
  final CreditCard card;
  final bool autoOpenAddTransactionDialog;

  const CardDetailScreen({
    super.key,
    required this.card,
    this.autoOpenAddTransactionDialog = false,
  });

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  late CreditCard card;

  @override
  void initState() {
    super.initState();
    card = widget.card;

    if (widget.autoOpenAddTransactionDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showAddTransactionDialog(context);
        }
      });
    }
  }

  @override
  void didUpdateWidget(CardDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card != widget.card) {
      setState(() {
        card = widget.card;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'ja_JP', symbol: '¥');

    return Scaffold(
      appBar: AppBar(
        title: Text(card.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showCardSettings(context),
            tooltip: 'カード設定',
          ),
        ],
      ),
      body: Consumer<CardProvider>(
        builder: (context, provider, _) {
          final transactions = provider.getTransactionsByCardId(card.id);
          final monthlyTotal = provider.getMonthlyTotalByCardId(card.id);
          final sortedMonths = monthlyTotal.keys.toList()
            ..sort((a, b) => b.compareTo(a)); // Descending

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildCardHeader(context, theme, currencyFormat),
                      const SizedBox(height: 24),
                      if (transactions.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.receipt_long_rounded,
                                  size: 48,
                                  color: theme.colorScheme.outline,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '利用履歴がありません',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (transactions.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final monthKey = sortedMonths[index];
                      final amount = monthlyTotal[monthKey]!;
                      final monthTransactions = transactions
                          .where((t) =>
                              '${t.year}-${t.month.toString().padLeft(2, '0')}' ==
                              monthKey)
                          .toList();

                      return _buildMonthSection(context, theme, monthKey,
                          amount, monthTransactions, currencyFormat);
                    },
                    childCount: sortedMonths.length,
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTransactionDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('支出記録'),
      ),
    );
  }

  Widget _buildCardHeader(
      BuildContext context, ThemeData theme, NumberFormat currencyFormat) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color:
                        Color(int.parse(card.color.replaceFirst('#', '0xFF'))),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: card.imagePath != null
                      ? ClipOval(
                          child: Image.file(
                            File(card.imagePath!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.credit_card,
                                color: Colors.white,
                                size: 32),
                          ),
                        )
                      : const Icon(Icons.credit_card,
                          color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        card.type,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(theme, '締め日',
                    card.closingDay != null ? '${card.closingDay}日' : '未設定'),
                _buildInfoItem(theme, '支払日',
                    card.paymentDay != null ? '${card.paymentDay}日' : '未設定'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(ThemeData theme, String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthSection(
    BuildContext context,
    ThemeData theme,
    String monthKey,
    int totalAmount,
    List<Transaction> transactions,
    NumberFormat currencyFormat,
  ) {
    final parts = monthKey.split('-');
    final year = parts[0];
    final month = parts[1];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$year年$month月',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                currencyFormat.format(totalAmount),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Column(
            children: transactions.map((transaction) {
              return ListTile(
                title: Text(
                  currencyFormat.format(transaction.amount),
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: transaction.title.isNotEmpty
                    ? Text(transaction.title)
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () =>
                          _showEditTransactionDialog(context, transaction),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () =>
                          _showDeleteTransactionDialog(context, transaction),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _showCardSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('カード情報を編集'),
              onTap: () {
                Navigator.pop(context);
                _showEditCardDialog(context, card);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('締め日・支払日設定'),
              onTap: () {
                Navigator.pop(context);
                _showDateSettingsDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.pie_chart),
              title: const Text('予算設定'),
              onTap: () {
                Navigator.pop(context);
                _showCardBudgetDialog(
                    context, context.read<CardProvider>(), card);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('カードを削除', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCardDialog(BuildContext context, CreditCard card) async {
    final nameController = TextEditingController(text: card.name);
    final typeController = TextEditingController(text: card.type);
    String selectedColor = card.color;
    String? currentImagePath = card.imagePath;
    File? selectedImageFile;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('カード編集'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final image =
                        await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      setDialogState(() {
                        selectedImageFile = File(image.path);
                        currentImagePath = null;
                      });
                    }
                  },
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: selectedImageFile != null
                        ? FileImage(selectedImageFile!)
                        : (currentImagePath != null
                            ? FileImage(File(currentImagePath!))
                            : null) as ImageProvider?,
                    child:
                        (selectedImageFile == null && currentImagePath == null)
                            ? const Icon(Icons.add_a_photo)
                            : null,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'カード名'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: typeController,
                  decoration: const InputDecoration(labelText: 'カード種類'),
                ),
                const SizedBox(height: 16),
                _buildColorPicker(selectedColor,
                    (color) => setDialogState(() => selectedColor = color)),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル')),
            FilledButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  String? imagePath = currentImagePath;
                  if (selectedImageFile != null) {
                    imagePath = await ImageStorage.saveImage(
                        selectedImageFile!, card.id);
                  }

                  final updatedCard = card.copyWith(
                    name: nameController.text,
                    type: typeController.text,
                    color: selectedColor,
                    imagePath: imagePath,
                  );
                  if (context.mounted) {
                    await context.read<CardProvider>().updateCard(updatedCard);
                    setState(() => this.card = updatedCard);
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPicker(
      String selectedColor, Function(String) onColorSelected) {
    final colors = [
      '#F44336',
      '#E91E63',
      '#9C27B0',
      '#673AB7',
      '#3F51B5',
      '#2196F3',
      '#009688',
      '#4CAF50',
      '#FFC107',
      '#FF9800',
      '#795548',
      '#607D8B'
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors.map((color) {
        final isSelected = selectedColor == color;
        return GestureDetector(
          onTap: () => onColorSelected(color),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
              shape: BoxShape.circle,
              border:
                  isSelected ? Border.all(color: Colors.black, width: 2) : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
          ),
        );
      }).toList(),
    );
  }

  void _showDateSettingsDialog(BuildContext context) {
    int? selectedClosingDay = card.closingDay;
    int? selectedPaymentDay = card.paymentDay;
    final days = List.generate(31, (index) => index + 1);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('締め日/支払日設定'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int?>(
                value: selectedClosingDay,
                decoration: const InputDecoration(labelText: '締め日'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('未設定')),
                  ...days.map(
                      (d) => DropdownMenuItem(value: d, child: Text('$d日'))),
                ],
                onChanged: (v) => setDialogState(() => selectedClosingDay = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int?>(
                value: selectedPaymentDay,
                decoration: const InputDecoration(labelText: '支払日'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('未設定')),
                  ...days.map(
                      (d) => DropdownMenuItem(value: d, child: Text('$d日'))),
                ],
                onChanged: (v) => setDialogState(() => selectedPaymentDay = v),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル')),
            FilledButton(
              onPressed: () {
                final updatedCard = card.copyWith(
                  closingDay: selectedClosingDay,
                  paymentDay: selectedPaymentDay,
                );
                context.read<CardProvider>().updateCard(updatedCard);
                setState(() => card = updatedCard);
                Navigator.pop(context);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCardBudgetDialog(
      BuildContext context, CardProvider provider, CreditCard card) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('予算設定'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            NumberTextInputFormatter()
          ],
          decoration:
              const InputDecoration(labelText: '月予算 (円)', suffixText: '円'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル')),
          FilledButton(
            onPressed: () {
              final amount =
                  int.tryParse(controller.text.replaceAll(',', '')) ?? 0;
              if (amount > 0) {
                provider.setCardBudget(
                    card.id, DateTime.now().year, DateTime.now().month, amount);
              }
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('カード削除'),
        content: const Text('このカードと全ての支出記録を削除しますか？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () {
              context.read<CardProvider>().deleteCard(card.id);
              Navigator.pop(context); // Dialog
              Navigator.pop(context); // Screen
            },
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context) {
    final amountController = TextEditingController();
    final titleController = TextEditingController();
    int selectedYear = DateTime.now().year;
    int selectedMonth = DateTime.now().month;
    final years = List.generate(10, (index) => DateTime.now().year - 5 + index);
    final months = List.generate(12, (index) => index + 1);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('支出追加'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: selectedYear,
                      items: years
                          .map((y) =>
                              DropdownMenuItem(value: y, child: Text('$y年')))
                          .toList(),
                      onChanged: (v) => setDialogState(() => selectedYear = v!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: selectedMonth,
                      items: months
                          .map((m) =>
                              DropdownMenuItem(value: m, child: Text('$m月')))
                          .toList(),
                      onChanged: (v) =>
                          setDialogState(() => selectedMonth = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  NumberTextInputFormatter()
                ],
                decoration:
                    const InputDecoration(labelText: '金額', suffixText: '円'),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'メモ (任意)'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル')),
            FilledButton(
              onPressed: () {
                final amount =
                    int.tryParse(amountController.text.replaceAll(',', ''));
                if (amount != null) {
                  final transaction = Transaction(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    cardId: card.id,
                    amount: amount,
                    year: selectedYear,
                    month: selectedMonth,
                    title: titleController.text,
                  );
                  context.read<CardProvider>().addTransaction(transaction);
                  Navigator.pop(context);
                }
              },
              child: const Text('追加'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTransactionDialog(
      BuildContext context, Transaction transaction) {
    final amountController = TextEditingController(
        text: NumberFormat('#,###').format(transaction.amount));
    final titleController = TextEditingController(text: transaction.title);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('支出編集'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                NumberTextInputFormatter()
              ],
              decoration:
                  const InputDecoration(labelText: '金額', suffixText: '円'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'メモ'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル')),
          FilledButton(
            onPressed: () {
              final amount =
                  int.tryParse(amountController.text.replaceAll(',', ''));
              if (amount != null) {
                final updatedTransaction = transaction.copyWith(
                  amount: amount,
                  title: titleController.text,
                );
                context
                    .read<CardProvider>()
                    .updateTransaction(updatedTransaction);
                Navigator.pop(context);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showDeleteTransactionDialog(
      BuildContext context, Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('支出削除'),
        content: const Text('この記録を削除しますか？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () {
              context.read<CardProvider>().deleteTransaction(transaction.id);
              Navigator.pop(context);
            },
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
}
