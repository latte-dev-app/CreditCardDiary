// Stub implementation for non-web platforms
class NotificationImpl {
  static String get permission => 'denied';
  
  static Future<String> requestPermission() async => 'denied';
  
  static Future<void> showNotification(
    String title, {
    String? body,
    String? tag,
    String? icon,
  }) async {}
}
