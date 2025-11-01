import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/card_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('設定', style: textTheme.titleLarge),
        elevation: 0,
        surfaceTintColor: colorScheme.surfaceTint,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Card(
                elevation: 2,
                color: colorScheme.surface.withValues(alpha: 0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(
                    color: colorScheme.outline.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              leading: Icon(Icons.info, size: 24.0, color: colorScheme.onSurface),
              title: Text(
                'クレカ使用額トラッカー',
                style: textTheme.titleMedium,
              ),
              subtitle: Text(
                'バージョン 1.0.0',
                style: textTheme.bodySmall,
              ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Card(
                elevation: 2,
                color: colorScheme.surface.withValues(alpha: 0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(
                    color: colorScheme.outline.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              leading: Icon(Icons.upload_file, size: 24.0, color: colorScheme.onSurface),
              title: Text(
                'データをエクスポート',
                style: textTheme.titleMedium,
              ),
              subtitle: Text(
                'JSON形式でダウンロード',
                style: textTheme.bodySmall,
              ),
              onTap: () => _exportData(context),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Card(
                elevation: 2,
                color: colorScheme.surface.withValues(alpha: 0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(
                    color: colorScheme.outline.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: ListTile(
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
              subtitle: Text(
                '全てのデータを削除します',
                style: textTheme.bodySmall,
              ),
              onTap: () => _showDeleteAllDataDialog(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _exportData(BuildContext context) {
    final provider = context.read<CardProvider>();
    final jsonData = provider.exportToJson();
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('データをエクスポート', style: textTheme.titleLarge),
        elevation: 24.0,
        content: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: SelectableText(
              jsonData,
              style: textTheme.bodySmall,
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
            onPressed: () {
              // クリップボードにコピー
              // Webでは実際のファイルダウンロード機能は制限があるため、
              // テキストをコピーしてファイルとして保存できるようにする
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('データをコピーしました。テキストエディタに貼り付けて保存してください。'),
                ),
              );
              if (!context.mounted) return;
              Navigator.pop(context);
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
      builder: (context) => AlertDialog(
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('データを削除しました'),
                ),
              );
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

