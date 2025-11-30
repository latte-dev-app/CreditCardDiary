import 'package:flutter/material.dart';

class ColorUtils {
  /// 指定された色が明るいかどうかを判定する
  ///
  /// [color] 判定対象の色
  /// Returns: 明るい場合は true, 暗い場合は false
  static bool isLightColor(Color color) {
    return ThemeData.estimateBrightnessForColor(color) == Brightness.light;
  }

  /// 背景色に基づいて適切なテキスト色（白または黒）を返す
  ///
  /// [backgroundColor] 背景色
  /// Returns: 背景が明るい場合は黒, 暗い場合は白
  static Color getTextColorForBackground(Color backgroundColor) {
    return isLightColor(backgroundColor) ? Colors.black : Colors.white;
  }

  /// Hex文字列からColorを生成する
  ///
  /// [hexString] #RRGGBB 形式の文字列
  /// [defaultColor] パース失敗時のデフォルト色 (デフォルト: グレー)
  static Color fromHex(String hexString, {Color defaultColor = Colors.grey}) {
    try {
      var hex = hexString.replaceFirst('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      debugPrint('Error parsing color: $hexString');
      return defaultColor;
    }
  }
}
