import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // For ThemeMode and Colors if needed
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../application/card_provider.dart';
import '../../../../app/theme_provider.dart';
import '../../../../shared/services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<bool>? _notificationEnabledFuture;

  @override
  void initState() {
    super.initState();
    _notificationEnabledFuture = NotificationService.getNotificationEnabled();
  }

  void _refreshNotificationEnabled() {
    setState(() {
      _notificationEnabledFuture = NotificationService.getNotificationEnabled();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? CupertinoColors.white : CupertinoColors.black;
    final secondaryTextColor =
        isDark ? CupertinoColors.systemGrey : CupertinoColors.secondaryLabel;

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
              header: const Text('テーマ設定'),
              children: [
                CupertinoListTile(
                  leading: Icon(
                    CupertinoIcons.device_phone_portrait,
                    color: textColor,
                  ),
                  title: Text('自動', style: TextStyle(color: textColor)),
                  trailing:
                      themeProvider.themeMode == ThemeMode.system
                          ? const Icon(CupertinoIcons.checkmark_alt)
                          : null,
                  onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                ),
                CupertinoListTile(
                  leading: Icon(CupertinoIcons.sun_max, color: textColor),
                  title: Text('ライト', style: TextStyle(color: textColor)),
                  trailing:
                      themeProvider.themeMode == ThemeMode.light
                          ? const Icon(CupertinoIcons.checkmark_alt)
                          : null,
                  onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                ),
                CupertinoListTile(
                  leading: Icon(CupertinoIcons.moon, color: textColor),
                  title: Text('ダーク', style: TextStyle(color: textColor)),
                  trailing:
                      themeProvider.themeMode == ThemeMode.dark
                          ? const Icon(CupertinoIcons.checkmark_alt)
                          : null,
                  onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              header: const Text('通知設定'),
              children: [
                FutureBuilder<bool>(
                  future: _notificationEnabledFuture,
                  builder: (context, snapshot) {
                    final isEnabled = snapshot.data ?? false;
                    return CupertinoListTile(
                      title: Text(
                        '支払日リマインダー',
                        style: TextStyle(color: textColor),
                      ),
                      subtitle: Text(
                        '支払日の3日前から通知',
                        style: TextStyle(color: secondaryTextColor),
                      ),
                      leading: Icon(CupertinoIcons.bell, color: textColor),
                      trailing: CupertinoSwitch(
                        value: isEnabled,
                        onChanged: (value) async {
                          HapticFeedback.selectionClick();
                          await NotificationService.setNotificationEnabled(
                            value,
                          );
                          if (mounted) {
                            _refreshNotificationEnabled();
                          }
                        },
                      ),
                    );
                  },
                ),
                FutureBuilder<NotificationPermissionResult>(
                  future: NotificationService.getPermissionStatus(),
                  builder: (context, snapshot) {
                    final permissionStatus = snapshot.data ?? NotificationPermissionResult.notSupported;
                    String statusText;
                    bool showRequestButton = false;

                    switch (permissionStatus) {
                      case NotificationPermissionResult.granted:
                        statusText = '通知は許可されています';
                        showRequestButton = false;
                        break;
                      case NotificationPermissionResult.denied:
                        statusText = '通知は拒否されています';
                        showRequestButton = false;
                        break;
                      case NotificationPermissionResult.defaultState:
                        statusText = '通知権限をリクエスト';
                        showRequestButton = true;
                        break;
                      case NotificationPermissionResult.notSupported:
                        statusText = '通知はサポートされていません';
                        showRequestButton = false;
                        break;
                      case NotificationPermissionResult.error:
                        statusText = 'エラーが発生しました';
                        showRequestButton = false;
                        break;
                    }

                    return CupertinoListTile(
                      title: Text(
                        '通知権限',
                        style: TextStyle(color: textColor),
                      ),
                      subtitle: Text(
                        statusText,
                        style: TextStyle(color: secondaryTextColor),
                      ),
                      leading: Icon(
                        permissionStatus == NotificationPermissionResult.granted
                            ? CupertinoIcons.checkmark_circle_fill
                            : CupertinoIcons.exclamationmark_circle,
                        color: permissionStatus == NotificationPermissionResult.granted
                            ? CupertinoColors.activeGreen
                            : textColor,
                      ),
                      trailing: showRequestButton
                          ? CupertinoButton(
                              padding: EdgeInsets.zero,
                              child: Text(
                                'リクエスト',
                                style: TextStyle(
                                  color: CupertinoColors.activeBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onPressed: () async {
                                final result = await NotificationService.requestPermissionFromUser();
                                if (context.mounted) {
                                  String message;
                                  switch (result) {
                                    case NotificationPermissionResult.granted:
                                      message = '通知権限が許可されました';
                                      break;
                                    case NotificationPermissionResult.denied:
                                      message = '通知権限が拒否されました。ブラウザの設定から許可してください。';
                                      break;
                                    default:
                                      message = '通知権限のリクエストに失敗しました';
                                  }

                                  showCupertinoDialog(
                                    context: context,
                                    builder: (context) => CupertinoAlertDialog(
                                      title: const Text('通知権限'),
                                      content: Text(message),
                                      actions: [
                                        CupertinoDialogAction(
                                          isDefaultAction: true,
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    ),
                                  );

                                  // UIを更新
                                  (context as Element).markNeedsBuild();
                                }
                              },
                            )
                          : null,
                    );
                  },
                ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              header: const Text('データ管理'),
              children: [
                CupertinoListTile(
                  leading: Icon(
                    CupertinoIcons.square_arrow_up,
                    color: textColor,
                  ),
                  title: Text('データをエクスポート', style: TextStyle(color: textColor)),
                  subtitle: Text(
                    'JSON形式でダウンロード',
                    style: TextStyle(color: secondaryTextColor),
                  ),
                  onTap: () => _exportData(context),
                ),
                CupertinoListTile(
                  leading: Icon(
                    CupertinoIcons.square_arrow_down,
                    color: textColor,
                  ),
                  title: Text('データをインポート', style: TextStyle(color: textColor)),
                  subtitle: Text(
                    'JSONファイルから復元',
                    style: TextStyle(color: secondaryTextColor),
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
                  leading: Icon(CupertinoIcons.info, color: textColor),
                  title: Text(
                    'クレカ使用額トラッカー',
                    style: TextStyle(color: textColor),
                  ),
                  additionalInfo: Text(
                    'v1.0.0',
                    style: TextStyle(color: secondaryTextColor),
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
