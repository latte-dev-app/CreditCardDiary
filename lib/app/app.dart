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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (_) => CardProvider(
            cardRepo: getIt<CardRepository>(),
            txRepo: getIt<TransactionRepository>(),
          )..init(), // Initialize data loading
      child: MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ja'), // Japanese
        ],
        home: const MainScreen(),
      ),
    );
  }
}
