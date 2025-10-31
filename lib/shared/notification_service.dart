// Webブラウザ通知サービス（PWA対応）

import 'package:flutter/foundation.dart';
import '../features/cards/application/card_provider.dart';

// Web専用のインポート
import 'dart:html' as html;

class NotificationService {
  static bool _permissionRequested = false;

  // 通知権限をリクエスト
  static Future<bool> requestPermission() async {
    if (!kIsWeb) return false;
    
    if (_permissionRequested) {
      return html.Notification.permission == 'granted';
    }

    try {
      if (html.Notification.permission == 'granted') {
        _permissionRequested = true;
        return true;
      }

      if (html.Notification.permission == 'default') {
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
    if (html.Notification.permission != 'granted') {
      debugPrint('通知権限がありません（permission: ${html.Notification.permission}）');
      return;
    }

    try {
      html.Notification(
        title,
        body: body,
        tag: tag,
        icon: '/icons/Icon-192.png',
      );
    } catch (e) {
      debugPrint('通知表示エラー: $e');
    }
  }

  // ユーザーインタラクションから通知権限をリクエスト
  static Future<bool> requestPermissionFromUser() async {
    if (!kIsWeb) return false;

    try {
      if (html.Notification.permission == 'granted') {
        return true;
      }

      if (html.Notification.permission == 'default') {
        // 権限リクエストはブラウザが自動的に処理する
        // 実際の権限リクエストは通知を表示しようとしたときに自動的に表示される
        return false;
      }

      return false; // 'denied'
    } catch (e) {
      debugPrint('通知権限リクエストエラー: $e');
      return false;
    }
  }

  // 支払日前のリマインド通知をチェック
  static Future<void> checkPaymentReminders(CardProvider provider) async {
    if (!kIsWeb) return;

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
          tag: 'payment_reminder_${card.id}_${paymentDate.millisecondsSinceEpoch}',
        );
      }
    }
  }
}

