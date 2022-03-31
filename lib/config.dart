import 'package:flutter/material.dart';

/// Drawer State enum
enum DrawerState { opening, closing, open, closed }

class ZoomDrawerController {
  /// callback function to open the drawer
  Function? open;

  /// callback function to close the drawer
  Function? close;

  /// callback function to toggle the drawer
  void Function()? toggle;

  /// callback function to determine the status of the drawer
  Function? isOpen;

  /// Drawer state notifier
  /// opening, closing, open, closed
  ValueNotifier<DrawerState>? stateNotifier;
}

enum DrawerStyle {
  defaultStyle,
  style1,
  style2,
  style3,
  style4,
  style5,
  style6,
  style7,
  style8,
}

/// Build custom style with (context, percentOpen, slideWidth, menuScreen, mainScreen) {}
typedef DrawerStyleBuilder = Widget Function(
  BuildContext context,
  double percentOpen,
  double slideWidth,
  Widget menuScreen,
  Widget mainScreen,
);
