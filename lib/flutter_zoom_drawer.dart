library flutter_zoom_drawer;

import 'dart:math' show pi;
import 'dart:ui' as ui show window;
import 'package:flutter/material.dart';

class ZoomDrawerController {
  /// callback function to open the drawer
  Function open;

  /// callback function to close the drawer
  Function close;

  /// callback function to toggle the drawer
  Function toggle;
}

class ZoomDrawer extends StatefulWidget {
  ZoomDrawer({
    this.controller,
    @required this.menuScreen,
    @required this.mainScreen,
    this.slideWidth = 275.0,
    this.borderRadius = 16.0,
    this.angle = -12.0,
    this.backgroundColor = Colors.white,
    this.showShadow = false,
  }) : assert(angle <= 0.0 && angle >= -30.0);

  /// controller to have access to the open/close/toggle function of the drawer
  final ZoomDrawerController controller;

  /// Screen containing the menu/bottom screen
  final Widget menuScreen;

  /// Screen containing the main content to display
  final Widget mainScreen;

  /// Sliding width of the drawer - defaults to 275.0
  final double slideWidth;

  /// Border radius of the slided content - defaults to 16.0
  final double borderRadius;

  /// Rotation angle of the drawer - defaults to -12.0
  final double angle;

  /// Background color of the drawer shadows - defaults to white
  final Color backgroundColor;

  /// Boolean, whether to show the drawer shadows - defaults to false
  final bool showShadow;

  @override
  _ZoomDrawerState createState() => new _ZoomDrawerState();

  /// static function to provide the drawer state
  static _ZoomDrawerState of(BuildContext context) {
    return context.findAncestorStateOfType<State<ZoomDrawer>>();
  }

  /// Static function to determine the device text direction RTL/LTR
  static bool isRTL() {
    return ui.window.locale.languageCode.toLowerCase() == "ar";
  }
}

class _ZoomDrawerState extends State<ZoomDrawer>
    with SingleTickerProviderStateMixin {
  final Curve _scaleDownCurve = Interval(0.0, 0.3, curve: Curves.easeOut);
  final Curve _scaleUpCurve = Interval(0.0, 1.0, curve: Curves.easeOut);
  final Curve _slideOutCurve = Interval(0.0, 1.0, curve: Curves.easeOut);
  final Curve _slideInCurve = Interval(0.0, 1.0, curve: Curves.easeOut);

  /// check the slide direction
  final int _rtlSlide = ZoomDrawer.isRTL() ? -1 : 1;

  final bool _rtl = ZoomDrawer.isRTL();

  AnimationController _animationController;
  MenuState _state = MenuState.closed;

  double get percentOpen => _animationController.value;

  /// Open drawer
  open() {
    _animationController.forward();
  }

  /// Close drawer
  close() {
    _animationController.reverse();
  }

  /// Toggle drawer
  toggle() {
    if (_state == MenuState.open) {
      close();
    } else if (_state == MenuState.closed) {
      open();
    }
  }

  @override
  void initState() {
    super.initState();

    /// Initialize the animation controller
    /// add status listener to update the menuStatus
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..addStatusListener((AnimationStatus status) {
        switch (status) {
          case AnimationStatus.forward:
            _state = MenuState.opening;
            break;
          case AnimationStatus.reverse:
            _state = MenuState.closing;
            break;
          case AnimationStatus.completed:
            _state = MenuState.open;
            break;
          case AnimationStatus.dismissed:
            _state = MenuState.closed;
            break;
        }
      });

    /// assign controller function to the widget methods
    if (widget.controller != null) {
      widget.controller.open = open;
      widget.controller.close = close;
      widget.controller.toggle = toggle;
    }
  }

  @override
  void dispose() {
    super.dispose();
    _animationController.dispose();
  }

  /// Build the widget based on the animation value
  ///
  /// * [container] is the widget to be displayed
  ///
  /// * [angle] is the the Z rotation angle
  ///
  /// * [scale] is a string to help identify this animation during
  ///   debugging (used by [toString]).
  ///
  /// * [slide] is the sliding amount of the drawer
  ///
  Widget zoomAndSlideContent(Widget container,
      {double angle, double scale, double slide = 0}) {
    var slidePercent, scalePercent;

    /// determine current slide percent based on the MenuStatus
    switch (_state) {
      case MenuState.closed:
        slidePercent = 0.0;
        scalePercent = 0.0;
        break;
      case MenuState.open:
        slidePercent = 1.0;
        scalePercent = 1.0;
        break;
      case MenuState.opening:
        slidePercent = _slideOutCurve.transform(percentOpen);
        scalePercent = _scaleDownCurve.transform(percentOpen);
        break;
      case MenuState.closing:
        slidePercent = _slideInCurve.transform(percentOpen);
        scalePercent = _scaleUpCurve.transform(percentOpen);
        break;
    }

    /// calculated sliding amount based on the RTL and animation value
    final slideAmount = (widget.slideWidth - slide) * slidePercent * _rtlSlide;

    /// calculated scale amount based on the provided scale and animation value
    final contentScale = (scale ?? 1.0) - (0.2 * scalePercent);

    /// calculated radius based on the provided radius and animation value
    final cornerRadius = widget.borderRadius * percentOpen;

    /// calculated rotation amount based on the provided angle and animation value
    final rotationAngle = ((angle ?? widget.angle) * pi / 180) * percentOpen;

    return Transform(
      transform: Matrix4.translationValues(slideAmount, 0.0, 0.0)
        ..rotateZ(rotationAngle)
        ..scale(contentScale, contentScale),
      alignment: Alignment.centerLeft,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cornerRadius),
        child: container,
      ),
    );
  }

  /*
    Container(
        decoration: BoxDecoration(
          boxShadow: Platform.isAndroid
              ? [
                  BoxShadow(
                    color: Colors.black12,
                    offset: const Offset(0.0, 5.0),
                    blurRadius: 15.0,
                    spreadRadius: 10.0,
                  ),
                ]
              : kElevationToShadow[5],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(cornerRadius),
          child: container,
        ),
      )
  * */

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          child: widget.menuScreen,

          /// Detecting the slide amount to close the drawer in RTL & LTR
          onPanUpdate: (details) {
            if (details.delta.dx < -6 && !_rtl ||
                details.delta.dx < 6 && _rtl) {
              toggle();
            }
          },
        ),
        if (widget.showShadow) ...[
          /// Displaying the first shadow
          AnimatedBuilder(
            animation: _animationController,
            builder: (_, w) => zoomAndSlideContent(w,
                angle: widget.angle - 8, scale: .9, slide: 20),
            child: Container(
              color: widget.backgroundColor.withAlpha(31),
            ),
          ),

          /// Displaying the second shadow
          AnimatedBuilder(
            animation: _animationController,
            builder: (_, w) => zoomAndSlideContent(w,
                angle: widget.angle - 4.0, scale: .95, slide: 10),
            child: Container(
              color: widget.backgroundColor,
            ),
          )
        ],

        /// Displaying the main screen
        AnimatedBuilder(
          animation: _animationController,
          builder: (_, w) => zoomAndSlideContent(w),
          child: widget.mainScreen,
        ),
      ],
    );
  }
}

/// Drawer State enum
enum MenuState { opening, closing, open, closed }
