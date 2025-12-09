import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../domain/card_model.dart';
import '../../application/card_provider.dart';
import '../../infrastructure/image_storage.dart';
import '../constants/card_constants.dart';
import '../widgets/color_picker.dart';
import '../screens/card_detail_screen.dart';
import '../../../../shared/widgets/native_dialog.dart';
import 'package:creditcarddiary/shared/widgets/loading_overlay.dart';

/// カード追加ダイアログを表示
Future<void> showAddCardDialog(
  BuildContext context, {
  required Function(CreditCard) onCardAdded,
}) async {
  final parentContext = context;
  final nameController = TextEditingController();
  final customNameController = TextEditingController();
  final typeController = TextEditingController();
  String selectedColor = CardConstants.defaultCardColor;
  String selectedType = CardConstants.defaultCardType;
  bool isCustomType = false;
  bool isCustomName = false;
  File? selectedImageFile;
  bool isLoading = false;
  int? selectedClosingDay;
  int? selectedPaymentDay;

  await showModalBottomSheet(
    context: parentContext,
    isScrollControlled: true,
    backgroundColor: Theme.of(parentContext).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder:
        (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final theme = Theme.of(dialogContext);
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
                              margin: const EdgeInsets.only(top: 12, bottom: 8),
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
                                  'カード追加',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(CupertinoIcons.xmark),
                                  onPressed: () => Navigator.pop(dialogContext),
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
                                // Image Picker
                                Center(
                                  child: CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    onPressed: () async {
                                      final source = await showModalBottomSheet<
                                        ImageSource
                                      >(
                                        context: dialogContext,
                                        builder:
                                            (
                                              sourceDialogContext,
                                            ) => CupertinoActionSheet(
                                              actions: [
                                                CupertinoActionSheetAction(
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        sourceDialogContext,
                                                        ImageSource.camera,
                                                      ),
                                                  child: const Text('カメラで撮影'),
                                                ),
                                                CupertinoActionSheetAction(
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        sourceDialogContext,
                                                        ImageSource.gallery,
                                                      ),
                                                  child: const Text(
                                                    'ギャラリーから選択',
                                                  ),
                                                ),
                                              ],
                                              cancelButton:
                                                  CupertinoActionSheetAction(
                                                    onPressed:
                                                        () => Navigator.pop(
                                                          sourceDialogContext,
                                                        ),
                                                    child: const Text('キャンセル'),
                                                  ),
                                            ),
                                      );
                                      if (source != null) {
                                        final imageFile =
                                            await ImageStorage.pickImage(
                                              source,
                                            );
                                        if (imageFile != null &&
                                            dialogContext.mounted) {
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
                                        color:
                                            theme
                                                .colorScheme
                                                .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: theme.colorScheme.outline
                                              .withValues(alpha: 0.2),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.05,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child:
                                          selectedImageFile != null
                                              ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                child: Image.file(
                                                  selectedImageFile!,
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                              : Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    CupertinoIcons.camera,
                                                    size: 32,
                                                    color:
                                                        theme
                                                            .colorScheme
                                                            .onSurface,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '画像を設定',
                                                    style: theme
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color:
                                                              theme
                                                                  .colorScheme
                                                                  .onSurface,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // Card Name
                                Text(
                                  'カード名',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                CupertinoListTile(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  title: Text(
                                    isCustomName || nameController.text.isEmpty
                                        ? (isCustomName ? 'その他' : 'カード名を選択')
                                        : nameController.text,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color:
                                          nameController.text.isEmpty &&
                                                  !isCustomName
                                              ? theme.hintColor
                                              : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  trailing: const Icon(
                                    CupertinoIcons.chevron_right,
                                    size: 20,
                                  ),
                                  backgroundColor: theme.colorScheme.surface,
                                  onTap: () async {
                                    final selected = await _showItemPicker(
                                      dialogContext,
                                      items: CardConstants.cardNames,
                                      initialItem:
                                          isCustomName
                                              ? 'その他'
                                              : (nameController.text.isEmpty
                                                  ? CardConstants
                                                      .cardNames
                                                      .first
                                                  : nameController.text),
                                      title: 'カード名を選択',
                                    );
                                    if (selected != null) {
                                      setDialogState(() {
                                        isCustomName = selected == 'その他';
                                        if (isCustomName) {
                                          customNameController.text = '';
                                          nameController.text = '';
                                        } else {
                                          nameController.text = selected;
                                        }
                                      });
                                    }
                                  },
                                ),
                                if (isCustomName) ...[
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: customNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'カード名を入力',
                                      hintText: '例: その他のカード名',
                                      counterText: '',
                                    ),
                                    maxLength: 20,
                                  ),
                                ],

                                const SizedBox(height: 24),

                                // Card Type
                                Text(
                                  'カード種類',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                CupertinoListTile(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  title: Text(
                                    isCustomType || selectedType.isEmpty
                                        ? (isCustomType ? 'その他' : 'カード種類を選択')
                                        : selectedType,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color:
                                          selectedType.isEmpty && !isCustomType
                                              ? theme.hintColor
                                              : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  trailing: const Icon(
                                    CupertinoIcons.chevron_right,
                                    size: 20,
                                  ),
                                  backgroundColor: theme.colorScheme.surface,
                                  onTap: () async {
                                    final selected = await _showItemPicker(
                                      dialogContext,
                                      items: CardConstants.cardTypes,
                                      initialItem:
                                          isCustomType
                                              ? 'その他'
                                              : (selectedType.isEmpty
                                                  ? CardConstants
                                                      .cardTypes
                                                      .first
                                                  : selectedType),
                                      title: 'カード種類を選択',
                                    );
                                    if (selected != null) {
                                      setDialogState(() {
                                        selectedType = selected;
                                        isCustomType = selected == 'その他';
                                        if (isCustomType) {
                                          typeController.text = '';
                                        } else {
                                          typeController.text = selected;
                                        }
                                      });
                                    }
                                  },
                                ),
                                if (isCustomType) ...[
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: typeController,
                                    decoration: const InputDecoration(
                                      labelText: 'カード種類を入力',
                                      hintText: '例: その他のカード種類',
                                      counterText: '',
                                    ),
                                    maxLength: 20,
                                  ),
                                ],

                                const SizedBox(height: 24),

                                // Color Picker
                                Text(
                                  'テーマカラー',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ColorPicker(
                                  selectedColor: selectedColor,
                                  onColorSelected: (color) {
                                    setDialogState(() {
                                      selectedColor = color;
                                    });
                                  },
                                ),
                                const SizedBox(height: 24),

                                // Payment Info (Optional)
                                Text(
                                  '支払日・締め日 (任意)',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CupertinoListTile(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                        title: Text(
                                          selectedClosingDay != null
                                              ? '$selectedClosingDay日締め'
                                              : '締め日',
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                                color:
                                                    selectedClosingDay == null
                                                        ? theme.hintColor
                                                        : theme
                                                            .colorScheme
                                                            .onSurface,
                                              ),
                                        ),
                                        backgroundColor:
                                            theme.colorScheme.surface,
                                        onTap: () async {
                                          final day = await _showDayPicker(
                                            dialogContext,
                                            initialDay: selectedClosingDay,
                                            title: '締め日を選択',
                                          );
                                          if (day != null) {
                                            setDialogState(() {
                                              selectedClosingDay = day;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: CupertinoListTile(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                        title: Text(
                                          selectedPaymentDay != null
                                              ? '$selectedPaymentDay日払い'
                                              : '支払日',
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                                color:
                                                    selectedPaymentDay == null
                                                        ? theme.hintColor
                                                        : theme
                                                            .colorScheme
                                                            .onSurface,
                                              ),
                                        ),
                                        backgroundColor:
                                            theme.colorScheme.surface,
                                        onTap: () async {
                                          final day = await _showDayPicker(
                                            dialogContext,
                                            initialDay: selectedPaymentDay,
                                            title: '支払日を選択',
                                          );
                                          if (day != null) {
                                            setDialogState(() {
                                              selectedPaymentDay = day;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                          // Bottom Button
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: CupertinoButton.filled(
                                onPressed: () async {
                                  if (isLoading) return;
                                  HapticFeedback.lightImpact();
                                  final cardName =
                                      isCustomName
                                          ? customNameController.text.trim()
                                          : nameController.text.trim();
                                  final type =
                                      isCustomType
                                          ? typeController.text.trim()
                                          : selectedType;
                                  if (cardName.isNotEmpty && type.isNotEmpty) {
                                    setDialogState(() {
                                      isLoading = true;
                                    });
                                    try {
                                      final cardId =
                                          DateTime.now().millisecondsSinceEpoch
                                              .toString();
                                      String? imagePath;

                                      if (selectedImageFile != null) {
                                        imagePath =
                                            await ImageStorage.saveImage(
                                              selectedImageFile!,
                                              cardId,
                                            );
                                      }

                                      final card = CreditCard(
                                        id: cardId,
                                        name: cardName,
                                        type: type,
                                        color: selectedColor,
                                        imagePath: imagePath,
                                        closingDay: selectedClosingDay,
                                        paymentDay: selectedPaymentDay,
                                      );
                                      if (!parentContext.mounted) return;
                                      await parentContext
                                          .read<CardProvider>()
                                          .addCard(card);
                                      if (!parentContext.mounted) return;

                                      Navigator.pop(dialogContext);

                                      // Confirmation Dialog
                                      await Future.delayed(
                                        const Duration(milliseconds: 300),
                                      );
                                      if (!parentContext.mounted) return;

                                      final addExpense =
                                          await showCupertinoDialog<bool>(
                                            context: parentContext,
                                            builder:
                                                (
                                                  confirmDialogContext,
                                                ) => CupertinoAlertDialog(
                                                  title: Text(
                                                    '${card.name}を追加しました',
                                                    style:
                                                        theme
                                                            .textTheme
                                                            .titleLarge,
                                                  ),
                                                  content: const Text(
                                                    '支出を追加しますか？',
                                                  ),
                                                  actions: [
                                                    CupertinoDialogAction(
                                                      onPressed:
                                                          () => Navigator.pop(
                                                            confirmDialogContext,
                                                            false,
                                                          ),
                                                      child: const Text('いいえ'),
                                                    ),
                                                    CupertinoDialogAction(
                                                      isDefaultAction: true,
                                                      onPressed:
                                                          () => Navigator.pop(
                                                            confirmDialogContext,
                                                            true,
                                                          ),
                                                      child: const Text('はい'),
                                                    ),
                                                  ],
                                                ),
                                          );

                                      if (addExpense == true &&
                                          parentContext.mounted) {
                                        Navigator.push(
                                          parentContext,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => CardDetailScreen(
                                                  card: card,
                                                  autoOpenAddTransactionDialog:
                                                      true,
                                                ),
                                          ),
                                        );
                                      }

                                      onCardAdded(card);
                                    } finally {
                                      if (dialogContext.mounted) {
                                        setDialogState(() {
                                          isLoading = false;
                                        });
                                      }
                                    }
                                  } else {
                                    showNativeErrorDialog(
                                      dialogContext,
                                      'カード名と種類を入力してください',
                                    );
                                  }
                                },
                                child: const Text(
                                  'カードを追加',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
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

Future<String?> _showItemPicker(
  BuildContext context, {
  required List<String> items,
  required String initialItem,
  required String title,
}) async {
  final theme = Theme.of(context);
  int selectedIndex = items.indexOf(initialItem);
  if (selectedIndex < 0) selectedIndex = 0;

  return await showModalBottomSheet<String?>(
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
                  children:
                      items.map((item) {
                        return Center(
                          child: Text(
                            item,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    onPressed: () {
                      Navigator.pop(context, items[selectedIndex]);
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

Future<int?> _showDayPicker(
  BuildContext context, {
  required int? initialDay,
  required String title,
}) async {
  final theme = Theme.of(context);
  int selectedIndex = (initialDay ?? 1) - 1;

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
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
