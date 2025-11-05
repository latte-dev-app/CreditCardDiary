import 'package:flutter/material.dart';

/// 予算進捗バーウィジェット
/// 予算を超えた場合、超過分を視覚的に表示
class BudgetProgressBar extends StatelessWidget {
  final int totalAmount;
  final int budget;
  final VoidCallback? onEditPressed;

  const BudgetProgressBar({
    super.key,
    required this.totalAmount,
    required this.budget,
    this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final budgetRatio = (totalAmount / budget).clamp(0.0, 1.0);
    final isOverBudget = totalAmount > budget;
    final overAmount = isOverBudget ? totalAmount - budget : 0;

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '予算進捗',
                style: textTheme.titleSmall?.copyWith(
                  color: isOverBudget ? colorScheme.error : null,
                ),
              ),
              if (onEditPressed != null)
                TextButton(
                  onPressed: onEditPressed,
                  child: const Text('設定'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // プログレスバー
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 12,
              child: Stack(
                children: [
                  // 背景色
                  Container(
                    color: colorScheme.surfaceContainerHighest,
                  ),
                  // 予算内の部分（100%まで）
                  if (!isOverBudget)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final progressWidth = constraints.maxWidth * budgetRatio;
                        return Positioned(
                          left: 0,
                          top: 0,
                          child: Container(
                            width: progressWidth,
                            height: 12,
                            decoration: BoxDecoration(
                              color: budgetRatio >= 0.8
                                  ? Colors.orange[400]!
                                  : Colors.green[400]!,
                            ),
                          ),
                        );
                      },
                    ),
                  // 予算超過の場合：バー全体を赤くし、100%の位置に線を表示
                  if (isOverBudget)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final fullWidth = constraints.maxWidth;
                        // 予算の100%の位置を計算（予算/合計金額の比率）
                        final budgetPosition = (budget / totalAmount).clamp(0.0, 1.0);
                        return Stack(
                          children: [
                            // バー全体を濃い赤で表示
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.red[500]!,
                                      Colors.red[700]!,
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                ),
                              ),
                            ),
                            // 100%の位置に線を表示（予算の境界）
                            Positioned(
                              left: fullWidth * budgetPosition,
                              top: 0,
                              child: Container(
                                width: 2,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 2,
                                      offset: const Offset(0, 0),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // パーセント表示
              Text(
                '${((totalAmount / budget) * 100).toStringAsFixed(1)}%',
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isOverBudget
                      ? colorScheme.error
                      : budgetRatio >= 0.8
                          ? Colors.orange[700]
                          : Colors.green[700],
                ),
              ),
              // 金額表示
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${totalAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} / ${budget.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}円',
                    style: textTheme.bodySmall,
                  ),
                  // 超過金額表示
                  if (isOverBudget)
                    Text(
                      '超過: ${overAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}円',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

