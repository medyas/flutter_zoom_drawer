import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';

extension ZoomDrawerContext on BuildContext {
  /// Drawer
  ZoomDrawerState? get drawer => ZoomDrawer.of(this);

  /// drawerLastAction
  DrawerLastAction? get drawerLastAction =>
      ZoomDrawer.of(this)?.drawerLastAction;

  /// drawerState
  DrawerState? get drawerState => ZoomDrawer.of(this)?.stateNotifier.value;

  /// drawerState notifier
  ValueNotifier<DrawerState>? get drawerStateNotifier =>
      ZoomDrawer.of(this)?.stateNotifier;

  /// Screen Width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Screen Height
  double get screenHeight => MediaQuery.of(this).size.height;
}
