import 'dart:io';
import 'dart:math' show pi;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';

class PageStructure extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget> actions;
  final Color backgroundColor;
  final double elevation;

  const PageStructure({
    Key key,
    @required this.title,
    @required this.child,
    this.actions,
    this.backgroundColor,
    this.elevation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final angle = ZoomDrawer.isRTL() ? 180 * pi / 180 : 0.0;

    return PlatformScaffold(
      backgroundColor: backgroundColor,
      appBar: PlatformAppBar(
        automaticallyImplyLeading: false,
        android: (_) => MaterialAppBarData(elevation: elevation),
        title: PlatformText(
          title,
        ),
        leading: Transform.rotate(
          angle: angle,
          child: PlatformIconButton(
            icon: Icon(
              Icons.menu,
            ),
            onPressed: () {
              ZoomDrawer.of(context).toggle();
            },
          ),
        ),
        trailingActions: actions,
      ),
      body: Platform.isAndroid
          ? child
          : SafeArea(
              child: child,
            ),
    );
  }
}
