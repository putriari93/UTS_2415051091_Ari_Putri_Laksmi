import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_info.dart';
import 'core/theme/app_theme.dart';
import 'providers/book_provider.dart';
import 'providers/favorite_provider.dart';
import 'providers/loan_provider.dart';
import 'providers/theme_provider.dart';
import 'repositories/book_repository.dart';
import 'repositories/loan_repository.dart';
import 'widgets/app_shell.dart';

class LenteraApp extends StatelessWidget {
  const LenteraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<BookRepository>(create: (_) => BookRepository()),
        Provider<LoanRepository>(create: (_) => LoanRepository()),
        ChangeNotifierProvider(
          lazy: false,
          create: (context) =>
              BookProvider(context.read<BookRepository>())..loadTrending(),
        ),
        ChangeNotifierProvider(
          lazy: false,
          create: (context) =>
              LoanProvider(context.read<LoanRepository>())..load(),
        ),
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: AppInfo.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeProvider.mode,
            home: const AppShell(),
          );
        },
      ),
    );
  }
}
