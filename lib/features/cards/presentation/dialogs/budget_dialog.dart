import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../application/card_provider.dart';
import '../widgets/number_input_formatter.dart';

/// 予算設定ダイアログを表示
Future<void> showBudgetDialog(
  BuildContext context,
  CardProvider provider,
  int year,
  int month,
) async {
  final currentBudget = await provider.getTotalBudget(year, month);
  if (!context.mounted) return;

  final budgetController = TextEditingController(
    text: currentBudget != null
        ? currentBudget.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          )
        : '',
  );
  final theme = Theme.of(context);
  final textTheme = theme.textTheme;

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('$year年$month月の予算設定', style: textTheme.titleLarge),
      elevation: 24.0,
      content: TextField(
        controller: budgetController,
        decoration: const InputDecoration(
          labelText: '予算額',
          hintText: '例: 50,000',
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          NumberTextInputFormatter(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        if (currentBudget != null)
          TextButton(
            onPressed: () async {
              await provider.setTotalBudget(year, month, 0);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ElevatedButton(
          onPressed: () async {
            final budgetStr =
                budgetController.text.trim().replaceAll(',', '');
            if (budgetStr.isNotEmpty) {
              final budget = int.tryParse(budgetStr);
              if (budget != null && budget >= 0) {
                await provider.setTotalBudget(year, month, budget);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            }
          },
          child: const Text('保存'),
        ),
      ],
    ),
  );
}

