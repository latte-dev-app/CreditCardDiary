import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/cards/application/card_provider.dart';
import '../features/cards/presentation/screens/main_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CardProvider(),
      child: MaterialApp(
        title: 'クレカ使用額トラッカー',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          // カードテーマの改善
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          // 入力フィールドの改善
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          // ボタンテーマの改善
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
          // アニメーションデュレーション
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            },
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
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
        ),
        themeMode: ThemeMode.system,
        home: const MainScreen(),
      ),
    );
  }
}


