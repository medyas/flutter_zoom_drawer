import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:example/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

void main() => runApp(EasyLocalization(
      child: MyApp(),
      path: 'assets/langs',
      supportedLocales: MyApp.list,
      useOnlyLangCode: true,
    ));

class MyApp extends StatelessWidget {
  static const list = [
    Locale('en', 'US'),
    Locale('ar', 'TN'),
  ];

  @override
  Widget build(BuildContext context) {
    final windowLocale = ui.window.locale;
    Locale locale;
    try {
      final first = MyApp.list
          ?.firstWhere((l) => l?.languageCode == windowLocale?.languageCode);
      locale = first != null ? first : Locale('en', 'US');
    } catch (e) {
      print(e);
    }

    return MaterialApp(
      title: 'Flutter Zoom Drawer Demo',
      onGenerateTitle: (context) => tr("app_name"),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        //app-specific localization
        EasyLocalization
            .of(context)
            .delegate,
      ],
      supportedLocales: EasyLocalization
          .of(context)
          .supportedLocales,
      locale: locale,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        accentColor: Colors.deepPurpleAccent,
      ),
      home: ChangeNotifierProvider(
        create: (_) => MenuProvider(),
        child: HomeScreen(),
      ),
    );
  }
}
