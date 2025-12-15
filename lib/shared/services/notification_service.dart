// Webブラウザ通知サービス（PWA対応）

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/cards/application/card_provider.dart';

// Web専用のインポート
// Conditional import to handle platform-specific code
import 'notification_service_stub.dart'
    if (dart.library.html) 'notification_service_web.dart';

/// 通知権限の結果を表す列挙型
enum NotificationPermissionResult {
  granted, // 権限が許可されている
  denied, // 権限が拒否されている
  defaultState, // まだリクエストされていない
  notSupported, // 通知がサポートされていない（Web以外など）
  error, // エラーが発生した
}

class NotificationService {
  static bool _permissionRequested = false;

  // 通知権限をリクエスト
  static Future<bool> requestPermission() async {
    if (!kIsWeb) return false;

    if (_permissionRequested) {
      return NotificationImpl.permission == 'granted';
    }

    try {
      if (NotificationImpl.permission == 'granted') {
        _permissionRequested = true;
        return true;
      }

      if (NotificationImpl.permission == 'default') {
        // 権限をリクエスト（ユーザーインタラクションが必要な場合がある）
        // 実際の権限リクエストはユーザーのアクション（ボタンクリックなど）から呼び出す必要がある
        // ここでは既存の権限状態のみをチェック
        _permissionRequested = true;
        return false; // 権限がまだ取得されていない
      }
    } catch (e) {
      debugPrint('通知権限リクエストエラー: $e');
    }

    return false;
  }

  // 通知を表示
  static Future<void> showNotification({
    required String title,
    required String body,
    String? tag,
  }) async {
    if (!kIsWeb) return;

    // 権限がない場合は通知を表示しない
    if (NotificationImpl.permission != 'granted') {
      debugPrint('通知権限がありません(permission: ${NotificationImpl.permission})');
      return;
    }

    try {
      NotificationImpl.showNotification(
        title,
        body: body,
        tag: tag,
        icon: '/icons/Icon-192.png',
      );
    } catch (e) {
      debugPrint('通知表示エラー: $e');
    }
  }

  /// ユーザーインタラクションから通知権限をリクエスト
  /// このメソッドはボタンクリックなどのユーザーアクションから呼び出す必要があります
  static Future<NotificationPermissionResult> requestPermissionFromUser() async {
    if (!kIsWeb) {
      return NotificationPermissionResult.notSupported;
    }

    try {
      final currentPermission = NotificationImpl.permission;
      
      if (currentPermission == 'granted') {
        return NotificationPermissionResult.granted;
      }

      if (currentPermission == 'denied') {
        return NotificationPermissionResult.denied;
      }

      // 権限をリクエスト
      final result = await NotificationImpl.requestPermission();
      
      if (result == 'granted') {
        _permissionRequested = true;
        return NotificationPermissionResult.granted;
      } else if (result == 'denied') {
        return NotificationPermissionResult.denied;
      } else {
        return NotificationPermissionResult.defaultState;
      }
    } catch (e) {
      debugPrint('通知権限リクエストエラー: $e');
      return NotificationPermissionResult.error;
    }
  }

  /// 現在の通知権限状態を取得
  static Future<NotificationPermissionResult> getPermissionStatus() async {
    if (!kIsWeb) {
      return NotificationPermissionResult.notSupported;
    }

    try {
      final permission = NotificationImpl.permission;
      switch (permission) {
        case 'granted':
          return NotificationPermissionResult.granted;
        case 'denied':
          return NotificationPermissionResult.denied;
        case 'default':
          return NotificationPermissionResult.defaultState;
        default:
          return NotificationPermissionResult.error;
      }
    } catch (e) {
      debugPrint('通知権限状態取得エラー: $e');
      return NotificationPermissionResult.error;
    }
  }

  static const String _keyNotificationEnabled = 'notification_enabled';

  // 通知設定を取得
  static Future<bool> getNotificationEnabled() async {
    if (!kIsWeb) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotificationEnabled) ?? true; // Default to true
  }

  static Future<void> setNotificationEnabled(bool enabled) async {
    if (!kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationEnabled, enabled);
  }

  // 支払日前のリマインド通知をチェック
  static Future<void> checkPaymentReminders(CardProvider provider) async {
    if (!kIsWeb) return;

    // Check if notifications are enabled
    if (!await getNotificationEnabled()) return;

    final now = DateTime.now();
    final cards = provider.cards;

    // 支払日が設定されているカードをチェック
    for (final card in cards) {
      if (card.paymentDay == null) continue;

      final monthlyTotal = provider.getMonthlyTotalByCardId(card.id);
      if (monthlyTotal.isEmpty) continue;

      // 最新の取引月を取得
      final sortedMonths = monthlyTotal.keys.toList()..sort();
      final latestMonth = sortedMonths.last;
      final latestYear = int.parse(latestMonth.split('-')[0]);
      final latestMonthNum = int.parse(latestMonth.split('-')[1]);

      // 支払日を計算（最新の取引月の支払日）
      DateTime paymentDate;
      try {
        paymentDate = DateTime(latestYear, latestMonthNum, card.paymentDay!);
      } catch (e) {
        // 月末日の調整（例：2月30日→2月28日）
        final lastDayOfMonth = DateTime(latestYear, latestMonthNum + 1, 0).day;
        paymentDate = DateTime(
          latestYear,
          latestMonthNum,
          card.paymentDay! > lastDayOfMonth ? lastDayOfMonth : card.paymentDay!,
        );
      }

      // 支払日が過去の場合はスキップ（既に支払済みとみなす）
      if (paymentDate.isBefore(now.subtract(const Duration(days: 1)))) {
        continue;
      }

      // 支払日までの日数を計算
      final daysUntilPayment = paymentDate.difference(now).inDays;

      // 支払日が3日以内の場合、通知を表示
      if (daysUntilPayment >= 0 && daysUntilPayment <= 3) {
        String message;
        if (daysUntilPayment == 0) {
          message = '${card.name}の支払日は今日です';
        } else if (daysUntilPayment == 1) {
          message = '${card.name}の支払日は明日です';
        } else {
          message = '${card.name}の支払日まであと$daysUntilPayment日です';
        }

        await showNotification(
          title: '支払日リマインド',
          body: message,
          tag:
              'payment_reminder_${card.id}_${paymentDate.millisecondsSinceEpoch}',
        );
      }
    }
  }
}
