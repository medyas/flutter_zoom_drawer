library flutter_zoom_drawer;

import 'dart:math' show pi;
import 'dart:ui' as ui show window;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class ZoomDrawerController {
  /// callback function to open the drawer
  Function open;

  /// callback function to close the drawer
  Function close;

  /// callback function to toggle the drawer
  Function toggle;

  /// callback function to determine the status of the drawer
  Function isOpen;

  /// Drawer state notifier
  /// opening, closing, open, closed
  ValueNotifier<DrawerState> stateNotifier;
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
    this.openCurve,
    this.closeCurve,
    this.duration,
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

  /// Drawer slide out curve
  final Curve openCurve;

  /// Drawer slide in curve
  final Curve closeCurve;

  /// Drawer Duration
  final Duration duration;

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
  final Curve _slideInCurve =
      Interval(0.0, 1.0, curve: Curves.easeOut); // Curves.bounceOut

  /// check the slide direction
  final int _rtlSlide = ZoomDrawer.isRTL() ? -1 : 1;

  final bool _rtl = ZoomDrawer.isRTL();

  AnimationController _animationController;
  DrawerState _state = DrawerState.closed;

  double get _percentOpen => _animationController.value;

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
    if (_state == DrawerState.open) {
      close();
    } else if (_state == DrawerState.closed) {
      open();
    }
  }

  /// check whether drawer is open
  bool isOpen() =>
      _state == DrawerState.open /* || _state == DrawerState.opening*/;

  /// Drawer state
  ValueNotifier<DrawerState> stateNotifier;

  @override
  void initState() {
    super.initState();

    stateNotifier = ValueNotifier(_state);

    /// Initialize the animation controller
    /// add status listener to update the menuStatus
    _animationController = AnimationController(
        vsync: this, duration: widget.duration is Duration ? widget.duration : Duration(milliseconds: 250))
      ..addStatusListener((AnimationStatus status) {
        switch (status) {
          case AnimationStatus.forward:
            _state = DrawerState.opening;
            _updateStatusNotifier();
            break;
          case AnimationStatus.reverse:
            _state = DrawerState.closing;
            _updateStatusNotifier();
            break;
          case AnimationStatus.completed:
            _state = DrawerState.open;
            _updateStatusNotifier();
            break;
          case AnimationStatus.dismissed:
            _state = DrawerState.closed;
            _updateStatusNotifier();
            break;
        }
      });

    /// assign controller function to the widget methods
    if (widget.controller != null) {
      widget.controller.open = open;
      widget.controller.close = close;
      widget.controller.toggle = toggle;
      widget.controller.isOpen = isOpen;
      widget.controller.stateNotifier = stateNotifier;
    }
  }

  _updateStatusNotifier() {
    stateNotifier.value = _state;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
  Widget _zoomAndSlideContent(Widget container,
      {double angle, double scale, double slide = 0}) {
    var slidePercent, scalePercent;

    /// determine current slide percent based on the MenuStatus
    switch (_state) {
      case DrawerState.closed:
        slidePercent = 0.0;
        scalePercent = 0.0;
        break;
      case DrawerState.open:
        slidePercent = 1.0;
        scalePercent = 1.0;
        break;
      case DrawerState.opening:
        slidePercent =
            (widget.openCurve ?? _slideOutCurve).transform(_percentOpen);
        scalePercent = _scaleDownCurve.transform(_percentOpen);
        break;
      case DrawerState.closing:
        slidePercent =
            (widget.closeCurve ?? _slideInCurve).transform(_percentOpen);
        scalePercent = _scaleUpCurve.transform(_percentOpen);
        break;
    }

    /// calculated sliding amount based on the RTL and animation value
    final slideAmount = (widget.slideWidth - slide) * slidePercent * _rtlSlide;

    /// calculated scale amount based on the provided scale and animation value
    final contentScale = (scale ?? 1.0) - (0.2 * scalePercent);

    /// calculated radius based on the provided radius and animation value
    final cornerRadius = widget.borderRadius * _percentOpen;

    /// calculated rotation amount based on the provided angle and animation value
    final rotationAngle =
        (((angle ?? widget.angle) * pi * _rtlSlide) / 180) * _percentOpen;

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
    final slidePercent =
        ZoomDrawer.isRTL() ? MediaQuery.of(context).size.width * .1 : 15.0;

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
            builder: (_, w) => _zoomAndSlideContent(w,
                angle: (widget.angle == 0.0) ? 0.0 : widget.angle - 8,
                scale: .9,
                slide: slidePercent * 2),
            child: Container(
              color: widget.backgroundColor.withAlpha(31),
            ),
          ),

          /// Displaying the second shadow
          AnimatedBuilder(
            animation: _animationController,
            builder: (_, w) => _zoomAndSlideContent(w,
                angle: (widget.angle == 0.0) ? 0.0 : widget.angle - 4.0,
                scale: .95,
                slide: slidePercent),
            child: Container(
              color: widget.backgroundColor,
            ),
          )
        ],

        /// Displaying the main screen
        AnimatedBuilder(
          animation: _animationController,
          builder: (_, w) => _zoomAndSlideContent(w),
          child: widget.mainScreen,
        ),
      ],
    );
  }
}

/// Drawer State enum
enum DrawerState { opening, closing, open, closed }
