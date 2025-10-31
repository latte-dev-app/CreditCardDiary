import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../application/card_provider.dart';
import '../../domain/card_model.dart';
import '../../infrastructure/image_storage.dart';
import 'card_detail_screen.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CardProvider>().init();
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
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                '$year年$month月',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: _nextMonth,
            tooltip: '次の月',
          ),
        ],
      ),
      body: Consumer<CardProvider>(
        builder: (context, provider, _) {
          final useBillingMonth = provider.useBillingMonth;
          final monthTotal = useBillingMonth
              ? provider.getBillingTotalByMonth(year, month)
              : provider.getTotalByMonth(year, month);
          final monthTransactions = useBillingMonth
              ? provider.getTransactionsByBillingMonth(year, month)
              : provider.getTransactionsByMonth(year, month);
              
              return Column(
                children: [
                  // 集計モード切替トグル
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text('請求月ベース'),
                        Switch(
                          value: useBillingMonth,
                          onChanged: (_) => provider.toggleAggregationMode(),
                        ),
                      ],
                    ),
                  ),
                  // 月別サマリー
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[400]!, Colors.purple[400]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          useBillingMonth ? '$year年$month月の請求額' : '$year年$month月の合計',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '${monthTotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}円',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
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
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'カードが登録されていません',
                              style: TextStyle(color: Colors.grey[600]),
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
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
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
                                            child: const Icon(
                                              Icons.credit_card,
                                              color: Colors.white,
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  : CircleAvatar(
                                      backgroundColor: _parseColor(card.color),
                                      child: const Icon(
                                        Icons.credit_card,
                                        color: Colors.white,
                                      ),
                                    ),
                              title: Text(card.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(card.type),
                                  Text(
                                    '$year年$month月: ${cardMonthTotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}円',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CardDetailScreen(card: card),
                                  ),
                                );
                              },
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

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('カード追加'),
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
              onPressed: () => Navigator.pop(context),
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
}

