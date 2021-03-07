import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:example/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      child: MyApp(),
      path: 'assets/langs',
      supportedLocales: MyApp.list,
      fallbackLocale: Locale("en"),
      useOnlyLangCode: true,
    ),
  );
}

class MyApp extends StatelessWidget {
  static const list = [
    Locale('en'),
    Locale('ar'),
  ];

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'Flutter Zoom Drawer Demo',
      onGenerateTitle: (context) => tr("app_name"),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
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
