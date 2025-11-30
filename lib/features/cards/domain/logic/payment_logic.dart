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
}
