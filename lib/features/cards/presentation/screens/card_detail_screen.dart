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
              icon: Icon(Icons.add_circle, color: theme.colorScheme.primary),
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
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(
                      Icons.settings_outlined,
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
                                                            Icons.credit_card,
                                                            color: Colors.white,
                                                            size: 32,
                                                          ),
                                                ),
                                              )
                                              : const Icon(
                                                Icons.credit_card,
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
                                              ? Icons.warning_rounded
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
                                    Icons.receipt_long_rounded,
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
                      child: const Icon(Icons.delete, color: Colors.white),
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
                                  Icons.edit_outlined,
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
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Icon(Icons.edit, color: theme.colorScheme.onSurface),
                  title: Text('カード情報を編集', style: theme.textTheme.bodyLarge),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditCardDialog(context, card);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.calendar_today,
                    color: theme.colorScheme.onSurface,
                  ),
                  title: Text('締め日・支払日設定', style: theme.textTheme.bodyLarge),
                  onTap: () {
                    Navigator.pop(context);
                    _showDateSettingsDialog(context);
                  },
                ),

                ListTile(
                  leading: Icon(Icons.delete, color: theme.colorScheme.error),
                  title: Text(
                    'カードを削除',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(context);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }

  void _showEditCardDialog(BuildContext context, CreditCard card) async {
    final theme = Theme.of(context);
    final nameController = TextEditingController(text: card.name);
    final typeController = TextEditingController(text: card.type);
    String selectedColor = card.color;
    String? currentImagePath = card.imagePath;
    File? selectedImageFile;

    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text(
                    'カード編集',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                                    ? const Icon(Icons.add_a_photo)
                                    : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: 'カード名',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: typeController,
                          decoration: InputDecoration(
                            labelText: 'カード種類',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('キャンセル'),
                    ),
                    FilledButton(
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

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '締め日・支払日設定',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
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
                          const Icon(Icons.chevron_right),
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
                          // Handle case where day is 0 (Not Set) - copyWith handles null if we pass null?
                          // My logic below returns 0 for "Not Set".
                          // Need to check copyWith logic or pass null.
                          // Let's assume _showDayPicker returns null for "Not Set".

                          await context.read<CardProvider>().updateCard(
                            updatedCard,
                          );
                          setState(() {
                            // Update local card state
                            // But we also need to update the parent widget's card state
                            // The parent (CardDetailScreen) listens to provider?
                            // No, it has local state 'card'.
                            // We need to update that too.
                            // But this setState only updates the BottomSheet.
                            // We need to call the parent's setState.
                            // However, we can't easily access parent's setState here.
                            // But we can update the 'card' variable of the State class.
                            card = updatedCard;
                          });
                          // Force parent rebuild
                          setState(() {});
                        }
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
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
                          const Icon(Icons.chevron_right),
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
                          setState(() {});
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
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

    // Items: 0 -> "未設定", 1..31 -> "1日".."31日"

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
                  title,
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          selectedIndex == 0 ? null : selectedIndex,
                        );
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

  void _showDeleteConfirmation(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'カード削除',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text('このカードと全ての支出記録を削除しますか？'),
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

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text(
                    '支出追加',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: selectedYear,
                              items:
                                  years
                                      .map(
                                        (y) => DropdownMenuItem(
                                          value: y,
                                          child: Text('$y年'),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (v) =>
                                      setDialogState(() => selectedYear = v!),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: selectedMonth,
                              items:
                                  months
                                      .map(
                                        (m) => DropdownMenuItem(
                                          value: m,
                                          child: Text('$m月'),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (v) =>
                                      setDialogState(() => selectedMonth = v!),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
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
                          NumberTextInputFormatter(),
                        ],
                        decoration: InputDecoration(
                          labelText: '金額',
                          suffixText: '円',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        autofocus: true,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'メモ (任意)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('キャンセル'),
                    ),
                    FilledButton(
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
    final theme = Theme.of(context);
    final amountController = TextEditingController(
      text: NumberFormat('#,###').format(transaction.amount),
    );
    final titleController = TextEditingController(text: transaction.title);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              '支出編集',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    NumberTextInputFormatter(),
                  ],
                  decoration: InputDecoration(
                    labelText: '金額',
                    suffixText: '円',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'メモ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
              FilledButton(
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
