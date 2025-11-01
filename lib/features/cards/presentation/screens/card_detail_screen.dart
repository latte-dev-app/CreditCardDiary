import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/card_model.dart';
import '../../application/card_provider.dart';
import '../../infrastructure/image_storage.dart';

class CardDetailScreen extends StatefulWidget {
  final CreditCard card;

  const CardDetailScreen({super.key, required this.card});

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  late CreditCard card;

  @override
  void initState() {
    super.initState();
    card = widget.card;
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
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(card.name, style: textTheme.titleLarge),
        elevation: 0,
        surfaceTintColor: colorScheme.surfaceTint,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, size: 24.0),
            constraints: const BoxConstraints(
              minWidth: 48.0,
              minHeight: 48.0,
            ),
            onPressed: () => _showEditCardDialog(context, card),
            tooltip: 'カード編集',
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 24.0),
            constraints: const BoxConstraints(
              minWidth: 48.0,
              minHeight: 48.0,
            ),
            onPressed: () => _showDeleteConfirmation(context),
            tooltip: 'カード削除',
          ),
        ],
      ),
      body: Consumer<CardProvider>(
        builder: (context, provider, _) {
          final transactions = provider.getTransactionsByCardId(card.id);
          final monthlyTotal = provider.getMonthlyTotalByCardId(card.id);
          
          // 月順にソート
          final sortedMonths = monthlyTotal.keys.toList()
            ..sort((a, b) => a.compareTo(b));
          
          // 最新月の合計を取得
          final latestMonthTotal = sortedMonths.isNotEmpty
              ? monthlyTotal[sortedMonths.last]!
              : 0;

          // 支払い済みかどうかを判定
          final now = DateTime.now();
          bool isPaid = false;
          if (card.paymentDay != null && sortedMonths.isNotEmpty) {
            // 最新の取引月を取得
            final latestMonth = sortedMonths.last;
            final latestYear = int.parse(latestMonth.split('-')[0]);
            final latestMonthNum = int.parse(latestMonth.split('-')[1]);
            
            // 支払日が過ぎているか確認
            if (now.year > latestYear || 
                (now.year == latestYear && now.month > latestMonthNum) ||
                (now.year == latestYear && now.month == latestMonthNum && now.day > card.paymentDay!)) {
              isPaid = true;
            }
          }

          return Column(
            children: [
              // 締め日/支払日設定ボタン
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showDateSettingsDialog(context),
                      icon: const Icon(Icons.calendar_today, size: 24.0),
                      label: const Text('締め日/支払日設定'),
                    ),
                  ],
                ),
              ),
              // カード別予算進捗バー
              FutureBuilder<int?>(
                future: provider.getCardBudget(card.id, DateTime.now().year, DateTime.now().month),
                builder: (context, snapshot) {
                  final budget = snapshot.data;
                  if (budget == null || budget == 0) {
                    return const SizedBox.shrink();
                  }
                  
                  final cardTotals = provider.getCardTotalsByMonth(
                    DateTime.now().year,
                    DateTime.now().month,
                  );
                  final total = cardTotals[card.id] ?? 0;
                  final progress = (total / budget).clamp(0.0, 1.0);
                  final isOverBudget = total > budget;
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isOverBudget ? colorScheme.error : colorScheme.outline.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '予算進捗',
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isOverBudget ? colorScheme.error : colorScheme.onSurface,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20.0),
                              constraints: const BoxConstraints(
                                minWidth: 48.0,
                                minHeight: 48.0,
                              ),
                              onPressed: () => _showCardBudgetDialog(context, provider, card),
                              tooltip: '予算を編集',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${total.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}円 / ${budget.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}円',
                          style: textTheme.bodySmall?.copyWith(
                            color: isOverBudget ? colorScheme.error : colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isOverBudget ? colorScheme.error : colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              // カード情報
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _parseColor(card.color),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                            Text(
                              card.name,
                              style: textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                                if (isPaid) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              card.type,
                              style: textTheme.bodyLarge?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        if (card.imagePath != null && File(card.imagePath!).existsSync())
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(card.imagePath!),
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          const Icon(
                            Icons.credit_card,
                            color: Colors.white,
                            size: 48,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (sortedMonths.isNotEmpty) ...[
                                Text(
                                  '${sortedMonths.last.replaceAll('-', '年')}月の使用額',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                              const Text(
                                '合計使用額',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${latestMonthTotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}円',
                            style: textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 支出一覧
              Expanded(
                child: transactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 48.0,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '支出が記録されていません',
                              style: textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = transactions[index];
                          return Card(
                            elevation: 2.0,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _parseColor(card.color),
                                radius: 20,
                                child: const Icon(
                                  Icons.shopping_cart,
                                  color: Colors.white,
                                  size: 24.0,
                                ),
                              ),
                              title: Text(
                                '${transaction.year}年${transaction.month}月',
                                style: textTheme.titleMedium,
                              ),
                              subtitle: Text(
                                '${transaction.month}月',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${transaction.amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}円',
                                    style: textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20.0),
                                    constraints: const BoxConstraints(
                                      minWidth: 48.0,
                                      minHeight: 48.0,
                                    ),
                                    onPressed: () {
                                      _showEditTransactionDialog(
                                        context,
                                        transaction,
                                      );
                                    },
                                    tooltip: '編集',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20.0),
                                    constraints: const BoxConstraints(
                                      minWidth: 48.0,
                                      minHeight: 48.0,
                                    ),
                                    onPressed: () {
                                      _showDeleteTransactionDialog(
                                        context,
                                        transaction,
                                      );
                                    },
                                    tooltip: '削除',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionDialog(context),
        tooltip: '支出追加',
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('カード削除', style: textTheme.titleLarge),
        content: Text(
          'このカードと全ての支出記録を削除しますか？',
          style: textTheme.bodyMedium,
        ),
        elevation: 24.0,
        actions: [
          TextButton(
            onPressed: () {
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<CardProvider>().deleteCard(card.id);
              if (!context.mounted) return;
              Navigator.pop(context); // ダイアログを閉じる
              if (!context.mounted) return;
              Navigator.pop(context); // 画面を戻る
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  void _showEditCardDialog(BuildContext context, CreditCard card) async {
    final nameController = TextEditingController(text: card.name);
    final typeController = TextEditingController(text: card.type);
    String selectedColor = card.color;
    String? currentImagePath = card.imagePath;
    File? selectedImageFile;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('カード編集', style: textTheme.titleLarge),
          elevation: 24.0,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 画像表示・選択
                GestureDetector(
                  onTap: () async {
                    final source = await showDialog<ImageSource>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('画像を選択', style: textTheme.titleLarge),
                        elevation: 24.0,
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.camera_alt),
                              title: const Text('カメラで撮影'),
                              onTap: () => Navigator.pop(context, ImageSource.camera),
                            ),
                            ListTile(
                              leading: const Icon(Icons.photo_library),
                              title: const Text('ギャラリーから選択'),
                              onTap: () => Navigator.pop(context, ImageSource.gallery),
                            ),
                            if (currentImagePath != null || selectedImageFile != null)
                              ListTile(
                                leading: const Icon(Icons.delete),
                                title: const Text('画像を削除'),
                                onTap: () {
                                  setDialogState(() {
                                    currentImagePath = null;
                                    selectedImageFile = null;
                                  });
                                  Navigator.pop(context);
                                },
                              ),
                          ],
                        ),
                      ),
                    );
                    if (source != null) {
                      final imageFile = await ImageStorage.pickImage(source);
                      if (imageFile != null) {
                        setDialogState(() {
                          selectedImageFile = imageFile;
                          currentImagePath = null;
                        });
                      }
                    }
                  },
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: selectedImageFile != null
                        ? Image.file(selectedImageFile!, fit: BoxFit.cover)
                        : currentImagePath != null && File(currentImagePath!).existsSync()
                            ? Image.file(File(currentImagePath!), fit: BoxFit.cover)
                            : const Icon(Icons.add_photo_alternate, size: 40),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'カード名',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: typeController,
                  decoration: const InputDecoration(
                    labelText: 'カード種類',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('色を選択'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    '#FF6B6B',
                    '#4ECDC4',
                    '#95E1D3',
                    '#F38181',
                    '#AA96DA',
                    '#FCBAD3',
                  ].map((color) {
                    final isSelected = selectedColor == color;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(
                            int.parse(color.replaceFirst('#', '0xFF')),
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.black : Colors.grey,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final type = typeController.text.trim();
                if (name.isNotEmpty && type.isNotEmpty) {
                  String? imagePath = currentImagePath;
                  
                  // 新しい画像が選択されている場合、保存
                  if (selectedImageFile != null) {
                    // 古い画像を削除
                    if (currentImagePath != null) {
                      await ImageStorage.deleteImage(currentImagePath);
                    }
                    // 新しい画像を保存
                    imagePath = await ImageStorage.saveImage(selectedImageFile!, card.id);
                  } else if (currentImagePath == null && card.imagePath != null) {
                    // 画像が削除された場合
                    await ImageStorage.deleteImage(card.imagePath);
                    imagePath = null;
                  }
                  
                  final updatedCard = card.copyWith(
                    name: name,
                    type: type,
                    color: selectedColor,
                    imagePath: imagePath,
                  );
                  // カードを更新（支出は保持）
                  if (!context.mounted) return;
                  final provider = context.read<CardProvider>();
                  await provider.updateCard(updatedCard);
                  if (context.mounted) {
                    Navigator.pop(context);
                    // 画面の状態を更新
                    setState(() {
                      card = updatedCard;
                    });
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

  void _showDateSettingsDialog(BuildContext context) {
    int? selectedClosingDay = card.closingDay;
    int? selectedPaymentDay = card.paymentDay;
    final days = List.generate(31, (index) => index + 1);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('締め日/支払日設定', style: textTheme.titleLarge),
          elevation: 24.0,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int?>(
                  value: selectedClosingDay,
                  decoration: const InputDecoration(
                    labelText: '締め日',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('未設定')),
                    ...days.map((day) => DropdownMenuItem(
                      value: day,
                      child: Text('$day日'),
                    )),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedClosingDay = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int?>(
                  value: selectedPaymentDay,
                  decoration: const InputDecoration(
                    labelText: '支払日',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('未設定')),
                    ...days.map((day) => DropdownMenuItem(
                      value: day,
                      child: Text('$day日'),
                    )),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedPaymentDay = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                final updatedCard = card.copyWith(
                  closingDay: selectedClosingDay,
                  paymentDay: selectedPaymentDay,
                );
                context.read<CardProvider>().updateCard(updatedCard);
                Navigator.pop(context);
                setState(() {
                  card = updatedCard;
                });
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context) {
    final amountController = TextEditingController();
    int selectedYear = DateTime.now().year;
    int selectedMonth = DateTime.now().month;
    
    // 年のリスト（現在年から5年後まで）
    final years = List.generate(
      10,
      (index) => DateTime.now().year - 5 + index,
    );
    
    // 月のリスト
    final months = List.generate(12, (index) => index + 1);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('支出追加', style: textTheme.titleLarge),
          elevation: 24.0,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: '金額',
                    hintText: '例: 3500',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: selectedYear,
                        decoration: const InputDecoration(
                          labelText: '年',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: years.map((year) {
                          return DropdownMenuItem(
                            value: year,
                            child: Text('$year年'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedYear = value;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: selectedMonth,
                        decoration: const InputDecoration(
                          labelText: '月',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: months.map((month) {
                          return DropdownMenuItem(
                            value: month,
                            child: Text('$month月'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedMonth = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                final amountStr = amountController.text.trim();
                
                if (amountStr.isNotEmpty) {
                  final amount = int.tryParse(amountStr);
                  if (amount != null && amount > 0) {
                    final transaction = Transaction(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      cardId: card.id,
                      title: '支出',
                      amount: amount,
                      year: selectedYear,
                      month: selectedMonth,
                    );
                    context.read<CardProvider>().addTransaction(transaction);
                    Navigator.pop(context);
                  }
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
    final amountController = TextEditingController(text: transaction.amount.toString());
    int selectedYear = transaction.year;
    int selectedMonth = transaction.month;
    
    // 年のリスト（現在年から5年後まで）
    final years = List.generate(
      10,
      (index) => DateTime.now().year - 5 + index,
    );
    
    // 月のリスト
    final months = List.generate(12, (index) => index + 1);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('支出編集', style: textTheme.titleLarge),
          elevation: 24.0,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: '金額',
                    hintText: '例: 3500',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: selectedYear,
                        decoration: const InputDecoration(
                          labelText: '年',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: years.map((year) {
                          return DropdownMenuItem(
                            value: year,
                            child: Text('$year年'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedYear = value;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: selectedMonth,
                        decoration: const InputDecoration(
                          labelText: '月',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: months.map((month) {
                          return DropdownMenuItem(
                            value: month,
                            child: Text('$month月'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedMonth = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                final amountStr = amountController.text.trim();
                
                if (amountStr.isNotEmpty) {
                  final amount = int.tryParse(amountStr);
                  if (amount != null && amount > 0) {
                    final updatedTransaction = transaction.copyWith(
                      amount: amount,
                      year: selectedYear,
                      month: selectedMonth,
                    );
                    context.read<CardProvider>().updateTransaction(updatedTransaction);
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

  void _showDeleteTransactionDialog(
      BuildContext context, Transaction transaction) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('支出削除', style: textTheme.titleLarge),
        content: Text(
          'この支出を削除しますか？',
          style: textTheme.bodyMedium,
        ),
        elevation: 24.0,
        actions: [
          TextButton(
            onPressed: () {
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<CardProvider>().deleteTransaction(transaction.id);
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  void _showCardBudgetDialog(BuildContext context, CardProvider provider, CreditCard card) async {
    final now = DateTime.now();
    final currentBudget = await provider.getCardBudget(card.id, now.year, now.month);
    if (!context.mounted) return;
    
    final budgetController = TextEditingController(
      text: currentBudget?.toString() ?? '',
    );
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${card.name}の予算設定', style: textTheme.titleLarge),
        elevation: 24.0,
        content: TextField(
          controller: budgetController,
          decoration: const InputDecoration(
            labelText: '予算額',
            hintText: '例: 50000',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          if (currentBudget != null)
            TextButton(
              onPressed: () async {
                await provider.setCardBudget(card.id, now.year, now.month, 0);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('削除', style: TextStyle(color: Colors.red)),
            ),
          ElevatedButton(
            onPressed: () async {
              final budgetStr = budgetController.text.trim();
              if (budgetStr.isNotEmpty) {
                final budget = int.tryParse(budgetStr);
                if (budget != null && budget > 0) {
                  await provider.setCardBudget(card.id, now.year, now.month, budget);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}


