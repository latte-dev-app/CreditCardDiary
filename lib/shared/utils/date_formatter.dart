class DateFormatter {
  static String toYearMonthString(int year, int month) {
    return '$year-${month.toString().padLeft(2, '0')}';
  }
}
