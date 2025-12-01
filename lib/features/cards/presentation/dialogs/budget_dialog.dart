import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../application/card_provider.dart';
import '../widgets/number_input_formatter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/widgets/native_dialog.dart';

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
    text:
        currentBudget != null
            ? currentBudget.toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (Match m) => '${m[1]},',
            )
            : '',
  );
  final theme = Theme.of(context);

  await showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          title: Text(
            '$year年$month月の予算設定',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: budgetController,
            decoration: InputDecoration(
              labelText: '予算額',
              hintText: '例: 50,000',
              prefixText: '¥ ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              NumberTextInputFormatter(),
            ],
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'キャンセル',
                style: GoogleFonts.plusJakartaSans(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (currentBudget != null)
              TextButton(
                onPressed: () async {
                  await provider.setTotalBudget(year, month, 0);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: Text(
                  '削除',
                  style: GoogleFonts.plusJakartaSans(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            FilledButton(
              onPressed: () async {
                final budgetStr = budgetController.text.trim().replaceAll(
                  ',',
                  '',
                );
                if (budgetStr.isNotEmpty) {
                  final budget = int.tryParse(budgetStr);
                  if (budget != null && budget >= 0) {
                    await provider.setTotalBudget(year, month, budget);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  }
                } else {
                  showNativeErrorDialog(context, '予算額を入力してください');
                }
              },
              child: Text(
                '保存',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
  );
}
