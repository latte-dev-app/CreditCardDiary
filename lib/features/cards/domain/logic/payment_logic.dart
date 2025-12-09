class PaymentLogic {
  static bool isPaymentDayApproaching(int? paymentDay) {
    if (paymentDay == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check current month's payment day
    DateTime paymentDate = DateTime(now.year, now.month, paymentDay);
    DateTime adjustedPaymentDate = _adjustForWeekend(paymentDate);

    // If passed, check next month
    if (adjustedPaymentDate.isBefore(today)) {
      paymentDate = DateTime(now.year, now.month + 1, paymentDay);
      adjustedPaymentDate = _adjustForWeekend(paymentDate);
    }

    final difference = adjustedPaymentDate.difference(today).inDays;
    return difference >= 0 && difference <= 3;
  }

  static bool isPaid(int? paymentDay, int targetYear, int targetMonth) {
    if (paymentDay == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetMonthStart = DateTime(targetYear, targetMonth, 1);
    final currentMonthStart = DateTime(now.year, now.month, 1);

    if (targetMonthStart.isBefore(currentMonthStart)) {
      return true; // Past month
    }
    if (targetMonthStart.isAfter(currentMonthStart)) {
      return false; // Future month
    }

    // Current month: Paid if today is strictly after ADJUSTED payment day
    final paymentDate = DateTime(targetYear, targetMonth, paymentDay);
    final adjustedPaymentDate = _adjustForWeekend(paymentDate);

    return today.isAfter(adjustedPaymentDate);
  }

  static DateTime _adjustForWeekend(DateTime date) {
    if (date.weekday == DateTime.saturday) {
      return date.add(const Duration(days: 2)); // Saturday -> Monday
    } else if (date.weekday == DateTime.sunday) {
      return date.add(const Duration(days: 1)); // Sunday -> Monday
    }
    return date;
  }
}
