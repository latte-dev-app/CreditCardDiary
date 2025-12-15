// Web-specific implementation using dart:html
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

class NotificationImpl {
  static String get permission {
    try {
      return html.Notification.permission ?? 'denied';
    } catch (e) {
      return 'denied';
    }
  }

  /// 通知権限をリクエスト（ユーザーインタラクションから呼び出す必要がある）
  static Future<String> requestPermission() async {
    try {
      final currentPermission = html.Notification.permission ?? 'denied';
      if (currentPermission == 'granted') {
        return 'granted';
      }

      if (currentPermission == 'denied') {
        return 'denied';
      }

      // 権限をリクエスト（ユーザーインタラクションが必要）
      final result = await html.Notification.requestPermission();
      return result ?? 'denied';
    } catch (e) {
      return 'denied';
    }
  }

  /// 通知を表示（Service Worker経由も試行）
  static Future<void> showNotification(
    String title, {
    String? body,
    String? tag,
    String? icon,
  }) async {
    try {
      // まずService Worker経由で通知を試行（バックグラウンド対応）
      final registration = await html.window.navigator.serviceWorker?.ready;
      if (registration != null) {
        try {
          // Service WorkerのshowNotificationはオプションオブジェクトを使用
          final options = {
            'body': body,
            'tag': tag,
            'icon': icon ?? '/icons/Icon-192.png',
            'badge': '/icons/Icon-192.png',
            'requireInteraction': false,
          };
          await registration.showNotification(title, options);
          return;
        } catch (e) {
          // Service Worker経由で失敗した場合は通常の通知APIを使用
        }
      }

      // 通常の通知APIを使用（フォアグラウンド）
      html.Notification(
        title,
        body: body,
        tag: tag,
        icon: icon ?? '/icons/Icon-192.png',
      );
    } catch (e) {
      // 通知表示に失敗した場合はエラーを無視（ログのみ）
      print('通知表示エラー: $e');
    }
  }
}
