import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../domain/card_model.dart';
import '../../application/card_provider.dart';
import '../../infrastructure/image_storage.dart';
import '../constants/card_constants.dart';
import '../widgets/color_picker.dart';
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

  final theme = Theme.of(parentContext);
  final textTheme = theme.textTheme;

  await showDialog(
    context: parentContext,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
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
                    context: dialogContext,
                    builder: (sourceDialogContext) => AlertDialog(
                      title: const Text('画像を選択'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.camera_alt),
                            title: const Text('カメラで撮影'),
                            onTap: () =>
                                Navigator.pop(sourceDialogContext, ImageSource.camera),
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo_library),
                            title: const Text('ギャラリーから選択'),
                            onTap: () => Navigator.pop(
                                sourceDialogContext, ImageSource.gallery),
                          ),
                        ],
                      ),
                    ),
                  );
                  if (source != null) {
                    final imageFile = await ImageStorage.pickImage(source);
                    if (imageFile != null && dialogContext.mounted) {
                      setDialogState(() {
                        selectedImageFile = imageFile;
                      });
                    }
                  }
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: selectedImageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(selectedImageFile!, fit: BoxFit.cover),
                        )
                      : const Icon(Icons.add_photo_alternate, size: 32),
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
                items: CardConstants.cardNames.map((name) {
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
                items: CardConstants.cardTypes.map((type) {
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
              ColorPicker(
                selectedColor: selectedColor,
                onColorSelected: (color) {
                  setDialogState(() {
                    selectedColor = color;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
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
                if (!parentContext.mounted) return;
                await parentContext.read<CardProvider>().addCard(card);
                if (!parentContext.mounted) return;

                // カード追加ダイアログを閉じる
                Navigator.pop(dialogContext);

                // 確認ダイアログを表示（少し待ってから）
                await Future.delayed(const Duration(milliseconds: 300));
                if (!parentContext.mounted) return;

                final addExpense = await showDialog<bool>(
                  context: parentContext,
                  builder: (confirmDialogContext) => AlertDialog(
                    title: Text('${card.name}を追加しました', style: textTheme.titleLarge),
                    content: const Text('支出を追加しますか？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(confirmDialogContext, false),
                        child: const Text('いいえ'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(confirmDialogContext, true),
                        child: const Text('はい'),
                      ),
                    ],
                  ),
                );

                // 「はい」が選択された場合、カード詳細画面に遷移（支出追加ダイアログを自動表示）
                if (addExpense == true && parentContext.mounted) {
                  Navigator.push(
                    parentContext,
                    MaterialPageRoute(
                      builder: (_) => CardDetailScreen(
                        card: card,
                        autoOpenAddTransactionDialog: true,
                      ),
                    ),
                  );
                }

                // コールバックを呼び出し
                onCardAdded(card);
              }
            },
            child: const Text('追加'),
          ),
        ],
      ),
    ),
  );
}

