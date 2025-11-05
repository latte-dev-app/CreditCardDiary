import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../application/card_provider.dart';
import '../../domain/card_model.dart';
import '../../infrastructure/image_storage.dart';
import '../../../../shared/notification_service.dart';
import 'card_detail_screen.dart';
import 'card_comparison_screen.dart';

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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '$year年$month月',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            itemBuilder: (context) => availableYears.map((y) {
              return PopupMenuItem(
                value: y,
                child: Text('$y年'),
              );
            }).toList(),
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
          final monthTotal = provider.getTotalByMonth(year, month);
          final monthTransactions = provider.getTransactionsByMonth(year, month);
              
              return Column(
                children: [
                  // 月別サマリー
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                margin: const EdgeInsets.all(24),
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue[400]!.withValues(alpha: 0.7),
                                      Colors.purple[400]!.withValues(alpha: 0.7),
                                      Colors.pink[400]!.withValues(alpha: 0.7),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withValues(alpha: 0.3),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$year年$month月の合計',
                                  style: textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  '${monthTotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}円',
                                  style: textTheme.headlineSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  // 予算進捗バー
                  FutureBuilder<int?>(
                    future: provider.getTotalBudget(year, month),
                    builder: (context, snapshot) {
                      final budget = snapshot.data;
                      if (budget == null || budget == 0) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: ElevatedButton.icon(
                            onPressed: () => _showBudgetDialog(context, provider, year, month),
                            icon: const Icon(Icons.add_chart, size: 24.0),
                            label: const Text('予算を設定'),
                          ),
                        );
                      }
                      
                      final total = monthTotal;
                      final progress = (total / budget).clamp(0.0, 1.0);
                      final isOverBudget = total > budget;
                      // 予算額の位置を計算（バーの幅に対する割合、最大100%）
                      final budgetPosition = 1.0.clamp(0.0, 1.0);
                      
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: progress),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeInOutCubic,
                        builder: (context, animatedProgress, child) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: isOverBudget 
                                        ? colorScheme.error.withValues(alpha: 0.6)
                                        : colorScheme.outline.withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '予算進捗',
                                      style: textTheme.titleMedium?.copyWith(
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
                                      onPressed: () => _showBudgetDialog(context, provider, year, month),
                                      tooltip: '予算を編集',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${total.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}円 / ${budget.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}円',
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: isOverBudget ? colorScheme.error : colorScheme.onSurface,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (isOverBudget)
                                      Text(
                                        '超過: ${(total - budget).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}円',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.error,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Stack(
                                      children: [
                                        // 使用額の進捗バー
                                        FractionallySizedBox(
                                          widthFactor: animatedProgress.clamp(0.0, 1.0),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: isOverBudget
                                                    ? [colorScheme.error, colorScheme.errorContainer]
                                                    : [
                                                        colorScheme.primary,
                                                        colorScheme.tertiary,
                                                      ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        // 予算額のタイミングで線を表示（常に100%の位置）
                                        Positioned.fill(
                                          child: LayoutBuilder(
                                            builder: (context, constraints) {
                                              final budgetLinePosition = constraints.maxWidth * budgetPosition;
                                              return Stack(
                                                children: [
                                                  // 予算ライン（常に表示）
                                                  Positioned(
                                                    left: budgetLinePosition - 1,
                                                    top: -4,
                                                    bottom: -4,
                                                    child: Container(
                                                      width: 3,
                                                      decoration: BoxDecoration(
                                                        color: isOverBudget 
                                                            ? colorScheme.error.withValues(alpha: 0.9)
                                                            : colorScheme.primary.withValues(alpha: 0.9),
                                                        borderRadius: BorderRadius.circular(1.5),
                                                        border: Border.all(
                                                          color: Colors.white,
                                                          width: 0.5,
                                                        ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: (isOverBudget 
                                                                ? colorScheme.error 
                                                                : colorScheme.primary).withValues(alpha: 0.8),
                                                            blurRadius: 6,
                                                            spreadRadius: 2,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  // 予算超過時のラベル表示
                                                  if (isOverBudget)
                                                    Positioned(
                                                      left: budgetLinePosition + 4,
                                                      top: -16,
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: colorScheme.error,
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: Text(
                                                          '予算',
                                                          style: textTheme.bodySmall?.copyWith(
                                                            color: Colors.white,
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 10,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${(progress * 100).toStringAsFixed(1)}%',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  
                  // カード別の月別合計
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
                                      horizontal: 24,
                                      vertical: 8,
                                    ),
                                    child: ListTile(
                              leading: card.imagePath != null && File(card.imagePath!).existsSync()
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Image.file(
                                        File(card.imagePath!),
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return CircleAvatar(
                                            backgroundColor: _parseColor(card.color),
                                            radius: 20,
                                            child: const Icon(
                                              Icons.credit_card,
                                              color: Colors.white,
                                              size: 24.0,
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  : CircleAvatar(
                                      backgroundColor: _parseColor(card.color),
                                      radius: 20,
                                      child: const Icon(
                                        Icons.credit_card,
                                        color: Colors.white,
                                        size: 24.0,
                                      ),
                                    ),
                              title: Text(
                                card.name,
                                style: textTheme.titleMedium,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    card.type,
                                    style: textTheme.bodySmall,
                                  ),
                                  Text(
                                    '$year年$month月: ${cardMonthTotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}円',
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 20.0),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => CardDetailScreen(card: card),
                                          ),
                                        );
                                      },
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
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCardDialog(context),
        tooltip: 'カード追加',
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

  void _showAddCardDialog(BuildContext context) {
    final nameController = TextEditingController();
    final customNameController = TextEditingController();
    final typeController = TextEditingController();
    String selectedColor = '#FF6B6B';
    String selectedType = 'Visa';
    bool isCustomType = false;
    bool isCustomName = false;
    File? selectedImageFile;

    // 主要なクレジットカード名
    final List<String> cardNames = [
      '楽天カード',
      'PayPayカード',
      '三井住友カード',
      'JALカード',
      'UCSカード',
      'その他',
    ];

    final List<String> cardTypes = [
      'Visa',
      'Mastercard',
      'American Express',
      'JCB',
      'Diners Club',
      'Discover',
      'その他',
    ];

    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('カード追加', style: textTheme.titleLarge),
          elevation: 24.0,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 画像選択
                GestureDetector(
                  onTap: () async {
                    final source = await showDialog<ImageSource>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('画像を選択'),
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
                          ],
                        ),
                      ),
                    );
                    if (source != null) {
                      final imageFile = await ImageStorage.pickImage(source);
                      if (imageFile != null && context.mounted) {
                        setDialogState(() {
                          selectedImageFile = imageFile;
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
                        : const Icon(Icons.add_photo_alternate, size: 40),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('カード名'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: null,
                  hint: const Text('カード名を選択'),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: cardNames.map((name) {
                    return DropdownMenuItem(
                      value: name,
                      child: Text(name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        isCustomName = value == 'その他';
                        if (isCustomName) {
                          customNameController.text = '';
                          nameController.text = '';
                        } else {
                          nameController.text = value;
                        }
                      });
                    }
                  },
                ),
                if (isCustomName) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: customNameController,
                    decoration: const InputDecoration(
                      labelText: 'カード名を入力',
                      hintText: '例: その他のカード名',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Text('カード種類'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: cardTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        selectedType = value;
                        isCustomType = value == 'その他';
                        if (isCustomType) {
                          typeController.text = '';
                        } else {
                          typeController.text = value;
                        }
                      });
                    }
                  },
                ),
                if (isCustomType) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: typeController,
                    decoration: const InputDecoration(
                      labelText: 'カード種類を入力',
                      hintText: '例: その他のカード種類',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
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
              onPressed: () {
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () async {
                final cardName = isCustomName
                    ? customNameController.text.trim()
                    : nameController.text.trim();
                final type = isCustomType
                    ? typeController.text.trim()
                    : selectedType;
                if (cardName.isNotEmpty && type.isNotEmpty) {
                  final cardId = DateTime.now().millisecondsSinceEpoch.toString();
                  String? imagePath;
                  
                  // 画像が選択されている場合、保存
                  if (selectedImageFile != null) {
                    imagePath = await ImageStorage.saveImage(selectedImageFile!, cardId);
                  }
                  
                  final card = CreditCard(
                    id: cardId,
                    name: cardName,
                    type: type,
                    color: selectedColor,
                    imagePath: imagePath,
                  );
                  if (!context.mounted) return;
                  await context.read<CardProvider>().addCard(card);
                  if (context.mounted) {
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

  void _showBudgetDialog(BuildContext context, CardProvider provider, int year, int month) async {
    final currentBudget = await provider.getTotalBudget(year, month);
    if (!context.mounted) return;
    
    final budgetController = TextEditingController(
      text: currentBudget?.toString() ?? '',
    );
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$year年$month月の予算設定', style: textTheme.titleLarge),
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
                await provider.setTotalBudget(year, month, 0);
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
                  await provider.setTotalBudget(year, month, budget);
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


