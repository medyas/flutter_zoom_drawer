import 'package:example/home_screen.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'package:provider/provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {


  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Zoom Drawer Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          accentColor: Colors.deepPurpleAccent),
      home: ChangeNotifierProvider(
        create: (_) => MenuProvider(),
        child: HomeScreen(),
      ),
    );
  }
}
