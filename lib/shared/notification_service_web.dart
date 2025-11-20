// Web-specific implementation using dart:html
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

class NotificationImpl {
  static String get permission => html.Notification.permission ?? 'denied';

  static void showNotification(
    String title, {
    String? body,
    String? tag,
    String? icon,
  }) {
    html.Notification(title, body: body, tag: tag, icon: icon);
  }
}
