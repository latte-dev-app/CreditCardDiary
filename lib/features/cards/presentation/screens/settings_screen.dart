import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // For ThemeMode and Colors if needed
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../application/card_provider.dart';
import '../../../../app/theme_provider.dart';
import '../../../../shared/services/notification_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('設定'),
        backgroundColor: CupertinoColors.systemGroupedBackground,
        border: null, // Remove border for a cleaner look matching insetGrouped
      ),
      child: SafeArea(
        child: ListView(
          children: [
            CupertinoListSection.insetGrouped(
              header: const Text('表示設定'),
              children: [
                CupertinoFormRow(
                  prefix: const Text(
                    'テーマ設定',
                    style: TextStyle(color: CupertinoColors.label),
                  ),
                  child: CupertinoSlidingSegmentedControl<ThemeMode>(
                    groupValue: themeProvider.themeMode,
                    children: const {
                      ThemeMode.system: Text('自動'),
                      ThemeMode.light: Text('ライト'),
                      ThemeMode.dark: Text('ダーク'),
                    },
                    onValueChanged: (value) {
                      if (value != null) {
                        themeProvider.setThemeMode(value);
                      }
                    },
                  ),
                ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              header: const Text('通知設定'),
              children: [
                FutureBuilder<bool>(
                  future: NotificationService.getNotificationEnabled(),
                  builder: (context, snapshot) {
                    final isEnabled = snapshot.data ?? false;
                    return CupertinoListTile(
                      title: const Text(
                        '支払日リマインダー',
                        style: TextStyle(color: CupertinoColors.label),
                      ),
                      subtitle: const Text(
                        '支払日の3日前から通知',
                        style: TextStyle(color: CupertinoColors.secondaryLabel),
                      ),
                      leading: const Icon(CupertinoIcons.bell),
                      trailing: CupertinoSwitch(
                        value: isEnabled,
                        onChanged: (value) async {
                          await NotificationService.setNotificationEnabled(
                            value,
                          );
                          if (context.mounted) {
                            (context as Element).markNeedsBuild();
                          }
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              header: const Text('データ管理'),
              children: [
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.square_arrow_up),
                  title: const Text(
                    'データをエクスポート',
                    style: TextStyle(color: CupertinoColors.label),
                  ),
                  subtitle: const Text(
                    'JSON形式でダウンロード',
                    style: TextStyle(color: CupertinoColors.secondaryLabel),
                  ),
                  onTap: () => _exportData(context),
                ),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.square_arrow_down),
                  title: const Text(
                    'データをインポート',
                    style: TextStyle(color: CupertinoColors.label),
                  ),
                  subtitle: const Text(
                    'JSONファイルから復元',
                    style: TextStyle(color: CupertinoColors.secondaryLabel),
                  ),
                  onTap: () => _showImportDialog(context),
                ),
                CupertinoListTile(
                  leading: const Icon(
                    CupertinoIcons.trash,
                    color: CupertinoColors.destructiveRed,
                  ),
                  title: const Text(
                    '全データを削除',
                    style: TextStyle(color: CupertinoColors.destructiveRed),
                  ),
                  onTap: () => _showDeleteAllDataDialog(context),
                ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              header: const Text('アプリ情報'),
              children: [
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.info),
                  title: const Text(
                    'クレカ使用額トラッカー',
                    style: TextStyle(color: CupertinoColors.label),
                  ),
                  additionalInfo: const Text(
                    'v1.0.0',
                    style: TextStyle(color: CupertinoColors.secondaryLabel),
                  ),
                  onTap: () {
                    showCupertinoDialog(
                      context: context,
                      builder:
                          (context) => CupertinoAlertDialog(
                            title: const Text('Credit Card Diary'),
                            content: const Text(
                              'クレジットカードの利用履歴を管理するアプリです。\n\nVersion 1.0.0',
                            ),
                            actions: [
                              CupertinoDialogAction(
                                isDefaultAction: true,
                                onPressed: () => Navigator.pop(context),
                                child: const Text('閉じる'),
                              ),
                            ],
                          ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    final textController = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('データをインポート'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('エクスポートしたJSONデータを貼り付けてください。\n※現在のデータは上書きされます。'),
                const SizedBox(height: 16),
                CupertinoTextField(
                  controller: textController,
                  maxLines: 5,
                  placeholder: 'JSONデータをここに貼り付け...',
                ),
              ],
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () async {
                  try {
                    final jsonString = textController.text;
                    if (jsonString.isEmpty) return;

                    await context.read<CardProvider>().importFromJson(
                      jsonString,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      // Use a native-style alert instead of SnackBar for success
                      showCupertinoDialog(
                        context: context,
                        builder:
                            (context) => CupertinoAlertDialog(
                              title: const Text('完了'),
                              content: const Text('データを復元しました'),
                              actions: [
                                CupertinoDialogAction(
                                  isDefaultAction: true,
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      showCupertinoDialog(
                        context: context,
                        builder:
                            (context) => CupertinoAlertDialog(
                              title: const Text('エラー'),
                              content: Text('エラーが発生しました: $e'),
                              actions: [
                                CupertinoDialogAction(
                                  isDefaultAction: true,
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                      );
                    }
                  }
                },
                child: const Text('インポート'),
              ),
            ],
          ),
    );
  }

  void _exportData(BuildContext context) {
    final provider = context.read<CardProvider>();
    final rawJson = provider.exportToJson();
    final dynamic parsedJson = jsonDecode(rawJson);
    final encoder = const JsonEncoder.withIndent('  ');
    final formattedJson = encoder.convert(parsedJson);

    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('データをエクスポート'),
            content: Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                child: Text(
                  formattedJson,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () {
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                child: const Text('閉じる'),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: formattedJson));
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  // Use native alert for success
                  showCupertinoDialog(
                    context: context,
                    builder:
                        (context) => CupertinoAlertDialog(
                          title: const Text('完了'),
                          content: const Text('データをクリップボードにコピーしました'),
                          actions: [
                            CupertinoDialogAction(
                              isDefaultAction: true,
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                  );
                },
                child: const Text('コピー'),
              ),
            ],
          ),
    );
  }

  void _showDeleteAllDataDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('全データを削除'),
            content: const Text('本当に全てのデータを削除しますか？この操作は取り消せません。'),
            actions: [
              CupertinoDialogAction(
                onPressed: () {
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                child: const Text('キャンセル'),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () {
                  context.read<CardProvider>().deleteAllData();
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  showCupertinoDialog(
                    context: context,
                    builder:
                        (context) => CupertinoAlertDialog(
                          title: const Text('完了'),
                          content: const Text('データを削除しました'),
                          actions: [
                            CupertinoDialogAction(
                              isDefaultAction: true,
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                  );
                },
                child: const Text('削除'),
              ),
            ],
          ),
    );
  }
}
