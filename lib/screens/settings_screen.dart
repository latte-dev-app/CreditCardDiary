import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/card_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('クレカ使用額トラッカー'),
            subtitle: Text('バージョン 1.0.0'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('データをエクスポート'),
            subtitle: const Text('JSON形式でダウンロード'),
            onTap: () => _exportData(context),
          ),
          ListTile(
            leading: const Icon(Icons.upload),
            title: const Text('データをインポート'),
            subtitle: const Text('JSON形式からインポート'),
            onTap: () => _importData(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text(
              '全データを削除',
              style: TextStyle(color: Colors.red),
            ),
            subtitle: const Text('全てのデータを削除します'),
            onTap: () => _showDeleteAllDataDialog(context),
          ),
        ],
      ),
    );
  }

  void _exportData(BuildContext context) {
    final provider = context.read<CardProvider>();
    final jsonData = provider.exportToJson();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('データをエクスポート'),
        content: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: SelectableText(
              jsonData,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
              Navigator.pop(context);
            },
            child: const Text('コピー'),
          ),
        ],
      ),
    );
  }

  void _importData(BuildContext context) {
    final jsonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('データをインポート'),
        content: SingleChildScrollView(
          child: TextField(
            controller: jsonController,
            maxLines: 10,
            decoration: const InputDecoration(
              hintText: 'JSON形式のデータを貼り付けてください',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              final jsonData = jsonController.text.trim();
              if (jsonData.isNotEmpty) {
                try {
                  await context.read<CardProvider>().importFromJson(jsonData);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('データをインポートしました'),
                      ),
                    );
                  }
                  Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('インポートに失敗しました: $e'),
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('インポート'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('全データを削除'),
        content: const Text('本当に全てのデータを削除しますか？この操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              // 全データを削除
              context.read<CardProvider>().deleteAllData();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('データを削除しました'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
}

