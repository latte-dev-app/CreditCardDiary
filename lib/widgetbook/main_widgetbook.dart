import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:creditcarddiary/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../features/cards/application/card_provider.dart';
import '../features/cards/domain/card_model.dart';
import '../features/cards/domain/repositories/card_repository.dart';
import '../features/cards/domain/repositories/transaction_repository.dart';
import '../features/cards/presentation/screens/main_screen.dart';
import '../features/cards/presentation/screens/home_screen.dart';
import '../features/cards/presentation/screens/line_chart_screen.dart';
import '../features/cards/presentation/screens/settings_screen.dart';
import '../features/cards/presentation/screens/card_detail_screen.dart';
import '../app/app_theme.dart';

void main() {
  runApp(const WidgetbookApp());
}

class WidgetbookApp extends StatelessWidget {
  const WidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      directories: [
        WidgetbookCategory(
          name: 'Screens',
          children: [
            // MainScreen（ボトムナビ付きの全体画面）
            WidgetbookComponent(
              name: 'MainScreen',
              useCases: [
                WidgetbookUseCase(
                  name: 'Default',
                  builder:
                      (context) => _wrapWithProviders(
                        const MainScreen(),
                        includeScaffold: false,
                      ),
                ),
              ],
            ),
            // HomeScreen
            WidgetbookComponent(
              name: 'HomeScreen',
              useCases: [
                WidgetbookUseCase(
                  name: 'Default',
                  builder: (context) => _wrapWithProviders(const HomeScreen()),
                ),
                WidgetbookUseCase(
                  name: 'With Sample Data',
                  builder: (context) {
                    final provider = _createMockProvider();
                    return _wrapWithProviders(
                      const HomeScreen(),
                      provider: provider,
                    );
                  },
                ),
              ],
            ),
            // LineChartScreen
            WidgetbookComponent(
              name: 'LineChartScreen',
              useCases: [
                WidgetbookUseCase(
                  name: 'Default',
                  builder:
                      (context) => _wrapWithProviders(const LineChartScreen()),
                ),
                WidgetbookUseCase(
                  name: 'With Sample Data',
                  builder: (context) {
                    final provider = _createMockProvider();
                    return _wrapWithProviders(
                      const LineChartScreen(),
                      provider: provider,
                    );
                  },
                ),
              ],
            ),
            // SettingsScreen
            WidgetbookComponent(
              name: 'SettingsScreen',
              useCases: [
                WidgetbookUseCase(
                  name: 'Default',
                  builder:
                      (context) => _wrapWithProviders(const SettingsScreen()),
                ),
                WidgetbookUseCase(
                  name: 'With Sample Data',
                  builder: (context) {
                    final provider = _createMockProvider();
                    return _wrapWithProviders(
                      const SettingsScreen(),
                      provider: provider,
                    );
                  },
                ),
              ],
            ),
            // CardDetailScreen
            WidgetbookComponent(
              name: 'CardDetailScreen',
              useCases: [
                WidgetbookUseCase(
                  name: 'Default Card',
                  builder: (context) {
                    final mockCard = CreditCard(
                      id: '1',
                      name: '楽天カード',
                      type: 'Visa',
                      color: '#FF6B6B',
                    );
                    return _wrapWithProviders(CardDetailScreen(card: mockCard));
                  },
                ),
                WidgetbookUseCase(
                  name: 'Card with Image',
                  builder: (context) {
                    final mockCard = CreditCard(
                      id: '2',
                      name: 'PayPayカード',
                      type: 'Mastercard',
                      color: '#4ECDC4',
                      imagePath: null, // 画像パスは実際には存在しないためnull
                    );
                    return _wrapWithProviders(CardDetailScreen(card: mockCard));
                  },
                ),
                WidgetbookUseCase(
                  name: 'Card with Payment Settings',
                  builder: (context) {
                    final mockCard = CreditCard(
                      id: '3',
                      name: '三井住友カード',
                      type: 'JCB',
                      color: '#95E1D3',
                      closingDay: 25,
                      paymentDay: 10,
                    );
                    return _wrapWithProviders(CardDetailScreen(card: mockCard));
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // 共通ラッパー関数：ProviderとScaffoldを提供
  Widget _wrapWithProviders(
    Widget screen, {
    CardProvider? provider,
    bool includeScaffold = true,
  }) {
    final cardProvider = provider ?? _createMockProvider();

    Widget wrappedScreen = screen;

    if (includeScaffold) {
      wrappedScreen = Scaffold(body: wrappedScreen);
    }

    return MaterialApp(
      title: 'Widgetbook',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ja')],
      // 画面遷移時もProviderが利用可能になるように
      builder: (context, child) {
        return ChangeNotifierProvider.value(
          value: cardProvider,
          child: child ?? const SizedBox(),
        );
      },
      home: ChangeNotifierProvider.value(
        value: cardProvider,
        child: wrappedScreen,
      ),
    );
  }

  // モックデータを持つProviderを作成
  CardProvider _createMockProvider() {
    return CardProvider(
      cardRepo: FakeCardRepository(),
      txRepo: FakeTransactionRepository(),
    );
  }
}

class FakeCardRepository implements CardRepository {
  @override
  Future<List<CreditCard>> getAllCards() async => [];
  @override
  Future<void> addCard(CreditCard card) async {}
  @override
  Future<void> updateCard(CreditCard card) async {}
  @override
  Future<void> upsertCard(CreditCard card) async {}
  @override
  Future<void> deleteCard(String cardId) async {}
  @override
  Future<void> setCardBudget(
    String cardId,
    int year,
    int month,
    int amount,
  ) async {}
  @override
  Future<int?> getCardBudget(String cardId, int year, int month) async => null;
}

class FakeTransactionRepository implements TransactionRepository {
  @override
  Future<List<Transaction>> getAllTransactions() async => [];
  @override
  Future<void> addTransaction(Transaction transaction) async {}
  @override
  Future<void> updateTransaction(Transaction transaction) async {}
  @override
  Future<void> upsertTransaction(Transaction transaction) async {}
  @override
  Future<void> deleteTransaction(String transactionId) async {}
  @override
  Future<void> setTotalBudget(int year, int month, int amount) async {}
  @override
  Future<int?> getTotalBudget(int year, int month) async => null;
}
