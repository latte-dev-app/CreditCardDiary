import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../domain/card_model.dart';
import '../../application/card_provider.dart';
import '../../infrastructure/image_storage.dart';
import '../widgets/number_input_formatter.dart';
import '../../domain/logic/payment_logic.dart';
import '../../../../shared/widgets/native_dialog.dart';
import '../../../../shared/widgets/native_touchable.dart';
import '../../../../shared/utils/color_utils.dart';
import '../widgets/color_picker.dart';

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
      bottomNavigationBar: BottomAppBar(
        color: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              onPressed: () => _showAddTransactionDialog(context),
              icon: Icon(
                CupertinoIcons.add_circled_solid,
                color: theme.colorScheme.primary,
              ),
              iconSize: 32,
              tooltip: '支出記録',
            ),
          ],
        ),
      ),
      body: Consumer<CardProvider>(
        builder: (context, provider, _) {
          final transactions = provider.getTransactionsByCardId(card.id);
          final monthlyTotal = provider.getMonthlyTotalByCardId(card.id);
          final sortedMonths =
              monthlyTotal.keys.toList()
                ..sort((a, b) => b.compareTo(a)); // Descending

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverAppBar(
                expandedHeight: 200.0,
                floating: false,
                pinned: true,
                backgroundColor: theme.scaffoldBackgroundColor,
                surfaceTintColor: Colors.transparent,
                shape: const Border(), // Remove default AppBar border
                leading: IconButton(
                  icon: const Icon(CupertinoIcons.back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(
                      CupertinoIcons.settings,
                      color: Colors.white,
                    ),
                    onPressed: () => _showCardSettings(context),
                    tooltip: 'カード設定',
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                    child: Stack(
                      children: [
                        // Base Gradient
                        Hero(
                          tag: 'card_hero_${card.id}',
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  ColorUtils.fromHex(card.color),
                                  ColorUtils.fromHex(
                                    card.color,
                                  ).withValues(alpha: 0.8),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Decorative Blobs
                        Positioned(
                          top: -50,
                          right: -50,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -30,
                          left: -30,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        // Glass Effect
                        BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        // Card Content
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.5,
                                          ),
                                          width: 2,
                                        ),
                                      ),
                                      child:
                                          card.imagePath != null
                                              ? ClipOval(
                                                child: Image.file(
                                                  File(card.imagePath!),
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (_, __, ___) =>
                                                          const Icon(
                                                            CupertinoIcons
                                                                .creditcard,
                                                            color: Colors.white,
                                                            size: 32,
                                                          ),
                                                ),
                                              )
                                              : const Icon(
                                                CupertinoIcons.creditcard,
                                                color: Colors.white,
                                                size: 32,
                                              ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            card.name,
                                            style: theme.textTheme.headlineSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      ColorUtils.getTextColorForBackground(
                                                        ColorUtils.fromHex(
                                                          card.color,
                                                        ),
                                                      ),
                                                ),
                                          ),
                                          Text(
                                            card.type,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color:
                                                      ColorUtils.getTextColorForBackground(
                                                        ColorUtils.fromHex(
                                                          card.color,
                                                        ),
                                                      ).withValues(alpha: 0.8),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildInfoItem(
                                      theme,
                                      '締め日',
                                      card.closingDay != null
                                          ? '${card.closingDay}日'
                                          : '未設定',
                                      textColor:
                                          ColorUtils.getTextColorForBackground(
                                            ColorUtils.fromHex(card.color),
                                          ),
                                    ),
                                    _buildInfoItem(
                                      theme,
                                      '支払日',
                                      card.paymentDay != null
                                          ? '${card.paymentDay}日'
                                          : '未設定',
                                      valueColor:
                                          PaymentLogic.isPaymentDayApproaching(
                                                card.paymentDay,
                                              )
                                              ? theme.colorScheme.error
                                              : null,
                                      icon:
                                          PaymentLogic.isPaymentDayApproaching(
                                                card.paymentDay,
                                              )
                                              ? CupertinoIcons
                                                  .exclamationmark_circle_fill
                                              : null,
                                      textColor:
                                          ColorUtils.getTextColorForBackground(
                                            ColorUtils.fromHex(card.color),
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver:
                    transactions.isEmpty
                        ? SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                children: [
                                  Icon(
                                    CupertinoIcons.doc_text,
                                    size: 64,
                                    color: theme.colorScheme.outline,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    '利用履歴がありません',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        : SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final monthKey = sortedMonths[index];
                            final amount = monthlyTotal[monthKey]!;
                            final monthTransactions =
                                transactions
                                    .where(
                                      (t) =>
                                          '${t.year}-${t.month.toString().padLeft(2, '0')}' ==
                                          monthKey,
                                    )
                                    .toList();

                            return _buildMonthSection(
                              context,
                              theme,
                              monthKey,
                              amount,
                              monthTransactions,
                              currencyFormat,
                            );
                          }, childCount: sortedMonths.length),
                        ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoItem(
    ThemeData theme,
    String label,
    String value, {
    Color? valueColor,
    IconData? icon,
    Color textColor = Colors.white,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: textColor.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: valueColor, size: 18),
              const SizedBox(width: 4),
            ],
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor ?? textColor,
              ),
            ),
          ],
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
          padding: const EdgeInsets.fromLTRB(8, 24, 8, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$year年$month月',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outline),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children:
                transactions.map((transaction) {
                  return Dismissible(
                    key: ValueKey(transaction.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: theme.colorScheme.error,
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
                              title: const Text('支出の削除'),
                              content: Text(
                                '「${transaction.title.isEmpty ? '支出' : transaction.title}」を削除しますか？',
                              ),
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
                      context.read<CardProvider>().deleteTransaction(
                        transaction.id,
                      );
                    },
                    child: Column(
                      children: [
                        NativeTouchable(
                          onTap:
                              () => _showEditTransactionDialog(
                                context,
                                transaction,
                              ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        currencyFormat.format(
                                          transaction.amount,
                                        ),
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                      ),
                                      if (transaction.title.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          transaction.title,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color:
                                                    theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Icon(
                                  CupertinoIcons.pencil,
                                  size: 24,
                                  color: theme.colorScheme.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (transaction != transactions.last)
                          Divider(
                            height: 1,
                            indent: 20,
                            endIndent: 20,
                            color: theme.colorScheme.outlineVariant,
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
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
            title: const Text('カード設定'),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  _showEditCardDialog(context, card);
                },
                child: const Text('カード情報を編集'),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  _showDateSettingsDialog(context);
                },
                child: const Text('締め日・支払日設定'),
              ),
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context);
                },
                child: const Text('カードを削除'),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
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

    await showCupertinoDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => CupertinoAlertDialog(
                  title: const Text('カード編集'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () async {
                            final picker = ImagePicker();
                            final image = await picker.pickImage(
                              source: ImageSource.gallery,
                            );
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
                            backgroundImage:
                                selectedImageFile != null
                                    ? FileImage(selectedImageFile!)
                                    : (currentImagePath != null
                                            ? FileImage(File(currentImagePath!))
                                            : null)
                                        as ImageProvider?,
                            child:
                                (selectedImageFile == null &&
                                        currentImagePath == null)
                                    ? const Icon(CupertinoIcons.camera)
                                    : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        CupertinoTextField(
                          controller: nameController,
                          placeholder: 'カード名',
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemBackground,
                            border: Border.all(
                              color: CupertinoColors.systemGrey4,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        CupertinoTextField(
                          controller: typeController,
                          placeholder: 'カード種類',
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemBackground,
                            border: Border.all(
                              color: CupertinoColors.systemGrey4,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ColorPicker(
                          selectedColor: selectedColor,
                          onColorSelected: (color) {
                            setDialogState(() => selectedColor = color);
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    CupertinoDialogAction(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('キャンセル'),
                    ),
                    CupertinoDialogAction(
                      isDefaultAction: true,
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        if (nameController.text.isNotEmpty) {
                          String? imagePath = currentImagePath;
                          if (selectedImageFile != null) {
                            imagePath = await ImageStorage.saveImage(
                              selectedImageFile!,
                              card.id,
                            );
                          }

                          final updatedCard = card.copyWith(
                            name: nameController.text,
                            type: typeController.text,
                            color: selectedColor,
                            imagePath: imagePath,
                          );
                          if (context.mounted) {
                            await context.read<CardProvider>().updateCard(
                              updatedCard,
                            );
                            setState(() => this.card = updatedCard);
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          }
                        } else {
                          showNativeErrorDialog(context, 'カード名を入力してください');
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
    final theme = Theme.of(context);

    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => Container(
            color: theme.scaffoldBackgroundColor,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      '締め日・支払日設定',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  CupertinoListTile(
                    title: const Text('締め日'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          card.closingDay != null
                              ? '${card.closingDay}日'
                              : '未設定',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(CupertinoIcons.chevron_right, size: 20),
                      ],
                    ),
                    onTap: () async {
                      final day = await _showDayPicker(
                        context,
                        initialDay: card.closingDay,
                        title: '締め日を選択',
                      );
                      if (context.mounted) {
                        final updatedCard = card.copyWith(closingDay: day);
                        await context.read<CardProvider>().updateCard(
                          updatedCard,
                        );
                        setState(() {
                          card = updatedCard;
                        });
                      }
                    },
                  ),
                  const Divider(height: 1),
                  CupertinoListTile(
                    title: const Text('支払日'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          card.paymentDay != null
                              ? '${card.paymentDay}日'
                              : '未設定',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(CupertinoIcons.chevron_right, size: 20),
                      ],
                    ),
                    onTap: () async {
                      final day = await _showDayPicker(
                        context,
                        initialDay: card.paymentDay,
                        title: '支払日を選択',
                      );
                      if (context.mounted) {
                        final updatedCard = card.copyWith(paymentDay: day);
                        await context.read<CardProvider>().updateCard(
                          updatedCard,
                        );
                        setState(() {
                          card = updatedCard;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: CupertinoButton.filled(
                        child: const Text('閉じる'),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
    );
  }

  Future<int?> _showDayPicker(
    BuildContext context, {
    required int? initialDay,
    required String title,
  }) async {
    final theme = Theme.of(context);
    int selectedIndex = initialDay ?? 0; // 0 represents "Not Set"

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
                        Navigator.pop(
                          context,
                          selectedIndex == 0 ? null : selectedIndex,
                        );
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
                    children: [
                      Center(
                        child: Text(
                          '未設定',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ),
                      ...List.generate(31, (index) {
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
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('カード削除'),
            content: const Text('このカードと全ての支出記録を削除しますか？'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
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
    final theme = Theme.of(context);
    final amountController = TextEditingController();
    final titleController = TextEditingController();
    int selectedYear = DateTime.now().year;
    int selectedMonth = DateTime.now().month;
    final years = List.generate(10, (index) => DateTime.now().year - 5 + index);
    final months = List.generate(12, (index) => index + 1);

    showCupertinoDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => CupertinoAlertDialog(
                  title: const Text('支出追加'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: CupertinoColors.systemGrey4,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '$selectedYear年',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    const Icon(
                                      CupertinoIcons.chevron_down,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                              onPressed: () async {
                                await showCupertinoModalPopup(
                                  context: context,
                                  builder:
                                      (context) => Container(
                                        height: 250,
                                        color: theme.scaffoldBackgroundColor,
                                        child: CupertinoPicker(
                                          itemExtent: 32,
                                          onSelectedItemChanged: (index) {
                                            setDialogState(
                                              () => selectedYear = years[index],
                                            );
                                          },
                                          scrollController:
                                              FixedExtentScrollController(
                                                initialItem: years.indexOf(
                                                  selectedYear,
                                                ),
                                              ),
                                          children:
                                              years
                                                  .map(
                                                    (y) => Center(
                                                      child: Text('$y年'),
                                                    ),
                                                  )
                                                  .toList(),
                                        ),
                                      ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: CupertinoColors.systemGrey4,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '$selectedMonth月',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    const Icon(
                                      CupertinoIcons.chevron_down,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                              onPressed: () async {
                                await showCupertinoModalPopup(
                                  context: context,
                                  builder:
                                      (context) => Container(
                                        height: 250,
                                        color: theme.scaffoldBackgroundColor,
                                        child: CupertinoPicker(
                                          itemExtent: 32,
                                          onSelectedItemChanged: (index) {
                                            setDialogState(
                                              () =>
                                                  selectedMonth = months[index],
                                            );
                                          },
                                          scrollController:
                                              FixedExtentScrollController(
                                                initialItem: months.indexOf(
                                                  selectedMonth,
                                                ),
                                              ),
                                          children:
                                              months
                                                  .map(
                                                    (m) => Center(
                                                      child: Text('$m月'),
                                                    ),
                                                  )
                                                  .toList(),
                                        ),
                                      ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CupertinoTextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          NumberTextInputFormatter(),
                        ],
                        placeholder: '金額 (円)',
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemBackground,
                          border: Border.all(
                            color: CupertinoColors.systemGrey4,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        autofocus: true,
                      ),
                      const SizedBox(height: 12),
                      CupertinoTextField(
                        controller: titleController,
                        placeholder: 'メモ (任意)',
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemBackground,
                          border: Border.all(
                            color: CupertinoColors.systemGrey4,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    CupertinoDialogAction(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('キャンセル'),
                    ),
                    CupertinoDialogAction(
                      isDefaultAction: true,
                      onPressed: () {
                        final amount = int.tryParse(
                          amountController.text.replaceAll(',', ''),
                        );
                        if (amount != null) {
                          final transaction = Transaction(
                            id:
                                DateTime.now().millisecondsSinceEpoch
                                    .toString(),
                            cardId: card.id,
                            amount: amount,
                            year: selectedYear,
                            month: selectedMonth,
                            title: titleController.text,
                          );
                          context.read<CardProvider>().addTransaction(
                            transaction,
                          );
                          Navigator.pop(context);
                        } else {
                          showNativeErrorDialog(context, '金額を入力してください');
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
    BuildContext context,
    Transaction transaction,
  ) {
    final amountController = TextEditingController(
      text: NumberFormat('#,###').format(transaction.amount),
    );
    final titleController = TextEditingController(text: transaction.title);

    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('支出編集'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                CupertinoTextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    NumberTextInputFormatter(),
                  ],
                  placeholder: '金額 (円)',
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground,
                    border: Border.all(color: CupertinoColors.systemGrey4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 12),
                CupertinoTextField(
                  controller: titleController,
                  placeholder: 'メモ',
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground,
                    border: Border.all(color: CupertinoColors.systemGrey4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () {
                  final amount = int.tryParse(
                    amountController.text.replaceAll(',', ''),
                  );
                  if (amount != null) {
                    final updatedTransaction = transaction.copyWith(
                      amount: amount,
                      title: titleController.text,
                    );
                    context.read<CardProvider>().updateTransaction(
                      updatedTransaction,
                    );
                    Navigator.pop(context);
                  } else {
                    showNativeErrorDialog(context, '金額を入力してください');
                  }
                },
                child: const Text('保存'),
              ),
            ],
          ),
    );
  }
}
