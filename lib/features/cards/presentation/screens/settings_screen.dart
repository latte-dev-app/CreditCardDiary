import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../application/card_provider.dart';
import '../../../../app/theme_provider.dart';
import '../../../../shared/services/notification_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('設定', style: textTheme.titleLarge),
        elevation: 0,
        surfaceTintColor: colorScheme.surfaceTint,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        children: [
          _SettingsSection(
            title: '表示設定',
            children: [
              CupertinoFormSection.insetGrouped(
                header: const Text('テーマ設定'),
                children: [
                  CupertinoFormRow(
                    prefix: const Text('システム設定に従う'),
                    child: CupertinoSwitch(
                      value: themeProvider.themeMode == ThemeMode.system,
                      onChanged: (value) {
                        if (value) themeProvider.setThemeMode(ThemeMode.system);
                      },
                    ),
                  ),
                  CupertinoFormRow(
                    prefix: const Text('ライトモード'),
                    child: CupertinoSwitch(
                      value: themeProvider.themeMode == ThemeMode.light,
                      onChanged: (value) {
                        if (value) themeProvider.setThemeMode(ThemeMode.light);
                      },
                    ),
                  ),
                  CupertinoFormRow(
                    prefix: const Text('ダークモード'),
                    child: CupertinoSwitch(
                      value: themeProvider.themeMode == ThemeMode.dark,
                      onChanged: (value) {
                        if (value) themeProvider.setThemeMode(ThemeMode.dark);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: '通知設定',
            children: [
              FutureBuilder<bool>(
                future: NotificationService.getNotificationEnabled(),
                builder: (context, snapshot) {
                  final isEnabled = snapshot.data ?? false;
                  return CupertinoListTile(
                    title: const Text('支払日リマインダー'),
                    subtitle: const Text('支払日の3日前から通知します'),
                    leading: Icon(
                      CupertinoIcons.bell,
                      color: colorScheme.primary,
                    ),
                    trailing: CupertinoSwitch(
                      value: isEnabled,
                      onChanged: (value) async {
                        await NotificationService.setNotificationEnabled(value);
                        // Force rebuild to show new state
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
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'データ管理',
            children: [
              CupertinoListTile(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                leading: Icon(
                  CupertinoIcons.square_arrow_up,
                  size: 24.0,
                  color: colorScheme.onSurface,
                ),
                title: Text('データをエクスポート', style: textTheme.titleMedium),
                subtitle: Text('JSON形式でダウンロード', style: textTheme.bodySmall),
                onTap: () => _exportData(context),
              ),
              Divider(height: 1, color: colorScheme.outlineVariant),
              CupertinoListTile(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                leading: Icon(
                  CupertinoIcons.square_arrow_down,
                  size: 24.0,
                  color: colorScheme.onSurface,
                ),
                title: Text('データをインポート', style: textTheme.titleMedium),
                subtitle: Text('JSONファイルから復元', style: textTheme.bodySmall),
                onTap: () => _showImportDialog(context),
              ),
              Divider(height: 1, color: colorScheme.outlineVariant),
              CupertinoListTile(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                leading: Icon(
                  CupertinoIcons.trash,
                  size: 24.0,
                  color: colorScheme.error,
                ),
                title: Text(
                  '全データを削除',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
                subtitle: Text('全てのデータを削除します', style: textTheme.bodySmall),
                onTap: () => _showDeleteAllDataDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'アプリ情報',
            children: [
              CupertinoListTile(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                leading: Icon(
                  CupertinoIcons.info,
                  size: 24.0,
                  color: colorScheme.onSurface,
                ),
                title: Text('クレカ使用額トラッカー', style: textTheme.titleMedium),
                subtitle: Text('バージョン 1.0.0', style: textTheme.bodySmall),
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
    );
  }

  void _showImportDialog(BuildContext context) {
    final textController = TextEditingController();
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: Text('データをインポート', style: textTheme.titleLarge),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'エクスポートしたJSONデータを貼り付けてください。\n※現在のデータは上書きされます。',
                  style: textTheme.bodyMedium,
                ),
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('データを復元しました')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('エラーが発生しました: $e'),
                          backgroundColor: theme.colorScheme.error,
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
    // Pretty print JSON
    final rawJson = provider.exportToJson();
    final dynamic parsedJson = jsonDecode(rawJson);
    final encoder = const JsonEncoder.withIndent('  ');
    final formattedJson = encoder.convert(parsedJson);

    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: Text('データをエクスポート', style: textTheme.titleLarge),
            content: Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                child: Text(
                  formattedJson,
                  style: textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
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
                  // クリップボードにコピー
                  await Clipboard.setData(ClipboardData(text: formattedJson));
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('データをクリップボードにコピーしました')),
                  );
                },
                child: const Text('コピー'),
              ),
            ],
          ),
    );
  }

  void _showDeleteAllDataDialog(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: Text('全データを削除', style: textTheme.titleLarge),
            content: Text(
              '本当に全てのデータを削除しますか？この操作は取り消せません。',
              style: textTheme.bodyMedium,
            ),
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
                  // 全データを削除
                  context.read<CardProvider>().deleteAllData();
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('データを削除しました')));
                },
                child: const Text('削除'),
              ),
            ],
          ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(child: Column(children: children)),
      ],
    );
  }
}
