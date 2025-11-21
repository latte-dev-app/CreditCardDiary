import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../domain/card_model.dart';
import '../../application/card_provider.dart';
import '../../infrastructure/image_storage.dart';
import '../constants/card_constants.dart';
import '../widgets/color_picker.dart';
import '../widgets/glass_modal.dart';
import '../screens/card_detail_screen.dart';

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

  await showModalBottomSheet(
    context: parentContext,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder:
        (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final theme = Theme.of(dialogContext);
            return GlassModal(
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
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.close),
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
                                  child: GestureDetector(
                                    onTap: () async {
                                      final source = await showModalBottomSheet<
                                        ImageSource
                                      >(
                                        context: dialogContext,
                                        builder:
                                            (sourceDialogContext) => SafeArea(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  ListTile(
                                                    leading: const Icon(
                                                      Icons.camera_alt,
                                                    ),
                                                    title: const Text('カメラで撮影'),
                                                    onTap:
                                                        () => Navigator.pop(
                                                          sourceDialogContext,
                                                          ImageSource.camera,
                                                        ),
                                                  ),
                                                  ListTile(
                                                    leading: const Icon(
                                                      Icons.photo_library,
                                                    ),
                                                    title: const Text(
                                                      'ギャラリーから選択',
                                                    ),
                                                    onTap:
                                                        () => Navigator.pop(
                                                          sourceDialogContext,
                                                          ImageSource.gallery,
                                                        ),
                                                  ),
                                                ],
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
                                                    Icons
                                                        .add_photo_alternate_outlined,
                                                    size: 32,
                                                    color:
                                                        theme
                                                            .colorScheme
                                                            .primary,
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
                                                                  .primary,
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
                                DropdownButtonFormField<String>(
                                  value: null,
                                  hint: const Text('カード名を選択'),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: theme
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withValues(alpha: 0.5),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  items:
                                      CardConstants.cardNames.map((name) {
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
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: customNameController,
                                    decoration: InputDecoration(
                                      labelText: 'カード名を入力',
                                      hintText: '例: その他のカード名',
                                      filled: true,
                                      fillColor: theme
                                          .colorScheme
                                          .surfaceContainerHighest
                                          .withValues(alpha: 0.5),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
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
                                DropdownButtonFormField<String>(
                                  value: selectedType,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: theme
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withValues(alpha: 0.5),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  items:
                                      CardConstants.cardTypes.map((type) {
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
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: typeController,
                                    decoration: InputDecoration(
                                      labelText: 'カード種類を入力',
                                      hintText: '例: その他のカード種類',
                                      filled: true,
                                      fillColor: theme
                                          .colorScheme
                                          .surfaceContainerHighest
                                          .withValues(alpha: 0.5),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
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
                              child: FilledButton(
                                onPressed: () async {
                                  final cardName =
                                      isCustomName
                                          ? customNameController.text.trim()
                                          : nameController.text.trim();
                                  final type =
                                      isCustomType
                                          ? typeController.text.trim()
                                          : selectedType;
                                  if (cardName.isNotEmpty && type.isNotEmpty) {
                                    final cardId =
                                        DateTime.now().millisecondsSinceEpoch
                                            .toString();
                                    String? imagePath;

                                    if (selectedImageFile != null) {
                                      imagePath = await ImageStorage.saveImage(
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

                                    final addExpense = await showDialog<bool>(
                                      context: parentContext,
                                      builder:
                                          (confirmDialogContext) => AlertDialog(
                                            title: Text(
                                              '${card.name}を追加しました',
                                              style: theme.textTheme.titleLarge,
                                            ),
                                            content: const Text('支出を追加しますか？'),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      confirmDialogContext,
                                                      false,
                                                    ),
                                                child: const Text('いいえ'),
                                              ),
                                              FilledButton(
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
                                  }
                                },
                                style: FilledButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
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
