library flutter_zoom_drawer;

import 'dart:math' show pi;
import 'dart:ui' as ui show window;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ZoomDrawerController {
  /// callback function to open the drawer
  Function? open;

  /// callback function to close the drawer
  Function? close;

  /// callback function to toggle the drawer
  Function? toggle;

  /// callback function to determine the status of the drawer
  Function? isOpen;

  /// Drawer state notifier
  /// opening, closing, open, closed
  ValueNotifier<DrawerState>? stateNotifier;
}

class ZoomDrawer extends StatefulWidget {
  ZoomDrawer({
    this.type = StyleState.styleDefault,
    this.controller,
    required this.menuScreen,
    required this.mainScreen,
    this.slideWidth = 275.0,
    this.slideHeight = 0.0,
    this.borderRadius = 16.0,
    this.angle = -12.0,
    this.backgroundColor = Colors.white,
    this.shadowColor = Colors.white,
    this.showShadow = false,
    this.openCurve,
    this.closeCurve,
    this.duration,
  }) : assert(angle <= 0.0 && angle >= -30.0);

  // Layout style
  final StyleState type;

  /// controller to have access to the open/close/toggle function of the drawer
  final ZoomDrawerController? controller;

  /// Screen containing the menu/bottom screen
  final Widget menuScreen;

  /// Screen containing the main content to display
  final Widget mainScreen;

  /// Sliding width of the drawer - defaults to 275.0
  final double slideWidth;
  final double slideHeight;

  /// Border radius of the slided content - defaults to 16.0
  final double borderRadius;

  /// Rotation angle of the drawer - defaults to -12.0
  final double angle;

  /// Background color of the drawer shadows - defaults to white
  final Color backgroundColor;

  final Color shadowColor;

  /// Boolean, whether to show the drawer shadows - defaults to false
  final bool showShadow;

  /// Drawer slide out curve
  final Curve? openCurve;

  /// Drawer slide in curve
  final Curve? closeCurve;

  /// Drawer Duration
  final Duration? duration;

  @override
  _ZoomDrawerState createState() => new _ZoomDrawerState();

  /// static function to provide the drawer state
  static _ZoomDrawerState? of(BuildContext context) {
    return context.findAncestorStateOfType<State<ZoomDrawer>>() as _ZoomDrawerState?;
  }

  /// Static function to determine the device text direction RTL/LTR
  static bool isRTL() {
    return ui.window.locale.languageCode.toLowerCase() == "ar";
  }
}

class _ZoomDrawerState extends State<ZoomDrawer> with SingleTickerProviderStateMixin {
  final Curve _scaleDownCurve = Interval(0.0, 0.3, curve: Curves.easeOut);
  final Curve _scaleUpCurve = Interval(0.0, 1.0, curve: Curves.easeOut);
  final Curve _slideOutCurve = Interval(0.0, 1.0, curve: Curves.easeOut);
  final Curve _slideInCurve = Interval(0.0, 1.0, curve: Curves.easeOut); // Curves.bounceOut
  static const Cubic slowMiddle = Cubic(0.19, 1, 0.22, 1);

  /// check the slide direction
  final int _rtlSlide = ZoomDrawer.isRTL() ? -1 : 1;

  final bool _rtl = ZoomDrawer.isRTL();

  AnimationController? _animationController;
  late Animation<double> scaleAnimation;

  DrawerState _state = DrawerState.closed;

  double get _percentOpen => _animationController!.value;

  /// Open drawer
  open() {
    _animationController!.forward();
  }

  /// Close drawer
  close() {
    _animationController!.reverse();
  }

  AnimationController? get animationController => _animationController;

  /// Toggle drawer
  toggle() {
    if (_state == DrawerState.open) {
      close();
    } else if (_state == DrawerState.closed) {
      open();
    }
  }

  /// check whether drawer is open
  bool isOpen() => _state == DrawerState.open /* || _state == DrawerState.opening*/;

  /// Drawer state
  ValueNotifier<DrawerState>? stateNotifier;

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
    scaleAnimation = new Tween(
      begin: 0.9,
      end: 1.0,
    ).animate(new CurvedAnimation(
      parent: _animationController!,
      curve: Curves.slowMiddle,
    ));
    // CurvedAnimation(parent: _animationController, curve: Curves.easeIn); //Curves.easeIn Curves.linear
    /// assign controller function to the widget methods
    if (widget.controller != null) {
      widget.controller!.open = open;
      widget.controller!.close = close;
      widget.controller!.toggle = toggle;
      widget.controller!.isOpen = isOpen;
      widget.controller!.stateNotifier = stateNotifier;
    }
  }

  _updateStatusNotifier() {
    stateNotifier!.value = _state;
  }

  @override
  void dispose() {
    _animationController!.dispose();
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
  Widget _zoomAndSlideContent(Widget? container, {double? angle, double? scale, double slideW = 0, double slideH = 0}) {
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
        slidePercent = (widget.openCurve ?? _slideOutCurve).transform(_percentOpen);
        scalePercent = _scaleDownCurve.transform(_percentOpen);
        break;
      case DrawerState.closing:
        slidePercent = (widget.closeCurve ?? _slideInCurve).transform(_percentOpen);
        scalePercent = _scaleUpCurve.transform(_percentOpen);
        break;
    }

    /// calculated sliding amount based on the RTL and animation value
    final slideAmountWidth = (widget.slideWidth - slideW) * slidePercent * _rtlSlide;
    final slideAmountHeight = (widget.slideHeight - slideH) * slidePercent * _rtlSlide;

    /// calculated scale amount based on the provided scale and animation value
    final contentScale = (scale ?? 1.0) - (0.2 * scalePercent);

    /// calculated radius based on the provided radius and animation value
    final cornerRadius = widget.borderRadius * _percentOpen;

    /// calculated rotation amount based on the provided angle and animation value
    final rotationAngle = (((angle ?? widget.angle) * pi * _rtlSlide) / 180) * _percentOpen;

    return Transform(
      transform: Matrix4.translationValues(slideAmountWidth, slideAmountHeight, 0.0)
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

  Widget renderDefault() {
    final rightSlide = MediaQuery.of(context).size.width * 0.75;
    return AnimatedBuilder(
      animation: _animationController!,
      builder: (context, child) {
        double left = (1 - _animationController!.value) * rightSlide;
        return Stack(
          children: [
            GestureDetector(
              child: Stack(
                children: [
                  widget.mainScreen,
                  if (_animationController!.value > 0) ...[
                    Opacity(
                      opacity: _animationController!.value * 0.5,
                      child: Container(
                        color: Colors.black,
                      ),
                    )
                  ],
                ],
              ),
              onTap: () {
                if (_state == DrawerState.open) {
                  toggle();
                }
              },
            ),
            Transform.translate(
              offset: Offset(-left, 0),
              child: Container(
                width: rightSlide,
                child: widget.menuScreen,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget renderStyle1() {
    final rightSlide = MediaQuery.of(context).size.width * 0.75;
    return AnimatedBuilder(
      animation: _animationController!,
      builder: (context, child) {
        double slide = rightSlide * _animationController!.value;
        return Stack(
          children: [
            Scaffold(
              backgroundColor: widget.backgroundColor,
              body: Transform.translate(
                offset: Offset(0, 0),
                child: widget.menuScreen,
              ),
            ),
            Transform(
              transform: Matrix4.identity()..translate(slide),
              alignment: Alignment.center,
              child: Container(
                child: GestureDetector(
                  child: Stack(
                    children: [
                      widget.mainScreen,
                      if (_animationController!.value > 0) ...[
                        Opacity(
                          opacity: _animationController!.value * 0.5,
                          child: Container(
                            color: Colors.black,
                          ),
                        )
                      ],
                    ],
                  ),
                  onTap: () {
                    if (_state == DrawerState.open) {
                      toggle();
                    }
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget renderStyle2() {
    final rightSlide = MediaQuery.of(context).size.width * 0.75;
    return AnimatedBuilder(
      animation: _animationController!,
      builder: (context, child) {
        double slide = rightSlide * _animationController!.value;
        double left = (1 - _animationController!.value) * rightSlide;
        return Stack(
          children: [
            Transform(
              transform: Matrix4.identity()..translate(slide),
              alignment: Alignment.center,
              child: GestureDetector(
                child: Stack(
                  children: [
                    widget.mainScreen,
                    if (_animationController!.value > 0) ...[
                      Opacity(
                        opacity: _animationController!.value * 0.5,
                        child: Container(
                          color: Colors.black,
                        ),
                      )
                    ],
                  ],
                ),
                onTap: () {
                  if (_state == DrawerState.open) {
                    toggle();
                  }
                },
              ),
            ),
            Transform.translate(
              offset: Offset(-left, 0),
              child: Container(color: Colors.blueAccent, width: rightSlide, child: widget.menuScreen),
            ),
          ],
        );
      },
    );
  }

  Widget renderStyle3() {
    final slidePercent = ZoomDrawer.isRTL() ? MediaQuery.of(context).size.width * .1 : 15.0;

    return AnimatedBuilder(
      animation: _animationController!,
      builder: (context, child) {
        return Stack(
          children: [
            Scaffold(
              backgroundColor: widget.backgroundColor,
              body: Transform.translate(
                offset: Offset(0, 0),
                child: widget.menuScreen,
              ),
            ),
            if (widget.showShadow) ...[
              /// Displaying the first shadow
              AnimatedBuilder(
                animation: _animationController!,
                builder: (_, w) => _zoomAndSlideContent(w,
                    angle: (widget.angle == 0.0) ? 0.0 : widget.angle - 8, scale: .9, slideW: slidePercent * 2),
                child: Container(
                  color: widget.shadowColor.withOpacity(0.3),
                ),
              ),

              /// Displaying the second shadow
              AnimatedBuilder(
                animation: _animationController!,
                builder: (_, w) => _zoomAndSlideContent(w,
                    angle: (widget.angle == 0.0) ? 0.0 : widget.angle - 4.0, scale: .95, slideW: slidePercent),
                child: Container(
                  color: widget.shadowColor.withOpacity(0.9),
                ),
              )
            ],
            AnimatedBuilder(
              animation: _animationController!,
              builder: (_, w) => _zoomAndSlideContent(w),
              child: GestureDetector(
                child: Stack(
                  children: [
                    widget.mainScreen,
                    if (_animationController!.value > 0) ...[
                      Opacity(
                        opacity: 0,
                        child: Container(
                          color: Colors.black,
                        ),
                      )
                    ]
                  ],
                ),
                onTap: () {
                  if (_state == DrawerState.open) {
                    toggle();
                  }
                },
              ),
            )
          ],
        );
      },
    );
  }

  Widget renderStyle4() {
    final rightSlide = MediaQuery.of(context).size.width * 0.75;
    return AnimatedBuilder(
      animation: _animationController!,
      builder: (context, child) {
        double x = _animationController!.value * (rightSlide / 1.89);
        double rotate = _animationController!.value * (pi / 4);
        return Stack(
          children: [
            Scaffold(
              backgroundColor: widget.backgroundColor,
              body: Transform.translate(
                offset: Offset(0, 0),
                child: widget.menuScreen,
              ),
            ),
            Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0009)
                ..translate(x)
                ..rotateY(rotate),
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  if (_state == DrawerState.open) {
                    toggle();
                  }
                },
                child: Stack(
                  children: [
                    widget.mainScreen,
                    if (_animationController!.value > 0) ...[
                      Opacity(
                        opacity: 0,
                        child: Container(
                          color: Colors.black,
                        ),
                      )
                    ]
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget renderStyle5() {
    final rightSlide = MediaQuery.of(context).size.width * 0.75;
    return AnimatedBuilder(
      animation: _animationController!,
      builder: (context, child) {
        double x = _animationController!.value * (rightSlide / 2.52);
        double scale = 1 - (_animationController!.value * 0.3);
        double rotate = _animationController!.value * (pi / 4);
        return Stack(
          children: [
            Scaffold(
              backgroundColor: widget.backgroundColor,
              body: Transform.translate(
                offset: Offset(0, 0),
                child: widget.menuScreen,
              ),
            ),
            Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0009)
                ..translate(x)
                ..scale(scale)
                ..rotateY(-rotate),
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  if (_state == DrawerState.open) {
                    toggle();
                  }
                },
                child: Stack(
                  children: [
                    widget.mainScreen,
                    if (_animationController!.value > 0) ...[
                      Opacity(
                        opacity: 0,
                        child: Container(
                          color: Colors.black,
                        ),
                      )
                    ]
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget renderStyle6() {
    return AnimatedBuilder(
      animation: _animationController!,
      builder: (context, child) {
        double scale = _animationController!.value > 0.8 ? _animationController!.value : 0.8;
        return Stack(
          children: [
            widget.mainScreen,
            if (_animationController!.value > 0) ...[
              Opacity(
                // opacity: _animationController.value,
                opacity: _animationController!.drive(CurveTween(curve: Curves.easeIn)).value, //Curves.easeOut
                child: ScaleTransition(
                  scale: scaleAnimation,
                  child: GestureDetector(
                    child: Stack(
                      children: <Widget>[
                        widget.menuScreen,
                        Padding(
                          padding: EdgeInsets.only(right: 24, top: 24),
                          child: Align(
                            alignment: Alignment.topRight,
                            child: FloatingActionButton(
                              onPressed: () {
                                if (_state == DrawerState.open) {
                                  toggle();
                                }
                              },
                              backgroundColor: Colors.transparent,
                              elevation: 0.0,
                              child: Icon(Icons.close, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ],
        );
      },
    );
  }

  Widget renderLayout() {
    switch (widget.type) {
      case StyleState.style1:
        return renderStyle1();
      case StyleState.style2:
        return renderStyle2();
      case StyleState.style3:
        return renderStyle3();
      case StyleState.style4:
        return renderStyle4();
      case StyleState.style5:
        return renderStyle5();
      case StyleState.style6:
        return renderStyle6();
      default:
        return renderDefault();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      /// Detecting the slide amount to close the drawer in RTL & LTR
      onPanUpdate: (details) {
        if (_state == DrawerState.open && details.delta.dx < -6 && !_rtl || details.delta.dx < 6 && _rtl) {
          toggle();
        }
      },
      child: renderLayout(),
    );
  }
}

/// Drawer State enum
enum DrawerState { opening, closing, open, closed }

// Style State
enum StyleState { styleDefault, style1, style2, style3, style4, style5, style6 }
