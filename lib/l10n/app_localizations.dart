import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('ja')];

  /// No description provided for @appTitle.
  ///
  /// In ja, this message translates to:
  /// **'クレカ使用額トラッカー'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In ja, this message translates to:
  /// **'ホーム'**
  String get home;

  /// No description provided for @spendingTrend.
  ///
  /// In ja, this message translates to:
  /// **'支出推移'**
  String get spendingTrend;

  /// No description provided for @settings.
  ///
  /// In ja, this message translates to:
  /// **'設定'**
  String get settings;

  /// No description provided for @addCard.
  ///
  /// In ja, this message translates to:
  /// **'カード追加'**
  String get addCard;

  /// No description provided for @editCard.
  ///
  /// In ja, this message translates to:
  /// **'カード編集'**
  String get editCard;

  /// No description provided for @deleteCard.
  ///
  /// In ja, this message translates to:
  /// **'カード削除'**
  String get deleteCard;

  /// No description provided for @addTransaction.
  ///
  /// In ja, this message translates to:
  /// **'支出追加'**
  String get addTransaction;

  /// No description provided for @editTransaction.
  ///
  /// In ja, this message translates to:
  /// **'支出編集'**
  String get editTransaction;

  /// No description provided for @deleteTransaction.
  ///
  /// In ja, this message translates to:
  /// **'支出削除'**
  String get deleteTransaction;

  /// No description provided for @cancel.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In ja, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In ja, this message translates to:
  /// **'削除'**
  String get delete;

  /// No description provided for @confirmDelete.
  ///
  /// In ja, this message translates to:
  /// **'本当に削除しますか？'**
  String get confirmDelete;

  /// No description provided for @totalAmount.
  ///
  /// In ja, this message translates to:
  /// **'合計金額'**
  String get totalAmount;

  /// No description provided for @averageAmount.
  ///
  /// In ja, this message translates to:
  /// **'平均金額'**
  String get averageAmount;

  /// No description provided for @billingMonth.
  ///
  /// In ja, this message translates to:
  /// **'請求月'**
  String get billingMonth;

  /// No description provided for @calendarMonth.
  ///
  /// In ja, this message translates to:
  /// **'カレンダー月'**
  String get calendarMonth;

  /// No description provided for @aggregationMode.
  ///
  /// In ja, this message translates to:
  /// **'集計モード'**
  String get aggregationMode;

  /// No description provided for @aggregationModeDescription.
  ///
  /// In ja, this message translates to:
  /// **'請求月（締め日）ベースで集計するか、カレンダー月で集計するかを切り替えます。'**
  String get aggregationModeDescription;

  /// No description provided for @deleteAllData.
  ///
  /// In ja, this message translates to:
  /// **'全データ削除'**
  String get deleteAllData;

  /// No description provided for @deleteAllDataConfirm.
  ///
  /// In ja, this message translates to:
  /// **'全てのデータを削除します。この操作は取り消せません。'**
  String get deleteAllDataConfirm;

  /// No description provided for @deleteAllDataSuccess.
  ///
  /// In ja, this message translates to:
  /// **'全データを削除しました'**
  String get deleteAllDataSuccess;

  /// No description provided for @cardName.
  ///
  /// In ja, this message translates to:
  /// **'カード名'**
  String get cardName;

  /// No description provided for @cardType.
  ///
  /// In ja, this message translates to:
  /// **'カード種類'**
  String get cardType;

  /// No description provided for @cardColor.
  ///
  /// In ja, this message translates to:
  /// **'カード色'**
  String get cardColor;

  /// No description provided for @closingDay.
  ///
  /// In ja, this message translates to:
  /// **'締め日'**
  String get closingDay;

  /// No description provided for @paymentDay.
  ///
  /// In ja, this message translates to:
  /// **'支払日'**
  String get paymentDay;

  /// No description provided for @transactionTitle.
  ///
  /// In ja, this message translates to:
  /// **'タイトル'**
  String get transactionTitle;

  /// No description provided for @transactionAmount.
  ///
  /// In ja, this message translates to:
  /// **'金額'**
  String get transactionAmount;

  /// No description provided for @transactionDate.
  ///
  /// In ja, this message translates to:
  /// **'日付'**
  String get transactionDate;

  /// No description provided for @selectCard.
  ///
  /// In ja, this message translates to:
  /// **'カード選択'**
  String get selectCard;

  /// No description provided for @pleaseEnter.
  ///
  /// In ja, this message translates to:
  /// **'入力してください'**
  String get pleaseEnter;

  /// No description provided for @pleaseSelect.
  ///
  /// In ja, this message translates to:
  /// **'選択してください'**
  String get pleaseSelect;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
