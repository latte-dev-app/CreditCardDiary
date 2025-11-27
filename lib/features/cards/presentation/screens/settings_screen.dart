import 'dart:convert';

import 'package:flutter/material.dart';
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
              RadioListTile<ThemeMode>(
                title: const Text('システム設定に従う'),
                value: ThemeMode.system,
                groupValue: themeProvider.themeMode,
                onChanged: (value) => themeProvider.setThemeMode(value!),
              ),
              RadioListTile<ThemeMode>(
                title: const Text('ライトモード'),
                value: ThemeMode.light,
                groupValue: themeProvider.themeMode,
                onChanged: (value) => themeProvider.setThemeMode(value!),
              ),
              RadioListTile<ThemeMode>(
                title: const Text('ダークモード'),
                value: ThemeMode.dark,
                groupValue: themeProvider.themeMode,
                onChanged: (value) => themeProvider.setThemeMode(value!),
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
                  return SwitchListTile(
                    title: const Text('支払日リマインダー'),
                    subtitle: const Text('支払日の3日前から通知します'),
                    value: isEnabled,
                    onChanged: (value) async {
                      await NotificationService.setNotificationEnabled(value);
                      // Force rebuild to show new state
                      if (context.mounted) {
                        (context as Element).markNeedsBuild();
                      }
                    },
                    secondary: Icon(
                      Icons.notifications,
                      color: colorScheme.primary,
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
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                leading: Icon(
                  Icons.upload_file,
                  size: 24.0,
                  color: colorScheme.onSurface,
                ),
                title: Text('データをエクスポート', style: textTheme.titleMedium),
                subtitle: Text('JSON形式でダウンロード', style: textTheme.bodySmall),
                onTap: () => _exportData(context),
              ),
              Divider(height: 1, color: colorScheme.outlineVariant),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                leading: Icon(
                  Icons.file_download,
                  size: 24.0,
                  color: colorScheme.onSurface,
                ),
                title: Text('データをインポート', style: textTheme.titleMedium),
                subtitle: Text('JSONファイルから復元', style: textTheme.bodySmall),
                onTap: () => _showImportDialog(context),
              ),
              Divider(height: 1, color: colorScheme.outlineVariant),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                leading: Icon(
                  Icons.delete_forever,
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
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                leading: Icon(
                  Icons.info,
                  size: 24.0,
                  color: colorScheme.onSurface,
                ),
                title: Text('クレカ使用額トラッカー', style: textTheme.titleMedium),
                subtitle: Text('バージョン 1.0.0', style: textTheme.bodySmall),
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

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('データをインポート', style: textTheme.titleLarge),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'エクスポートしたJSONデータを貼り付けてください。\n※現在のデータは上書きされます。',
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: textController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'JSONデータをここに貼り付け...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
              FilledButton(
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

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('データをエクスポート', style: textTheme.titleLarge),
            elevation: 24.0,
            content: SingleChildScrollView(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: SelectableText(
                  formattedJson,
                  style: textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                child: const Text('閉じる'),
              ),
              ElevatedButton(
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
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('全データを削除', style: textTheme.titleLarge),
            content: Text(
              '本当に全てのデータを削除しますか？この操作は取り消せません。',
              style: textTheme.bodyMedium,
            ),
            elevation: 24.0,
            actions: [
              TextButton(
                onPressed: () {
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () {
                  // 全データを削除
                  context.read<CardProvider>().deleteAllData();
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('データを削除しました')));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                ),
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
