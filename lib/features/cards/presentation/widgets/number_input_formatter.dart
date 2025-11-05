import 'package:flutter/services.dart';

/// 数値入力時にカンマを自動で追加するTextInputFormatter
/// 1000未満の場合はカンマを付けない
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
    
    // 1000未満の場合はカンマを付けない
    String formatted;
    if (number < 1000) {
      formatted = digitsOnly;
    } else {
      formatted = digitsOnly.replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
    }
    
    // カーソル位置を計算
    final cursorOffset = newValue.selection.baseOffset;
    
    // カーソル位置までの数字の数を数える
    final textBeforeCursor = newValue.text.substring(0, cursorOffset.clamp(0, newValue.text.length));
    final digitsBeforeCursor = textBeforeCursor.replaceAll(RegExp(r'[^\d]'), '').length;
    
    // フォーマット後のテキストで、同じ数の数字の位置を探す
    int newCursorOffset;
    if (number < 1000) {
      // カンマがない場合、数字の数がそのまま位置
      newCursorOffset = digitsBeforeCursor.clamp(0, formatted.length);
    } else {
      // カンマがある場合、数字の位置を正確に計算
      // フォーマット後のテキストを左から走査して、digitsBeforeCursor個の数字の位置を見つける
      int digitCount = 0;
      newCursorOffset = formatted.length; // デフォルトは最後
      
      for (int i = 0; i < formatted.length; i++) {
        if (formatted[i] != ',') {
          digitCount++;
          // カーソル位置までの数字数に達したら、その直後をカーソル位置にする
          if (digitCount == digitsBeforeCursor) {
            newCursorOffset = i + 1;
            break;
          }
        }
      }
      
      // 数字が増えた場合（入力時）、カーソルを右に移動
      final oldDigits = oldValue.text.replaceAll(RegExp(r'[^\d]'), '');
      if (digitsOnly.length > oldDigits.length && digitsBeforeCursor == digitsOnly.length) {
        // 最後の数字の後
        newCursorOffset = formatted.length;
      }
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCursorOffset.clamp(0, formatted.length)),
    );
  }
}

