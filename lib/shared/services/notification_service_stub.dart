// Stub implementation for non-web platforms
class NotificationImpl {
  static String get permission => 'denied';
  static void showNotification(String title,
      {String? body, String? tag, String? icon}) {}
}
