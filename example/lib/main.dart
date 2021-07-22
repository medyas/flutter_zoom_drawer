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
      saveLocale: true,
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
        primarySwatch: Colors.blue,
        accentColor: Colors.orange,
      ),
      home: ChangeNotifierProvider(
        create: (_) => MenuProvider(),
        child: HomeScreen(),
      ),
    );
  }

  /// Languages that are Right to Left
  static List<String> RTL_LANGUAGES = ["ar", "ur", "he", "dv", "fa"];

  /// Static function to determine the device text direction RTL/LTR
  static bool isRTL() {
    /// Device language
    final locale = _getLanguageCode();

    return RTL_LANGUAGES.contains(locale);
  }

  static String? _getLanguageCode() {
    try {
      return ui.window.locale!.languageCode.toLowerCase();
    } catch (e) {
      return null;
    }
  }
}


