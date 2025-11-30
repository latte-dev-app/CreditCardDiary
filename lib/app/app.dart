import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:creditcarddiary/l10n/app_localizations.dart';
import '../features/cards/application/card_provider.dart';
import '../features/cards/domain/repositories/card_repository.dart';
import '../features/cards/domain/repositories/transaction_repository.dart';
import '../features/cards/presentation/screens/main_screen.dart';
import 'service_locator.dart';
import 'app_theme.dart';
import '../features/cards/application/fixed_cost_provider.dart';
import '../features/cards/infrastructure/local_storage.dart';
import 'theme_provider.dart';
import '../features/cards/presentation/screens/splash_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create:
              (_) => CardProvider(
                cardRepo: getIt<CardRepository>(),
                txRepo: getIt<TransactionRepository>(),
              )..init(),
        ),
        ChangeNotifierProvider(
          create:
              (_) => FixedCostProvider(
                SharedPreferencesRepository(), // Using the implementation directly as it's not in GetIt yet for this specific type, or we can cast/update GetIt
              )..loadFixedCosts(),
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            onGenerateTitle:
                (context) => AppLocalizations.of(context)!.appTitle,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.themeMode,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('ja'), // Japanese
            ],
            home: Consumer2<CardProvider, FixedCostProvider>(
              builder: (context, cardProvider, fixedCostProvider, child) {
                if (cardProvider.isLoading || fixedCostProvider.isLoading) {
                  return const SplashScreen();
                }
                return const MainScreen();
              },
            ),
          );
        },
      ),
    );
  }
}
