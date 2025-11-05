import 'package:flutter/material.dart';
import '../constants/card_constants.dart';

/// カラー選択ウィジェット
class ColorPicker extends StatelessWidget {
  final String selectedColor;
  final ValueChanged<String> onColorSelected;

  const ColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    // 選択された色がどのカテゴリに属するか確認
    String initialCategory = CardConstants.colorPalettes.keys.first;
    for (var entry in CardConstants.colorPalettes.entries) {
      if (entry.value.contains(selectedColor)) {
        initialCategory = entry.key;
        break;
      }
    }

    return _ColorPickerStateful(
      selectedColor: selectedColor,
      initialCategory: initialCategory,
      onColorSelected: onColorSelected,
    );
  }
}

class _ColorPickerStateful extends StatefulWidget {
  final String selectedColor;
  final String initialCategory;
  final ValueChanged<String> onColorSelected;

  const _ColorPickerStateful({
    required this.selectedColor,
    required this.initialCategory,
    required this.onColorSelected,
  });

  @override
  State<_ColorPickerStateful> createState() => _ColorPickerStatefulState();
}

class _ColorPickerStatefulState extends State<_ColorPickerStateful> {
  late final ValueNotifier<String> currentCategoryNotifier;

  @override
  void initState() {
    super.initState();
    currentCategoryNotifier = ValueNotifier<String>(widget.initialCategory);
  }

  @override
  void dispose() {
    currentCategoryNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: currentCategoryNotifier,
      builder: (context, currentCategory, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // カテゴリ選択（SegmentedButton風）
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: CardConstants.colorPalettes.keys.map((category) {
                  final isSelected = currentCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        currentCategoryNotifier.value = category;
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            // カラーチップ
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CardConstants.colorPalettes[currentCategory]!.map((color) {
                final isSelected = widget.selectedColor == color;
                return GestureDetector(
                  onTap: () => widget.onColorSelected(color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(
                        int.parse(color.replaceFirst('#', '0xFF')),
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.grey[400]!,
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 20,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

