// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'クレカ使用額トラッカー';

  @override
  String get home => 'ホーム';

  @override
  String get spendingTrend => '支出推移';

  @override
  String get settings => '設定';

  @override
  String get addCard => 'カード追加';

  @override
  String get editCard => 'カード編集';

  @override
  String get deleteCard => 'カード削除';

  @override
  String get addTransaction => '支出追加';

  @override
  String get editTransaction => '支出編集';

  @override
  String get deleteTransaction => '支出削除';

  @override
  String get cancel => 'キャンセル';

  @override
  String get save => '保存';

  @override
  String get delete => '削除';

  @override
  String get confirmDelete => '本当に削除しますか？';

  @override
  String get totalAmount => '合計金額';

  @override
  String get averageAmount => '平均金額';

  @override
  String get billingMonth => '請求月';

  @override
  String get calendarMonth => 'カレンダー月';

  @override
  String get aggregationMode => '集計モード';

  @override
  String get aggregationModeDescription =>
      '請求月（締め日）ベースで集計するか、カレンダー月で集計するかを切り替えます。';

  @override
  String get deleteAllData => '全データ削除';

  @override
  String get deleteAllDataConfirm => '全てのデータを削除します。この操作は取り消せません。';

  @override
  String get deleteAllDataSuccess => '全データを削除しました';

  @override
  String get cardName => 'カード名';

  @override
  String get cardType => 'カード種類';

  @override
  String get cardColor => 'カード色';

  @override
  String get closingDay => '締め日';

  @override
  String get paymentDay => '支払日';

  @override
  String get transactionTitle => 'タイトル';

  @override
  String get transactionAmount => '金額';

  @override
  String get transactionDate => '日付';

  @override
  String get selectCard => 'カード選択';

  @override
  String get pleaseEnter => '入力してください';

  @override
  String get pleaseSelect => '選択してください';
}
