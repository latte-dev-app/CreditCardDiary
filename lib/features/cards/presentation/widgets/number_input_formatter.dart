import 'package:flutter/services.dart';

/// 数値入力時にカンマを自動で追加するTextInputFormatter
class NumberTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 数字のみを抽出
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    // カンマ区切りでフォーマット
    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }
    
    final number = int.tryParse(digitsOnly);
    if (number == null) {
      return oldValue;
    }
    
    final formatted = number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    
    // カーソル位置を調整
    final selectionIndex = formatted.length;
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}

