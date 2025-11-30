import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/card_model.dart';
import '../screens/card_detail_screen.dart';
import '../../domain/logic/payment_logic.dart';
import '../../../../shared/utils/color_utils.dart';

class HomeCardItem extends StatelessWidget {
  final CreditCard card;
  final int amount;
  final NumberFormat currencyFormat;
  final int viewingMonth;
  final bool isPrivacyMode;

  const HomeCardItem({
    super.key,
    required this.card,
    required this.amount,
    required this.currencyFormat,
    required this.viewingMonth,
    required this.isPrivacyMode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPaymentApproaching = PaymentLogic.isPaymentDayApproaching(
      card.paymentDay,
    );
    final borderColor =
        isPaymentApproaching
            ? theme.colorScheme.error
            : theme.colorScheme.outline.withValues(alpha: 0.5);
    final borderWidth = isPaymentApproaching ? 2.0 : 1.0;

    // Calculate next payment date and days remaining
    String paymentInfo = '';
    if (card.paymentDay != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      DateTime paymentDate = DateTime(now.year, now.month, card.paymentDay!);
      if (paymentDate.isBefore(today)) {
        paymentDate = DateTime(now.year, now.month + 1, card.paymentDay!);
      }
      final difference = paymentDate.difference(today).inDays;

      paymentInfo = '$viewingMonth月${card.paymentDay}日支払い';
      if (isPaymentApproaching) {
        paymentInfo += ' (あと$difference日)';
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color:
                isPaymentApproaching
                    ? theme.colorScheme.error.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.03),
            blurRadius: isPaymentApproaching ? 20 : 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CardDetailScreen(card: card)),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Hero(
                  tag: 'card_hero_${card.id}',
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: ColorUtils.fromHex(card.color),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: ColorUtils.fromHex(
                            card.color,
                          ).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child:
                        card.imagePath != null
                            ? ClipOval(
                              child: Image.file(
                                File(card.imagePath!),
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) => const Icon(
                                      Icons.credit_card,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                              ),
                            )
                            : const Icon(
                              Icons.credit_card,
                              color: Colors.white,
                              size: 28,
                            ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              card.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isPaymentApproaching) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.warning_rounded,
                              size: 18,
                              color: theme.colorScheme.error,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        card.type,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isPrivacyMode ? '****' : currencyFormat.format(amount),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color:
                            isPaymentApproaching
                                ? theme.colorScheme.error
                                : theme.colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (paymentInfo.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        paymentInfo,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color:
                              isPaymentApproaching
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.outline,
                          fontWeight:
                              isPaymentApproaching
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
