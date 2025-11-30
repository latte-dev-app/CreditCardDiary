import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeBudgetCard extends StatelessWidget {
  final int totalAmount;
  final int budget;
  final bool isPrivacyMode;
  final VoidCallback onTap;

  const HomeBudgetCard({
    super.key,
    required this.totalAmount,
    required this.budget,
    required this.isPrivacyMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'ja_JP', symbol: '¥');

    final budgetProgress =
        budget > 0 ? (totalAmount / budget).clamp(0.0, 1.0) : 0.0;
    final remainingBudget = budget - totalAmount;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  budget > 0
                      ? '残り予算: ${isPrivacyMode ? '****' : currencyFormat.format(remainingBudget)}'
                      : '予算を設定する',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (budget > 0)
                  Text(
                    '${(budgetProgress * 100).toInt()}%',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            if (budget > 0) ...[
              const SizedBox(height: 12),
              Stack(
                children: [
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: budgetProgress),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return FractionallySizedBox(
                        widthFactor: value,
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color:
                                remainingBudget < 0
                                    ? theme.colorScheme.error
                                    : const Color(0xFF34D399),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: (remainingBudget < 0
                                        ? theme.colorScheme.error
                                        : const Color(0xFF34D399))
                                    .withValues(alpha: 0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
