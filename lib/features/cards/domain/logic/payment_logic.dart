class PaymentLogic {
  static bool isPaymentDayApproaching(int? paymentDay) {
    if (paymentDay == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check current month's payment day
    DateTime paymentDate = DateTime(now.year, now.month, paymentDay);

    // If passed, check next month
    if (paymentDate.isBefore(today)) {
      paymentDate = DateTime(now.year, now.month + 1, paymentDay);
    }

    final difference = paymentDate.difference(today).inDays;
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

    // Current month: Paid if today is strictly after payment day
    return today.day > paymentDay;
  }
}
