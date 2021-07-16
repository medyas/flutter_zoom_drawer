library flutter_zoom_drawer;

import 'dart:math' show pi;

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
    this.type = StyleState.overlay,
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
    this.isRTL = false,
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

  /// Static function to determine the device text direction RTL/LTR
  final bool isRTL;

  @override
  _ZoomDrawerState createState() => new _ZoomDrawerState();

  /// static function to provide the drawer state
  static _ZoomDrawerState? of(BuildContext context) {
    return context.findAncestorStateOfType<State<ZoomDrawer>>() as _ZoomDrawerState?;
  }
}

class _ZoomDrawerState extends State<ZoomDrawer> with SingleTickerProviderStateMixin {
  final Curve _scaleDownCurve = Interval(0.0, 0.3, curve: Curves.easeOut);
  final Curve _scaleUpCurve = Interval(0.0, 1.0, curve: Curves.easeOut);
  final Curve _slideOutCurve = Interval(0.0, 1.0, curve: Curves.easeOut);
  final Curve _slideInCurve = Interval(0.0, 1.0, curve: Curves.easeOut); // Curves.bounceOut
  // static const Cubic slowMiddle = Cubic(0.19, 1, 0.22, 1);

  late AnimationController _animationController;
  late Animation<double> scaleAnimation;

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
      parent: _animationController,
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
  Widget _zoomAndSlideContent(Widget? container, {double? angle, double? scale, double slideW = 0, double slideH = 0}) {
    var slidePercent, scalePercent;
    int _rtlSlide = widget.isRTL ? -1 : 1;

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

  Widget renderOverlay() {
    final rightSlide = MediaQuery.of(context).size.width * 0.75;
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        double left = (1 - _animationController.value) * rightSlide;
        return dragClick(
            menuScreen: GestureDetector(
              child: Stack(
                children: [
                  widget.mainScreen,
                  if (_animationController.value > 0) ...[
                    Opacity(
                      opacity: _animationController.value * 0.5,
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
            mainScreen: Transform.translate(
              offset: Offset(widget.isRTL ? left : -left, 0),
              child: Container(
                width: rightSlide,
                child: widget.menuScreen,
              ),
            ));
      },
    );
  }

  Widget renderFixedStack() {
    final rightSlide = MediaQuery.of(context).size.width * 0.75;
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        double slide = rightSlide * _animationController.value;
        return dragClick(
          menuScreen: Scaffold(
            backgroundColor: widget.backgroundColor,
            body: Transform.translate(
              offset: Offset(0, 0),
              child: widget.menuScreen,
            ),
          ),
          mainScreen: Transform(
            transform: Matrix4.identity()..translate(widget.isRTL ? -slide : slide),
            alignment: Alignment.center,
            child: Container(
              child: GestureDetector(
                child: Stack(
                  children: [
                    widget.mainScreen,
                    if (_animationController.value > 0) ...[
                      Opacity(
                        opacity: _animationController.value * 0.5,
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
        );
      },
    );
  }

  Widget renderStack() {
    final rightSlide = MediaQuery.of(context).size.width * 0.75;
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        double slide = rightSlide * _animationController.value;
        double left = (1 - _animationController.value) * rightSlide;
        return Stack(
          children: [
            Transform.translate(
              offset: Offset(widget.isRTL ? left : -left, 0),
              child: Container(color: Colors.blueAccent, width: rightSlide, child: widget.menuScreen),
            ),
            Stack(
              children: [
                Transform(
                  transform: Matrix4.identity()..translate(widget.isRTL ? -slide : slide),
                  alignment: Alignment.center,
                  child: GestureDetector(
                    child: Stack(
                      children: [
                        widget.mainScreen,
                        if (_animationController.value > 0) ...[
                          Opacity(
                            opacity: _animationController.value * 0.5,
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
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanUpdate: (details) {
                    if ((details.delta.dx > 6 || details.delta.dx < 6 && _state == DrawerState.open) && !widget.isRTL) {
                      if (_state == DrawerState.closed) {
                        open();
                      } else if (_state == DrawerState.open && details.delta.dx < -6) {
                        close();
                      }
                    }

                    if ((details.delta.dx < -6 || details.delta.dx > 6 && _state == DrawerState.open) && widget.isRTL) {
                      if (_state == DrawerState.closed) {
                        open();
                      } else if (_state == DrawerState.open && details.delta.dx > 6) {
                        close();
                      }
                    }
                  },
                  child: Container(
                    width: DrawerState.closed == _state ? 20 : 0,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget renderScaleRight() {
    final slidePercent = widget.isRTL ? MediaQuery.of(context).size.width * .095 : 15.0;
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return dragClick(
            menuScreen: Scaffold(
              backgroundColor: widget.backgroundColor,
              body: Transform.translate(
                offset: Offset(0, 0),
                child: widget.menuScreen,
              ),
            ),
            shadow: widget.showShadow == true
                ? [
                    /// Displaying the first shadow
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (_, w) => _zoomAndSlideContent(w,
                          angle: (widget.angle == 0.0) ? 0.0 : widget.angle - 8, scale: .9, slideW: slidePercent * 2),
                      child: Container(
                        color: widget.shadowColor.withOpacity(0.3),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (_, w) => _zoomAndSlideContent(w,
                          angle: (widget.angle == 0.0) ? 0.0 : widget.angle - 4.0, scale: .95, slideW: slidePercent),
                      child: Container(
                        color: widget.shadowColor.withOpacity(0.9),
                      ),
                    )
                  ]
                : null,
            mainScreen: AnimatedBuilder(
              animation: _animationController,
              builder: (_, w) => _zoomAndSlideContent(w),
              child: GestureDetector(
                child: Stack(
                  children: [
                    widget.mainScreen,
                    if (_animationController.value > 0) ...[
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
            ));
      },
    );
  }

  Widget renderRotate3dIn() {
    final rightSlide = MediaQuery.of(context).size.width * 0.75;
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        double x = _animationController.value * (rightSlide / 1.89);
        double rotate = _animationController.value * (pi / 4);
        return dragClick(
            menuScreen: Scaffold(
              backgroundColor: widget.backgroundColor,
              body: Transform.translate(
                offset: Offset(0, 0),
                child: widget.menuScreen,
              ),
            ),
            mainScreen: Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0009)
                ..translate(widget.isRTL ? -x : x)
                ..rotateY(widget.isRTL ? -rotate : rotate),
              alignment: widget.isRTL ? Alignment.centerLeft : Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  if (_state == DrawerState.open) {
                    toggle();
                  }
                },
                child: Stack(
                  children: [
                    widget.mainScreen,
                    if (_animationController.value > 0) ...[
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
            ));
      },
    );
  }

  Widget renderRotate3dOut() {
    final rightSlide = MediaQuery.of(context).size.width * 0.75;
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        double x = _animationController.value * (rightSlide / 2.65);
        double scale = 1 - (_animationController.value * 0.3);
        double rotate = _animationController.value * (pi / 4);
        return dragClick(
            menuScreen: Scaffold(
              backgroundColor: widget.backgroundColor,
              body: Transform.translate(
                offset: Offset(0, 0),
                child: widget.menuScreen,
              ),
            ),
            mainScreen: Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0009)
                ..translate(widget.isRTL ? -x : x)
                ..scale(scale)
                ..rotateY(widget.isRTL ? rotate : -rotate),
              alignment: widget.isRTL ? Alignment.centerLeft : Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  if (_state == DrawerState.open) {
                    toggle();
                  }
                },
                child: Stack(
                  children: [
                    widget.mainScreen,
                    if (_animationController.value > 0) ...[
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
            ));
      },
    );
  }

  Widget renderPopUp() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          children: [
            widget.mainScreen,
            if (_animationController.value > 0) ...[
              Opacity(
                opacity: _animationController.drive(CurveTween(curve: Curves.easeIn)).value, //Curves.easeOut
                child: ScaleTransition(
                  scale: scaleAnimation,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      if ((details.delta.dx > 6 || details.delta.dx < 6 && _state == DrawerState.open) &&
                          !widget.isRTL) {
                        if (_state == DrawerState.open && details.delta.dx < -6) {
                          close();
                        }
                      }
                      if ((details.delta.dx < -6 || details.delta.dx > 6 && _state == DrawerState.open) &&
                          widget.isRTL) {
                        if (_state == DrawerState.open && details.delta.dx > 6) {
                          close();
                        }
                      }
                    },
                    child: Stack(
                      children: <Widget>[
                        Container(
                          color: Colors.red.withOpacity(0.6), //widget.backgroundColor.withOpacity(0.6),
                          child: widget.menuScreen,
                        ),
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

  @override
  Widget build(BuildContext context) {
    switch (widget.type) {
      case StyleState.fixedStack:
        return renderFixedStack();
      case StyleState.stack:
        return renderStack();
      case StyleState.scaleRight:
        return renderScaleRight();
      case StyleState.rotate3dIn:
        return renderRotate3dIn();
      case StyleState.rotate3dOut:
        return renderRotate3dOut();
      case StyleState.popUp:
        return renderPopUp();
      default:
        return renderOverlay();
    }
  }

  Widget dragClick({required Widget menuScreen, required Widget mainScreen, List? shadow}) {
    return Stack(
      children: [
        menuScreen,
        if (shadow != null) ...shadow,
        Stack(
          children: [
            GestureDetector(
              onPanUpdate: (details) {
                if ((details.delta.dx > 6 || details.delta.dx < 6 && _state == DrawerState.open) && !widget.isRTL) {
                  if (_state == DrawerState.open && details.delta.dx < -6) {
                    close();
                  }
                }

                if ((details.delta.dx < -6 || details.delta.dx > 6 && _state == DrawerState.open) && widget.isRTL) {
                  if (_state == DrawerState.open && details.delta.dx > 6) {
                    close();
                  }
                }
              },
              child: mainScreen,
            ),
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanUpdate: (details) {
                if ((details.delta.dx > 6 || details.delta.dx < 6 && _state == DrawerState.open) && !widget.isRTL) {
                  if (_state == DrawerState.closed) {
                    open();
                  }
                }

                if ((details.delta.dx < -6 || details.delta.dx > 6 && _state == DrawerState.open) && widget.isRTL) {
                  if (_state == DrawerState.closed) {
                    open();
                  }
                }
              },
              child: Container(
                width: DrawerState.closed == _state ? 20 : 0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Drawer State enum
enum DrawerState { opening, closing, open, closed }

// Style State
enum StyleState { overlay, fixedStack, stack, scaleRight, rotate3dIn, rotate3dOut, popUp }
