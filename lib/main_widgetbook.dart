import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:widgetbook/widgetbook.dart';
import 'features/cards/application/card_provider.dart';
import 'features/cards/domain/card_model.dart';
import 'features/cards/presentation/screens/main_screen.dart';
import 'features/cards/presentation/screens/home_screen.dart';
import 'features/cards/presentation/screens/line_chart_screen.dart';
import 'features/cards/presentation/screens/settings_screen.dart';
import 'features/cards/presentation/screens/card_detail_screen.dart';

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
                  builder: (context) => _wrapWithProviders(
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
                  builder: (context) => _wrapWithProviders(
                    const HomeScreen(),
                  ),
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
                  builder: (context) => _wrapWithProviders(
                    const LineChartScreen(),
                  ),
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
                  builder: (context) => _wrapWithProviders(
                    const SettingsScreen(),
                  ),
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
                    return _wrapWithProviders(
                      CardDetailScreen(card: mockCard),
                    );
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
                    return _wrapWithProviders(
                      CardDetailScreen(card: mockCard),
                    );
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
                    return _wrapWithProviders(
                      CardDetailScreen(card: mockCard),
                    );
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
    final cardProvider = provider ?? CardProvider();
    
    Widget wrappedScreen = screen;

    if (includeScaffold) {
      wrappedScreen = Scaffold(body: wrappedScreen);
    }

    return MaterialApp(
      title: 'Widgetbook',
      theme: _createTheme(Brightness.light),
      darkTheme: _createTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
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

  // テーマを作成
  ThemeData _createTheme(Brightness brightness) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: brightness,
      ),
      useMaterial3: true,
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  // モックデータを持つProviderを作成
  CardProvider _createMockProvider() {
    final provider = CardProvider();
    
    // 注意: CardProviderの内部メソッドを直接呼び出すことはできないため、
    // 実際のデータは初期化時に空の状態で表示されます
    // より詳細なモックが必要な場合は、CardProviderにモックメソッドを追加するか、
    // テスト用のProviderを作成する必要があります
    
    return provider;
  }
}

