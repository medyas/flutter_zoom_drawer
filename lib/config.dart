import 'package:flutter/material.dart';

/// Drawer State enum
/// Note: Upon Drawer dragging the state is always opening
/// Use DrawerLastAction to figure if last state was opened or closed
enum DrawerState { opening, closing, open, closed }

/// Drawer last action enum
/// To detect last action from drawer if it was opened or closed.
enum DrawerLastAction { opened, closed }

class ZoomDrawerController {
  /// Callback function to open the drawer
  void Function()? open;

  /// Callback function to close the drawer
  void Function()? close;

  /// Callback function to toggle the drawer
  void Function({bool forceToggle})? toggle;

  /// Callback function to determine the status of the drawer
  void Function()? isOpen;

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
